"""读物相关 Schema"""
from typing import Optional
from pydantic import BaseModel


class ReadingBookResponse(BaseModel):
    id: int
    title: str
    age_group: str
    cover_url: Optional[str]
    difficulty: int


class ReadingBooksResponse(BaseModel):
    books: list[ReadingBookResponse]


class ReadingSentenceResponse(BaseModel):
    id: int
    sentence_index: int
    original_text: str
    sign_text: str
    alignment_ops: list


class ReadingContentResponse(BaseModel):
    book: ReadingBookResponse
    sentences: list[ReadingSentenceResponse]
