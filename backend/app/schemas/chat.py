"""聊天相关 Schema"""
from typing import Optional
from pydantic import BaseModel


class PreheatData(BaseModel):
    original: str = ""


class FirstPassData(BaseModel):
    text: str
    oov_status: bool


class RefinedPassData(BaseModel):
    text: str
    oov_map: dict[str, str]
    nmm_hints: dict[str, str]
    alignment_ops: list


class FallbackData(BaseModel):
    fallback_text: str


class RewriteRequest(BaseModel):
    text: str
    context: Optional[str] = None


class AsrAndRewriteRequest(BaseModel):
    text: str
    context: Optional[str] = None


class TtsRequest(BaseModel):
    text: str
    speed: float = 1.0


class TtsResponse(BaseModel):
    audio_url: str


class SuggestReplyRequest(BaseModel):
    text: str
    context: Optional[str] = None


class SuggestionItem(BaseModel):
    text: str
    reason: Optional[str] = None


class SuggestReplyResponse(BaseModel):
    suggestions: list[SuggestionItem]


class NormalizeOptionsRequest(BaseModel):
    text: str
    num_options: int = 3


class NormalizeOptionsResponse(BaseModel):
    options: list[str]


class LogMismatchRequest(BaseModel):
    original_text: str
    failed_options: list[str]
    context: Optional[str] = None
