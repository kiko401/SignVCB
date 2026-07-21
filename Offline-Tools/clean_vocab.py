"""特教专家原始词表清洗去重。

输入: data/raw_vocab.txt（特教专家提供）
输出: outputs/data/csl_standard_vocab.json

如果没有 raw_vocab.txt，则创建示例词表用于测试。
"""
import json
import re
from pathlib import Path

INPUT = Path("Offline-Tools/data/raw_vocab.txt")
OUTPUT = Path("Offline-Tools/outputs/data/csl_standard_vocab.json")


def clean():
    if not INPUT.exists():
        print(f"[WARN] {INPUT} not found, creating sample vocab for testing")
        sample_words = [
            "我", "你", "他", "她", "它", "我们", "你们", "他们",
            "吃", "喝", "玩", "看", "听", "说", "读", "写",
            "苹果", "香蕉", "葡萄", "西瓜", "桃子", "梨",
            "爸爸", "妈妈", "爷爷", "奶奶", "哥哥", "姐姐",
            "猫", "狗", "鸟", "鱼", "兔子", "乌龟",
            "学校", "老师", "同学", "朋友", "医院", "医生",
        ]
        OUTPUT.parent.mkdir(parents=True, exist_ok=True)
        OUTPUT.write_text(json.dumps(sample_words, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"Created sample vocab: {len(sample_words)} words -> {OUTPUT}")
        return

    seen = set()
    cleaned = []
    for line in INPUT.read_text(encoding="utf-8").splitlines():
        w = line.strip()
        if not w or len(w) > 10:
            continue
        if re.search(r'[\u4e00-\u9fff]', w) is None:
            continue
        if w in seen:
            continue
        seen.add(w)
        cleaned.append(w)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(cleaned, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Cleaned vocab: {len(cleaned)} words -> {OUTPUT}")


if __name__ == "__main__":
    clean()
