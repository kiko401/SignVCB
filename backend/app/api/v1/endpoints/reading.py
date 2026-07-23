"""读物接口"""
from typing import List
from fastapi import APIRouter, Depends, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.reading import ReadingContentResponse, ReadingBookResponse
from app.services.reading_service import ReadingService
from app.core.rate_limit import limiter
from app.core.exceptions import NotFoundError

router = APIRouter()


@router.get("/books", response_model=List[ReadingBookResponse])
@limiter.limit("60/minute")
async def get_books(
    request: Request,
    age_group: str = None,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取书籍列表

    返回直接数组，前端直接解析 response.data as List。
    设计文档 v3.1 明确要求：修复 ReadingService.getBooks 直接解析数组而非 response.data['books']。
    """
    books = await ReadingService.get_books(session, age_group)
    return books


@router.get("/books/{book_id}/content", response_model=ReadingContentResponse)
@limiter.limit("60/minute")
async def get_book_content(
    request: Request,
    book_id: int,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取书籍内容"""
    content = await ReadingService.get_content(session, book_id)
    if not content:
        raise NotFoundError(detail="Book not found")
    return content
