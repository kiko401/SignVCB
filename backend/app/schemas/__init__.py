"""Schema 模块"""
from app.schemas.auth import (
    RegisterRequest, LoginRequest, TokenResponse, UserResponse
)
from app.schemas.config import AppConfigResponse
from app.schemas.chat import (
    PreheatData, FirstPassData, RefinedPassData, FallbackData,
    RewriteRequest, AsrAndRewriteRequest,
    TtsRequest, TtsResponse,
    SuggestReplyRequest, SuggestReplyResponse, SuggestionItem,
    NormalizeOptionsRequest, NormalizeOptionsResponse,
    LogMismatchRequest
)
from app.schemas.alignment import AlignmentOp, AlignmentOpType
from app.schemas.reading import (
    ReadingBookResponse, ReadingBooksResponse,
    ReadingSentenceResponse, ReadingContentResponse
)
from app.schemas.practice import (
    PracticeQuestionResponse,
    PracticeValidateRequest, PracticeValidateResponse
)
from app.schemas.common import ErrorResponse, SuccessResponse
from app.schemas.fallback import FallbackItem, DynamicFallbackResponse

__all__ = [
    "RegisterRequest", "LoginRequest", "TokenResponse", "UserResponse",
    "AppConfigResponse",
    "PreheatData", "FirstPassData", "RefinedPassData", "FallbackData",
    "RewriteRequest", "AsrAndRewriteRequest",
    "TtsRequest", "TtsResponse",
    "SuggestReplyRequest", "SuggestReplyResponse", "SuggestionItem",
    "NormalizeOptionsRequest", "NormalizeOptionsResponse",
    "LogMismatchRequest",
    "AlignmentOp", "AlignmentOpType",
    "ReadingBookResponse", "ReadingBooksResponse",
    "ReadingSentenceResponse", "ReadingContentResponse",
    "PracticeQuestionResponse",
    "PracticeValidateRequest", "PracticeValidateResponse",
    "ErrorResponse", "SuccessResponse",
    "FallbackItem", "DynamicFallbackResponse",
]
