"""生成 L1/L2/L3 练习题。

输出: deploy/init_data/practice_questions.json
"""
import json
from pathlib import Path

L1_QUESTIONS = [
    {
        "level": "L1",
        "type": "word_match",
        "question": {
            "mode": "image",
            "image_urls": [
                "https://cdn.example.com/wordcards/apple.png",
                "https://cdn.example.com/wordcards/banana.png",
            ],
            "text": None,
            "choices": ["苹果", "香蕉", "葡萄", "西瓜"],
            "scrambled": [],
            "target_text": None,
        },
        "answer": ["苹果"],
    },
    {
        "level": "L1",
        "type": "word_match",
        "question": {
            "mode": "image",
            "image_urls": [
                "https://cdn.example.com/wordcards/cat.png",
                "https://cdn.example.com/wordcards/dog.png",
            ],
            "text": None,
            "choices": ["猫", "狗", "鸟", "鱼"],
            "scrambled": [],
            "target_text": None,
        },
        "answer": ["猫"],
    },
    {
        "level": "L1",
        "type": "sentence_order",
        "question": {
            "mode": "text",
            "image_urls": [],
            "text": None,
            "choices": [],
            "scrambled": ["我", "吃", "苹果"],
            "target_text": "我吃苹果",
        },
        "answer": ["我", "吃", "苹果"],
    },
    {
        "level": "L1",
        "type": "sentence_order",
        "question": {
            "mode": "text",
            "image_urls": [],
            "text": None,
            "choices": [],
            "scrambled": ["妈妈", "爱", "我"],
            "target_text": "妈妈爱我",
        },
        "answer": ["妈妈", "爱", "我"],
    },
]

L2_QUESTIONS = [
    {
        "level": "L2",
        "type": "word_match",
        "question": {
            "mode": "image",
            "image_urls": [
                "https://cdn.example.com/wordcards/school.png",
                "https://cdn.example.com/wordcards/hospital.png",
            ],
            "text": None,
            "choices": ["学校", "医院", "公园", "商店"],
            "scrambled": [],
            "target_text": None,
        },
        "answer": ["学校"],
    },
    {
        "level": "L2",
        "type": "sentence_order",
        "question": {
            "mode": "text",
            "image_urls": [],
            "text": None,
            "choices": [],
            "scrambled": ["小马", "驮着", "麦子", "去", "磨坊"],
            "target_text": "小马驮着麦子去磨坊",
        },
        "answer": ["小马", "驮着", "麦子", "去", "磨坊"],
    },
]

L3_QUESTIONS = [
    {
        "level": "L3",
        "type": "sign_recognize",
        "question": {
            "mode": "text",
            "image_urls": [],
            "text": "小猫跟妈妈一起去钓鱼。",
            "choices": [],
            "scrambled": [],
            "target_text": "小猫钓鱼",
        },
        "answer": "小猫钓鱼",
    },
    {
        "level": "L3",
        "type": "sign_recognize",
        "question": {
            "mode": "text",
            "image_urls": [],
            "text": "小马驮着麦子去磨坊。",
            "choices": [],
            "scrambled": [],
            "target_text": "小马过河",
        },
        "answer": "小马过河",
    },
]

OUTPUT = "deploy/init_data/practice_questions.json"


def generate():
    all_questions = L1_QUESTIONS + L2_QUESTIONS + L3_QUESTIONS

    Path(OUTPUT).parent.mkdir(parents=True, exist_ok=True)
    Path(OUTPUT).write_text(
        json.dumps(all_questions, ensure_ascii=False, indent=2),
        encoding="utf-8"
    )
    print(f"Generated {len(all_questions)} questions -> {OUTPUT}")


if __name__ == "__main__":
    generate()
