"""降级相关 Schema"""
from pydantic import BaseModel


class FallbackItem(BaseModel):
    oov: str
    fallback: str


class DynamicFallbackResponse(BaseModel):
    items: list[FallbackItem]
    server_time: str
    count: int
