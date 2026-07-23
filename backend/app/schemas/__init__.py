"""Schema 模块（API 数据契约）"""
from app.schemas.auth import (
    RegisterRequest, LoginRequest, TokenResponse, UserResponse
)
from app.schemas.config import AppConfigResponse
from app.schemas.chat import (
    RewriteRequest, AsrAndRewriteRequest,
    TtsRequest, TtsResponse,
    SuggestReplyRequest, SuggestReplyResponse, SuggestionItem,
    NormalizeOptionsRequest, NormalizeOptionsResponse,
    LogMismatchRequest
)
from app.schemas.alignment import AlignmentOp, AlignmentOpType
from app.schemas.reading import (
    ReadingBookResponse,
    ReadingSentenceResponse, ReadingContentResponse
)
from app.schemas.practice import (
    PracticeQuestionResponse,
    PracticeValidateRequest, PracticeValidateResponse
)
from app.schemas.common import ErrorResponse, SuccessResponse
from app.schemas.fallback import FallbackItem, DynamicFallbackResponse

__all__ = [
    # auth
    "RegisterRequest", "LoginRequest", "TokenResponse", "UserResponse",
    # config
    "AppConfigResponse",
    # chat
    "RewriteRequest", "AsrAndRewriteRequest",
    "TtsRequest", "TtsResponse",
    "SuggestReplyRequest", "SuggestReplyResponse", "SuggestionItem",
    "NormalizeOptionsRequest", "NormalizeOptionsResponse",
    "LogMismatchRequest",
    # alignment
    "AlignmentOp", "AlignmentOpType",
    # reading
    "ReadingBookResponse",
    "ReadingSentenceResponse", "ReadingContentResponse",
    # practice
    "PracticeQuestionResponse",
    "PracticeValidateRequest", "PracticeValidateResponse",
    # common
    "ErrorResponse", "SuccessResponse",
    # fallback
    "FallbackItem", "DynamicFallbackResponse",
]
