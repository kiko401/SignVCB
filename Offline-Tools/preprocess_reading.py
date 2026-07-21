"""生成读物数据：reading_books.json + reading_sentences.json。

输出:
- deploy/init_data/reading_books.json
- deploy/init_data/reading_sentences.json
"""
import json
from pathlib import Path

BOOKS = [
    {
        "title": "小猫钓鱼",
        "age_group": "L1",
        "cover_url": "https://cdn.example.com/covers/cat_fishing.png",
        "difficulty": 1,
    },
    {
        "title": "小马过河",
        "age_group": "L2",
        "cover_url": "https://cdn.example.com/covers/horse_river.png",
        "difficulty": 2,
    },
    {
        "title": "曹冲称象",
        "age_group": "L3",
        "cover_url": "https://cdn.example.com/covers/cao_chong.png",
        "difficulty": 3,
    },
]

SENTENCES = {
    "小猫钓鱼": [
        "小猫跟妈妈一起去钓鱼。",
        "小猫一会儿捉蝴蝶，一会儿捉蜻蜓。",
        "最后小猫一条鱼也没钓到。",
    ],
    "小马过河": [
        "小马驮着麦子去磨坊。",
        "小马遇到一条小河，不知道深浅。",
        "小马问了小松鼠和小黄牛，最后自己试了试。",
    ],
    "曹冲称象": [
        "古时候有个小孩叫曹冲。",
        "别人送了一头大象，没人知道它有多重。",
        "曹冲用船和石头称出了大象的重量。",
    ],
}


def generate():
    books_out = []
    sentences_out = []

    for i, b in enumerate(BOOKS):
        books_out.append({"id": i + 1, **b})
        for j, original in enumerate(SENTENCES[b["title"]]):
            sentences_out.append({
                "id": len(sentences_out) + 1,
                "book_id": i + 1,
                "sentence_index": j,
                "original_text": original,
                "sign_text": original,
                "alignment_ops": [],
            })

    books_path = Path("deploy/init_data/reading_books.json")
    sentences_path = Path("deploy/init_data/reading_sentences.json")

    books_path.parent.mkdir(parents=True, exist_ok=True)
    books_path.write_text(json.dumps(books_out, ensure_ascii=False, indent=2), encoding="utf-8")
    sentences_path.write_text(json.dumps(sentences_out, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Generated {len(books_out)} books -> {books_path}")
    print(f"Generated {len(sentences_out)} sentences -> {sentences_path}")


if __name__ == "__main__":
    generate()
