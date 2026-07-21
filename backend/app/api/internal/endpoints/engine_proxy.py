"""引擎代理接口（供后端内部调用）"""
from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
from app.services.engine_client import EngineClient, EngineTimeoutError, format_sse_event

router = APIRouter()


@router.post("/rewrite")
async def rewrite(req: Request):
    """透传 rewrite 请求到引擎"""
    body = await req.json()
    text = body.get("text", "")
    context = body.get("context")
    request_id = req.headers.get("X-Request-ID", "")

    engine = EngineClient.get_instance()

    async def event_generator():
        try:
            async for event_name, event_data in engine.stream_rewrite(text, context, request_id):
                yield format_sse_event(event_name, event_data)
        except EngineTimeoutError:
            yield format_sse_event("fallback", {"fallback_text": "引擎超时"})
        finally:
            await engine.close()

    return StreamingResponse(event_generator(), media_type="text/event-stream")


@router.get("/health")
async def engine_health():
    """引擎健康检查"""
    engine = EngineClient.get_instance()
    ok = await engine.health_check()
    await engine.close()
    return {"engine": "ok" if ok else "error"}
