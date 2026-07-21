"""API 路由"""
from fastapi import APIRouter, Request
from fastapi.responses import StreamingResponse
import loguru

from app.pipelines.forward_rewrite import forward_rewrite_pipeline
from app.pipelines.reverse_normalize import reverse_normalize_pipeline
from app.schemas import RewriteRequest, NormalizeRequest, NormalizeResponse
from app.utils.sse import format_sse_event

logger = loguru.logger

router = APIRouter(tags=["Internal"])


@router.post("/internal/rewrite")
async def rewrite(req: RewriteRequest, request: Request):
    """流式 rewrite 接口"""

    async def event_generator():
        try:
            async for event_name, event_data in forward_rewrite_pipeline.rewrite(req.text, req.context):
                yield format_sse_event(event_name, event_data)
        except Exception as e:
            logger.error(f"Rewrite error: {e}")
            yield format_sse_event("error", {"message": str(e)})

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={"X-Request-ID": request.headers.get("X-Request-ID", "")}
    )


@router.post("/internal/normalize", response_model=NormalizeResponse)
async def normalize(req: NormalizeRequest):
    """逆向归一化接口"""
    options = await reverse_normalize_pipeline.normalize(req.text, req.num_options)
    return NormalizeResponse(options=options)


@router.get("/internal/dynamic_fallback")
async def get_dynamic_fallback():
    """获取动态降级词典"""
    from app.services.dynamic_fallback_service import get_dynamic_fallback_service
    service = get_dynamic_fallback_service()
    if service:
        return {"fallback_dict": service.fallback_dict}
    return {"fallback_dict": {}}
