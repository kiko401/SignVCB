"""读物相关 Schema"""
from typing import Optional, List
from pydantic import BaseModel
from app.schemas.alignment import AlignmentOp


class ReadingBookResponse(BaseModel):
    id: int
    title: str
    age_group: str
    cover_url: Optional[str]
    difficulty: int


class ReadingSentenceResponse(BaseModel):
    index: int
    original: str
    sign_text: str
    alignment_ops: List[AlignmentOp]


class ReadingBooksResponse(BaseModel):
    books: List[ReadingBookResponse]


class ReadingContentResponse(BaseModel):
    book_id: int
    sentences: List[ReadingSentenceResponse]
