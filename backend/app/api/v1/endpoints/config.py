"""配置接口"""
from fastapi import APIRouter, Request
from app.schemas.config import AppConfigResponse
from app.core.config import get_settings
from app.core.rate_limit import limiter

router = APIRouter()


@router.get("/app_config", response_model=AppConfigResponse)
@limiter.limit("60/minute")
async def get_app_config(request: Request):
    """获取应用配置（匿名公共接口，无需登录）"""
    settings = get_settings()
    return AppConfigResponse(
        enable_stream_masking=settings.ENABLE_STREAM_MASKING,
        show_oov_map=settings.SHOW_OOV_MAP,
        show_nmm_hints=settings.SHOW_NMM_HINTS,
        sse_timeout_ms=settings.SSE_TIMEOUT_MS
    )
