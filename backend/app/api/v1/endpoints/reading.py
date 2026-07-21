"""读物接口"""
from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.reading import ReadingBooksResponse, ReadingContentResponse
from app.services.reading_service import ReadingService
from app.core.rate_limit import limiter

router = APIRouter()


@router.get("/books", response_model=ReadingBooksResponse)
@limiter.limit("60/minute")
async def get_books(
    request: Request,
    age_group: str = None,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """获取书籍列表"""
    books = await ReadingService.get_books(session, age_group)
    return ReadingBooksResponse(books=books)


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
        raise HTTPException(status_code=404, detail="Book not found")
    return content
