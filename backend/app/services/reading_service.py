"""读物服务"""
from typing import Optional, List
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
import json
from app.models.reading import ReadingBook, ReadingSentence
from app.schemas.reading import (
    ReadingBookResponse,
    ReadingContentResponse,
    ReadingSentenceResponse
)
from app.schemas.alignment import AlignmentOp


class ReadingService:
    """读物服务"""

    @staticmethod
    async def get_books(session: AsyncSession, age_group: str = None) -> list[ReadingBookResponse]:
        """获取书籍列表"""
        stmt = select(ReadingBook)
        if age_group:
            stmt = stmt.where(ReadingBook.age_group == age_group)

        result = await session.execute(stmt)
        books = result.scalars().all()

        return [
            ReadingBookResponse(
                id=b.id,
                title=b.title,
                age_group=b.age_group,
                cover_url=b.cover_url,
                difficulty=b.difficulty
            )
            for b in books
        ]

    @staticmethod
    async def get_content(session: AsyncSession, book_id: int) -> Optional[ReadingContentResponse]:
        """获取书籍内容"""
        result = await session.execute(
            select(ReadingBook).where(ReadingBook.id == book_id)
        )
        book = result.scalar_one_or_none()
        if not book:
            return None

        result = await session.execute(
            select(ReadingSentence)
            .where(ReadingSentence.book_id == book_id)
            .order_by(ReadingSentence.sentence_index)
        )
        sentences = result.scalars().all()

        sentence_responses = [
            ReadingSentenceResponse(
                index=s.sentence_index,
                original=s.original_text,
                sign_text=s.sign_text,
                alignment_ops=json.loads(s.alignment_ops) if s.alignment_ops else []
            )
            for s in sentences
        ]

        return ReadingContentResponse(book_id=book.id, sentences=sentence_responses)
