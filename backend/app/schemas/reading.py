"""读物相关 Schema"""
from typing import Optional, List
from pydantic import BaseModel
from app.schemas.alignment import AlignmentOp


class ReadingBookResponse(BaseModel):
    """单个书籍响应"""
    id: int
    title: str
    age_group: str
    cover_url: Optional[str]
    difficulty: int


class ReadingSentenceResponse(BaseModel):
    """阅读句子响应"""
    index: int
    original: str
    sign_text: str
    alignment_ops: List[AlignmentOp]


class ReadingContentResponse(BaseModel):
    """阅读内容响应"""
    book_id: int
    sentences: List[ReadingSentenceResponse]
