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
    NormalizeOptionsRequest, NormalizeOptionsResponse
)
from app.services.chat_service import ChatService
from app.services.engine_client import format_sse_event

router = APIRouter()


@router.post("/rewrite")
async def rewrite(req: RewriteRequest, request: Request):
    """流式 rewrite"""
    request_id = request.headers.get("X-Request-ID", "")

    async def event_generator():
        async for event_name, event_data in ChatService.stream_rewrite(
            req.text, req.context, request_id
        ):
            yield format_sse_event(event_name, event_data)

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.post("/asr_rewrite")
async def asr_rewrite(req: AsrAndRewriteRequest, request: Request):
    """ASR + rewrite"""
    request_id = request.headers.get("X-Request-ID", "")

    async def event_generator():
        async for event_name, event_data in ChatService.asr_and_stream_rewrite(
            req.text.encode(), req.context, request_id
        ):
            yield format_sse_event(event_name, event_data)

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.post("/tts", response_model=TtsResponse)
async def tts(req: TtsRequest):
    """TTS 合成"""
    audio_url = await ChatService.tts(req.text, req.speed)
    return TtsResponse(audio_url=audio_url)


@router.post("/suggest", response_model=SuggestReplyResponse)
async def suggest(req: SuggestReplyRequest):
    """建议回复"""
    suggestions = await ChatService.suggest_reply(req.text)
    return SuggestReplyResponse(suggestions=suggestions)


@router.post("/normalize", response_model=NormalizeOptionsResponse)
async def normalize(req: NormalizeOptionsRequest):
    """逆向归一化"""
    options = await ChatService.normalize_options(req.text, req.num_options)
    return NormalizeOptionsResponse(options=options)
