#!/usr/bin/env python3
"""CSL Rewrite Pipeline 消融实验脚本

测试各模块对输出质量的影响：
1. 完整 pipeline（all=True）
2. 无 OOV 检测（OOV 词保持原样）
3. 无 LLM 精炼（直接使用 first_pass）
4. 无 FAISS 相似度搜索（只用初始降级词典）
5. 无动态降级同步（只用初始词典）

用法：
    python scripts/run_ablation.py
"""
import asyncio
import json
import time
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.modules.oov_detector import OOVDetector
from app.modules.fallback_resolver import FallbackResolver
from app.modules.llm_refiner import LLMRefiner
from app.modules.alignment_generator import AlignmentGenerator
from app.modules.nmm_generator import NMMGenerator
from app.core.llm_client import get_shared_client, close_shared_client


class AblationPipeline:
    """可配置的消融流水线"""

    def __init__(self, config: dict):
        self.use_oov = config.get("use_oov", True)
        self.use_llm = config.get("use_llm", True)
        self.use_faiss = config.get("use_faiss", True)
        self.use_dynamic = config.get("use_dynamic", True)

        self.oov_detector = OOVDetector()
        self.alignment_generator = AlignmentGenerator()
        self.nmm_generator = NMMGenerator()

        initial_fallback = {}
        fb_path = Path(__file__).parent.parent / "data" / "fallback" / "initial_fallback.json"
        if fb_path.exists():
            initial_fallback = json.loads(fb_path.read_text(encoding="utf-8"))

        self.fallback_resolver = FallbackResolver(
            self.oov_detector, initial_fallback if self.use_dynamic else {}
        )

        self.llm_refiner = None
        if self.use_llm:
            self.llm_refiner = LLMRefiner(get_shared_client())

    def load(self, index_path: str, vocab_path: str):
        """加载 OOV 检测器（仅在 use_faiss=True 时加载 FAISS）"""
        self.oov_detector.load(
            index_path if self.use_faiss else "",
            vocab_path,
            None
        )

    async def process(self, text: str) -> dict:
        """执行消融流水线"""
        start = time.monotonic()

        if not self.use_oov:
            words = text.split()
            first_pass_text = text
            oov_status = False
            oov_words = []
        else:
            first_pass_text, oov_status, oov_words = self.oov_detector.detect(text)

        yield_result = {
            "first_pass": first_pass_text,
            "oov_status": oov_status,
            "oov_words": oov_words,
        }

        if not oov_status:
            refined_text = first_pass_text
            oov_map = {}
        else:
            oov_map = self.fallback_resolver.build_oov_map(oov_words)
            refined_text = first_pass_text
            for oov_word, fallback_word in oov_map.items():
                refined_text = refined_text.replace(oov_word, fallback_word)

        if self.use_llm and (oov_status or True):
            try:
                refined_text = await self.llm_refiner.refine(first_pass_text, oov_map)
            except Exception as e:
                refined_text = first_pass_text

        nmm_hints = self.nmm_generator.generate(refined_text)
        alignment_ops = self.alignment_generator.generate(first_pass_text, refined_text)

        latency_ms = (time.monotonic() - start) * 1000

        return {
            **yield_result,
            "refined_pass": refined_text,
            "oov_map": oov_map,
            "nmm_hints": nmm_hints,
            "alignment_ops": [op.model_dump() for op in alignment_ops],
            "latency_ms": round(latency_ms, 2),
        }


TEST_CASES = [
    "我 吃 苹果",
    "今天 天气 怎么样",
    "量子 计算 技术 发展",
    "中国 北京 上海 深圳",
    "人 工 智能 应用 场景",
]


ABLATION_CONFIGS = [
    {"name": "full", "label": "完整 pipeline", "use_oov": True, "use_llm": True, "use_faiss": True, "use_dynamic": True},
    {"name": "no_oov", "label": "无 OOV 检测", "use_oov": False, "use_llm": True, "use_faiss": True, "use_dynamic": True},
    {"name": "no_llm", "label": "无 LLM 精炼", "use_oov": True, "use_llm": False, "use_faiss": True, "use_dynamic": True},
    {"name": "no_faiss", "label": "无 FAISS 搜索", "use_oov": True, "use_llm": True, "use_faiss": False, "use_dynamic": True},
    {"name": "no_dynamic", "label": "无动态降级", "use_oov": True, "use_llm": True, "use_faiss": True, "use_dynamic": False},
]


async def run_one_config(config: dict, index_path: str, vocab_path: str) -> dict:
    """运行单个配置"""
    pipeline = AblationPipeline(config)
    pipeline.load(index_path, vocab_path)

    results = []
    for text in TEST_CASES:
        result = await pipeline.process(text)
        results.append(result)

    avg_latency = sum(r["latency_ms"] for r in results) / len(results)
    return {"config": config["name"], "label": config["label"], "results": results, "avg_latency_ms": avg_latency}


async def main():
    base_dir = Path(__file__).parent.parent
    index_path = str(base_dir / "data" / "faiss" / "faiss_index.bin")
    vocab_path = str(base_dir / "data" / "vocab.json")

    print("=" * 60)
    print("CSL Rewrite Pipeline 消融实验")
    print("=" * 60)
    print(f"测试用例数: {len(TEST_CASES)}")
    print(f"配置数: {len(ABLATION_CONFIGS)}")
    print()

    all_results = []
    for cfg in ABLATION_CONFIGS:
        print(f"运行: {cfg['label']} ({cfg['name']})...")
        r = await run_one_config(cfg, index_path, vocab_path)
        all_results.append(r)
        print(f"  平均延迟: {r['avg_latency_ms']:.2f} ms")

    print()
    print("=" * 60)
    print("消融结果汇总")
    print("=" * 60)
    print(f"{'配置':<20} {'avg latency (ms)':<18} {'OOV 覆盖率':<15}")
    print("-" * 60)

    for res in all_results:
        oov_cov = sum(1 for r in res["results"] if r["oov_status"]) / len(res["results"])
        print(f"{res['label']:<16} {res['avg_latency_ms']:<18.2f} {oov_cov:<15.2%}")

    print()
    print("=" * 60)
    print("各测试用例输出详情")
    print("=" * 60)

    for i, text in enumerate(TEST_CASES):
        print(f"\n[用例 {i+1}] 输入: {text}")
        for res in all_results:
            r = res["results"][i]
            oov_flag = "[OOV]" if r["oov_status"] else "     "
            print(f"  {res['label']:<14} {oov_flag} first='{r['first_pass']}' refined='{r['refined_pass']}'")

    output_path = base_dir / "data" / "ablation_results.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(all_results, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"\n结果已保存: {output_path}")

    await close_shared_client()


if __name__ == "__main__":
    asyncio.run(main())
