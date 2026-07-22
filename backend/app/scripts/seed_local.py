#!/usr/bin/env python3
"""数据库种子数据初始化脚本

直接在数据库层面写入，不依赖 backend app 的 import 体系，
可在容器启动时独立运行。

用法：
    python -m app.scripts.seed_local
"""
import asyncio
import json
import sys
import os
from pathlib import Path

# aiomysql 直接连接，不走 SQLAlchemy app model
import aiomysql


async def get_pool():
    host = os.getenv("MYSQL_HOST", "signvcb-mysql")
    port = int(os.getenv("MYSQL_PORT", "3306"))
    user = os.getenv("MYSQL_USER", "signvcb")
    password = os.getenv("MYSQL_PASSWORD", "signvcb123")
    database = os.getenv("MYSQL_DATABASE", "signvcb")

    return await aiomysql.create_pool(
        host=host, port=port, user=user, password=password,
        db=database, autocommit=True, minsize=1, maxsize=3
    )


async def seed_reading(pool):
    """写入读物数据"""
    # 支持环境变量指定数据目录，容器内用 /app/deploy/init_data，本地开发用相对路径
    seed_data_dir = os.getenv("SEED_DATA_DIR")
    if seed_data_dir:
        deploy_dir = Path(seed_data_dir)
    else:
        deploy_dir = Path(__file__).parent.parent.parent.parent / "deploy" / "init_data"
    books_path = deploy_dir / "reading_books.json"
    sentences_path = deploy_dir / "reading_sentences.json"

    if not books_path.exists():
        print("[WARN] reading_books.json not found, skipping")
        return

    books = json.loads(books_path.read_text(encoding="utf-8"))
    sentences = json.loads(sentences_path.read_text(encoding="utf-8")) if sentences_path.exists() else []

    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            for b in books:
                await cur.execute(
                    """INSERT INTO reading_books (title, age_group, cover_url, difficulty)
                       VALUES (%s, %s, %s, %s)
                       ON DUPLICATE KEY UPDATE title=VALUES(title)""",
                    (b["title"], b["age_group"], b.get("cover_url"), b.get("difficulty"))
                )

            for s in sentences:
                ops = json.dumps(s.get("alignment_ops", []), ensure_ascii=False)
                await cur.execute(
                    """INSERT INTO reading_sentences
                       (book_id, sentence_index, original_text, sign_text, alignment_ops)
                       VALUES (%s, %s, %s, %s, %s)
                       ON DUPLICATE KEY UPDATE original_text=VALUES(original_text)""",
                    (s["book_id"], s["sentence_index"], s["original_text"], s["sign_text"], ops)
                )

    print(f"Seeded {len(books)} books, {len(sentences)} sentences")


async def seed_practice(pool):
    """写入练习题数据"""
    seed_data_dir = os.getenv("SEED_DATA_DIR")
    if seed_data_dir:
        deploy_dir = Path(seed_data_dir)
    else:
        deploy_dir = Path(__file__).parent.parent.parent.parent / "deploy" / "init_data"
    questions_path = deploy_dir / "practice_questions.json"

    if not questions_path.exists():
        print("[WARN] practice_questions.json not found, skipping")
        return

    questions = json.loads(questions_path.read_text(encoding="utf-8"))

    async with pool.acquire() as conn:
        async with conn.cursor() as cur:
            for q in questions:
                question_data = q.get("question", {})
                answer_data = q.get("answer", [])

                await cur.execute(
                    """INSERT INTO practice_questions (level, type, question, answer)
                       VALUES (%s, %s, %s, %s)
                       ON DUPLICATE KEY UPDATE level=VALUES(level)""",
                    (
                        q["level"],
                        q["type"],
                        json.dumps(question_data, ensure_ascii=False),
                        json.dumps(answer_data, ensure_ascii=False),
                    )
                )

    print(f"Seeded {len(questions)} practice questions")


async def main():
    print("Starting database seeding...")
    print(f"MYSQL_HOST={os.getenv('MYSQL_HOST', 'localhost')}")

    try:
        pool = await get_pool()
    except Exception as e:
        print(f"[ERROR] Cannot connect to MySQL: {e}")
        print("Make sure MySQL is running and MYSQL_* env vars are set correctly.")
        sys.exit(1)

    try:
        await seed_reading(pool)
        await seed_practice(pool)
        print("Database seeding completed!")
    finally:
        pool.close()
        await pool.wait_closed()


if __name__ == "__main__":
    asyncio.run(main())
