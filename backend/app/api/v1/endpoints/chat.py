"""聊天接口"""
from fastapi import APIRouter, Depends, Request
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from app.core.database import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.chat import (
    RewriteRequest, AsrAndRewriteRequest,
    TtsRequest, TtsResponse,
    SuggestReplyRequest, SuggestReplyResponse,
    NormalizeOptionsRequest, NormalizeOptionsResponse,
    LogMismatchRequest
)
from app.schemas.common import SuccessResponse
from app.services.chat_service import ChatService
from app.services.engine_client import format_sse_event
from app.core.rate_limit import limiter
from app.models.fallback import IntentMismatchLog
import json

router = APIRouter()


@router.post("/rewrite")
@limiter.limit("30/minute")
async def rewrite(request: Request, req: RewriteRequest):
    """流式 rewrite"""
    request_id = request.headers.get("X-Request-ID", "")

    async def event_generator():
        async for event_name, event_data in ChatService.stream_rewrite(
            req.text, req.context, request_id
        ):
            yield format_sse_event(event_name, event_data)

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.post("/asr_rewrite")
@limiter.limit("15/minute")
async def asr_rewrite(request: Request, req: AsrAndRewriteRequest):
    """ASR + rewrite"""
    request_id = request.headers.get("X-Request-ID", "")

    async def event_generator():
        async for event_name, event_data in ChatService.asr_and_stream_rewrite(
            req.text.encode(), req.context, request_id
        ):
            yield format_sse_event(event_name, event_data)

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.post("/tts", response_model=TtsResponse)
@limiter.limit("30/minute")
async def tts(request: Request, req: TtsRequest):
    """TTS 合成"""
    audio_url = await ChatService.tts(req.text, req.speed)
    return TtsResponse(audio_url=audio_url)


@router.post("/suggest", response_model=SuggestReplyResponse)
@limiter.limit("30/minute")
async def suggest(request: Request, req: SuggestReplyRequest):
    """建议回复"""
    suggestions = await ChatService.suggest_reply(req.text, req.context)
    return SuggestReplyResponse(suggestions=suggestions)


@router.post("/normalize", response_model=NormalizeOptionsResponse)
@limiter.limit("30/minute")
async def normalize(request: Request, req: NormalizeOptionsRequest):
    """逆向归一化"""
    options = await ChatService.normalize_options(req.text, req.num_options)
    return NormalizeOptionsResponse(options=options)


@router.post("/log_mismatch", response_model=SuccessResponse)
@limiter.limit("30/minute")
async def log_mismatch(
    request: Request,
    req: LogMismatchRequest,
    session: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """记录用户选择的意图不匹配选项"""
    log = IntentMismatchLog(
        user_id=current_user.id,
        original_text=req.original_text,
        failed_options=json.dumps(req.failed_options, ensure_ascii=False),
        context=req.context
    )
    session.add(log)
    await session.commit()
    return SuccessResponse(status="ok")
