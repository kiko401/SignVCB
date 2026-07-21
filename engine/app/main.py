"""FastAPI 应用入口"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
import asyncio
import json
from pathlib import Path
import loguru

from app.core.config import get_settings
from app.core.llm_client import close_shared_client
from app.pipelines.forward_rewrite import forward_rewrite_pipeline
from app.pipelines.reverse_normalize import reverse_normalize_pipeline
from app.services.redis_service import init_redis_service, close_redis_service, get_redis_service
from app.services.dynamic_fallback_service import (
    DynamicFallbackService,
    set_dynamic_fallback_service,
    get_dynamic_fallback_service
)
from app.api.routes import router as rewrite_router
from app.api.health import router as health_router

logger = loguru.logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting SignVCB Engine...")
    settings = get_settings()

    # 1. 初始化 Redis
    try:
        await init_redis_service(settings.REDIS_HOST, settings.REDIS_PORT)
    except Exception as e:
        logger.warning(f"Redis not connected: {e}")

    # 2. 初始化 rewrite 流水线
    try:
        forward_rewrite_pipeline.initialize(
            index_path=settings.FAISS_INDEX_PATH,
            vocab_path=settings.VOCAB_PATH,
            fallback_path=settings.INITIAL_FALLBACK_PATH,
            redis_service=get_redis_service()
        )
    except Exception as e:
        logger.warning(f"Rewrite pipeline init warning: {e}")

    # 3. 初始化 normalize 流水线
    try:
        reverse_normalize_pipeline.initialize()
    except Exception as e:
        logger.warning(f"Normalize pipeline init warning: {e}")

    # 4. 初始化动态降级服务
    try:
        initial_fallback = {}
        if Path(settings.INITIAL_FALLBACK_PATH).exists():
            with open(settings.INITIAL_FALLBACK_PATH, encoding="utf-8") as f:
                initial_fallback = json.load(f)

        service = DynamicFallbackService()
        await service.initial_load(initial_fallback)
        service.set_backend_url(f"http://{settings.BACKEND_HOST}:{settings.BACKEND_PORT}")
        set_dynamic_fallback_service(service)

        # 同时启动 PubSub 订阅 + 定期同步
        redis_service = get_redis_service()
        await service.start(redis_service, settings.DYNAMIC_FALLBACK_SYNC_INTERVAL)
    except Exception as e:
        logger.warning(f"Dynamic fallback service not initialized: {e}")

    logger.info("SignVCB Engine started")

    yield

    # 关闭阶段
    logger.info("Shutting down SignVCB Engine...")

    # 1. 关闭 DynamicFallbackService 后台任务
    service = get_dynamic_fallback_service()
    if service:
        await service.stop()

    # 2. 关闭 Redis
    await close_redis_service()

    # 3. 关闭 DeepSeek 客户端（必须 await）
    await close_shared_client()

    logger.info("SignVCB Engine stopped")


def create_app() -> FastAPI:
    app = FastAPI(
        title="默语共鸣 Engine",
        version="3.3",
        lifespan=lifespan,
        docs_url=None
    )

    app.include_router(rewrite_router)
    app.include_router(health_router)

    return app


app = create_app()
