"""基于近邻检索生成 OOV 降级词典。

如果 FAISS 索引不存在，则创建默认降级词典。
"""
import json
import os
import sys
from pathlib import Path

VOCAB = "Offline-Tools/outputs/data/csl_standard_vocab.json"
ONNX = "Offline-Tools/outputs/onnx/csl_encoder.onnx"
FAISS = "Offline-Tools/outputs/faiss/faiss_index.bin"
OUT = "Offline-Tools/outputs/fallback/initial_fallback.json"

SEEDS = [
    "量子", "区块链", "人工智能", "元宇宙", "芯片",
    "算法", "数据", "网络", "程序", "服务器",
    "中国", "美国", "日本", "韩国", "德国",
    "北京", "上海", "深圳", "杭州", "广州",
]


def build():
    for f in [VOCAB, FAISS]:
        if not Path(f).exists():
            print(f"[WARN] {f} not found, creating default fallback")
            os.makedirs(os.path.dirname(OUT), exist_ok=True)
            default_fallback = {
                "量子": "东西", "区块链": "技术", "人工智能": "智能",
                "元宇宙": "世界", "芯片": "零件", "算法": "方法",
                "数据": "信息", "网络": "网络", "程序": "代码",
                "服务器": "电脑", "中国": "国家", "美国": "国家",
                "日本": "国家", "韩国": "国家", "德国": "国家",
                "北京": "城市", "上海": "城市", "深圳": "城市",
                "杭州": "城市", "广州": "城市",
            }
            json.dump(default_fallback, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
            print(f"Created default fallback: {OUT}, {len(default_fallback)} entries")
            return

    words = json.loads(open(VOCAB, encoding="utf-8").read())

    try:
        import numpy as np
        import faiss
        sys.path.insert(0, "engine")
        from app.core.onnx_encoder import ONNXEncoder

        encoder = ONNXEncoder()
        encoder.load(ONNX)
        index = faiss.read_index(FAISS)
        seed_embs = encoder.encode(SEEDS)
        fallback = {}
        for i, seed in enumerate(SEEDS):
            emb = np.array([seed_embs[i]], dtype=np.float32)
            _, ids = index.search(emb, 5)
            for j in ids[0]:
                if words[j] != seed:
                    fallback[seed] = words[j]
                    break
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        json.dump(fallback, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        print(f"Done: {OUT}, {len(fallback)} entries")
    except Exception as e:
        print(f"[WARN] FAISS lookup failed: {e}, using default mapping")
        default_fallback = {s: "东西" for s in SEEDS}
        os.makedirs(os.path.dirname(OUT), exist_ok=True)
        json.dump(default_fallback, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=2)
        print(f"Created default fallback: {OUT}, {len(default_fallback)} entries")


if __name__ == "__main__":
    build()
