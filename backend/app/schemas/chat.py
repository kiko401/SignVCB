"""聊天相关 Schema（API 请求与响应）"""
from typing import Optional
from pydantic import BaseModel


# ─── 请求 ───────────────────────────────────────────────────

class RewriteRequest(BaseModel):
    text: str
    context: Optional[str] = None


class AsrAndRewriteRequest(BaseModel):
    text: str
    context: Optional[str] = None


class TtsRequest(BaseModel):
    text: str
    speed: float = 1.0


class SuggestReplyRequest(BaseModel):
    text: str
    context: Optional[str] = None


class NormalizeOptionsRequest(BaseModel):
    text: str
    num_options: int = 3


class LogMismatchRequest(BaseModel):
    original_text: str
    failed_options: list[str]
    context: Optional[str] = None


# ─── 响应 ───────────────────────────────────────────────────

class TtsResponse(BaseModel):
    audio_url: str


class SuggestionItem(BaseModel):
    text: str
    reason: Optional[str] = None


class SuggestReplyResponse(BaseModel):
    suggestions: list[SuggestionItem]


class NormalizeOptionsResponse(BaseModel):
    options: list[str]
