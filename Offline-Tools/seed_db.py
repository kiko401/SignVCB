"""直连 MySQL 写入初始化数据。

用于 Day 1 数据初始化。
需要 Docker 中的 MySQL 容器运行。
"""
import json
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, "backend")
sys.path.insert(0, "Offline-Tools")


async def seed_reading_data():
    """写入读物数据。"""
    try:
        from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
        from sqlalchemy import text
        from app.core.config import get_settings

        settings = get_settings()
        engine = create_async_engine(settings.DATABASE_URL)
        Session = async_sessionmaker(engine)

        books_path = Path("deploy/init_data/reading_books.json")
        sentences_path = Path("deploy/init_data/reading_sentences.json")

        if not books_path.exists():
            print("[WARN] reading_books.json not found, skipping seed")
            return

        books = json.loads(books_path.read_text(encoding="utf-8"))
        sentences = json.loads(sentences_path.read_text(encoding="utf-8")) if sentences_path.exists() else []

        async with Session() as s:
            for b in books:
                await s.execute(
                    text("""
                        INSERT INTO reading_books (id, title, age_group, cover_url, difficulty)
                        VALUES (:id, :title, :age_group, :cover_url, :difficulty)
                        ON DUPLICATE KEY UPDATE title=:title
                    """),
                    b
                )

            for sent in sentences:
                await s.execute(
                    text("""
                        INSERT INTO reading_sentences (id, book_id, sentence_index, original_text, sign_text, alignment_ops)
                        VALUES (:id, :book_id, :sentence_index, :original_text, :sign_text, :alignment_ops)
                        ON DUPLICATE KEY UPDATE original_text=:original_text
                    """),
                    {
                        **sent,
                        "alignment_ops": json.dumps(sent.get("alignment_ops", []), ensure_ascii=False)
                    }
                )

            await s.commit()

        print(f"Seeded {len(books)} books, {len(sentences)} sentences")
        await engine.dispose()

    except Exception as e:
        print(f"[ERROR] Failed to seed reading data: {e}")
        raise


async def seed_practice_data():
    """写入练习题数据。"""
    try:
        from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
        from sqlalchemy import text
        from app.core.config import get_settings

        settings = get_settings()
        engine = create_async_engine(settings.DATABASE_URL)
        Session = async_sessionmaker(engine)

        questions_path = Path("deploy/init_data/practice_questions.json")

        if not questions_path.exists():
            print("[WARN] practice_questions.json not found, skipping seed")
            return

        questions = json.loads(questions_path.read_text(encoding="utf-8"))

        async with Session() as s:
            for q in questions:
                question_data = q.get("question", {})
                answer_data = q.get("answer", [])

                await s.execute(
                    text("""
                        INSERT INTO practice_questions (level, type, question, answer)
                        VALUES (:level, :type, :question, :answer)
                    """),
                    {
                        "level": q["level"],
                        "type": q["type"],
                        "question": json.dumps(question_data, ensure_ascii=False),
                        "answer": json.dumps(answer_data, ensure_ascii=False),
                    }
                )

            await s.commit()

        print(f"Seeded {len(questions)} practice questions")
        await engine.dispose()

    except Exception as e:
        print(f"[ERROR] Failed to seed practice data: {e}")
        raise


async def main():
    print("Starting database seeding...")

    import subprocess
    result = subprocess.run(
        ["docker", "ps", "--filter", "name=signvcb-mysql", "--format", "{{.Names}}"],
        capture_output=True,
        text=True
    )

    if "signvcb-mysql" not in result.stdout:
        print("[WARN] signvcb-mysql not running, please run: docker compose -f deploy/docker-compose.yml up -d")
        print("Skipping DB seeding for now.")
        return

    try:
        await seed_reading_data()
        await seed_practice_data()
        print("Database seeding completed!")
    except Exception as e:
        print(f"[ERROR] Seeding failed: {e}")


if __name__ == "__main__":
    asyncio.run(main())
