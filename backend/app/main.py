"""FastAPI 应用入口"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from slowapi import _rate_limit_exceeded_handler
from slowapi.errors import RateLimitExceeded
import loguru

from app.core.config import get_settings
from app.core.logging import init_logging
from app.core.middleware import RequestIDMiddleware
from app.core.exceptions import register_exception_handlers
from app.core.rate_limit import limiter
from app.api.v1 import router as v1_router
from app.api.internal import router as internal_router

init_logging()
logger = loguru.logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    from app.core.database import engine, redis_client
    from app.services.engine_client import EngineClient
    from app.services.suggest_service import SuggestService
    from sqlalchemy import text
    import os

    logger.info("Starting SignVCB Server...")

    # 1. 校验数据库连接
    try:
        async with engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        logger.info("MySQL connected")
    except Exception as e:
        logger.error(f"MySQL connection failed: {e}")
        raise

    # 2. 校验 Redis 连接
    try:
        await redis_client.ping()
        logger.info("Redis connected")
    except Exception as e:
        logger.error(f"Redis connection failed: {e}")
        raise

    # 3. 校验算法引擎可达（启动时检查，失败不阻塞但 warning）
    try:
        engine_client = EngineClient()
        if await engine_client.health_check():
            logger.info("Engine healthy")
        else:
            logger.warning("Engine not reachable at startup (will retry on request)")
    except Exception as e:
        logger.warning(f"Engine health check failed: {e}")

    # 4. 确保 TTS 音频目录存在
    from app.core.config import get_settings
    settings = get_settings()
    os.makedirs(settings.TTS_AUDIO_DIR, exist_ok=True)

    # 5. 启动 OOV 队列消费者（daemon thread）
    # consumer = OOVFallbackConsumer()
    # t = Thread(target=lambda: consumer.run_sync(), daemon=True)
    # t.start()
    # logger.info("OOVFallbackConsumer started in background thread")

    yield

    # ===== 关闭阶段 =====
    logger.info("Shutting down SignVCB Server...")

    # 1. 停止 OOV 消费者
    # await consumer.stop()

    # 2. 关闭 SuggestService
    try:
        await SuggestService.close()
    except Exception as e:
        logger.warning(f"SuggestService close error: {e}")

    # 3. 关闭 EngineClient
    try:
        await EngineClient.get_instance().close()
    except Exception as e:
        logger.warning(f"EngineClient close error: {e}")

    # 4. 关闭 Redis
    try:
        await redis_client.close()
    except Exception as e:
        logger.warning(f"Redis close error: {e}")

    # 5. 关闭数据库引擎
    try:
        await engine.dispose()
    except Exception as e:
        logger.warning(f"Engine dispose error: {e}")

    logger.info("SignVCB Server stopped")


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="默语共鸣 Server",
        version="3.3",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url=None
    )

    # Rate limiter
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

    # CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ALLOW_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Request ID Middleware
    app.add_middleware(RequestIDMiddleware)

    # Exception handlers
    register_exception_handlers(app)

    # Routes
    app.include_router(v1_router)
    app.include_router(internal_router)

    # TTS 静态文件挂载
    import os
    os.makedirs(settings.TTS_AUDIO_DIR, exist_ok=True)
    app.mount("/tts_audio", StaticFiles(directory=settings.TTS_AUDIO_DIR), name="tts_audio")

    # Health
    @app.get("/health")
    async def health():
        from app.core.database import engine, redis_client
        from app.services.engine_client import EngineClient
        from sqlalchemy import text

        deps = {}

        # 1. MySQL
        try:
            async with engine.connect() as conn:
                await conn.execute(text("SELECT 1"))
            deps["mysql"] = "ok"
        except Exception:
            deps["mysql"] = "fail"

        # 2. Redis
        try:
            await redis_client.ping()
            deps["redis"] = "ok"
        except Exception:
            deps["redis"] = "fail"

        # 3. Engine
        try:
            engine_client = EngineClient()
            engine_ok = await engine_client.health_check()
            deps["engine"] = "ok" if engine_ok else "fail"
        except Exception:
            deps["engine"] = "fail"

        all_ok = all(v == "ok" for v in deps.values())
        return {
            "status": "healthy" if all_ok else "degraded",
            "dependencies": deps
        }

    return app


app = create_app()
