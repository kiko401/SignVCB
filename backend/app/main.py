"""FastAPI 应用入口"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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
    logger.info("Starting SignVCB Server...")
    from app.services.oov_consumer import OOVFallbackConsumer
    from threading import Thread
    consumer = OOVFallbackConsumer()
    t = Thread(target=lambda: consumer.run_sync(), daemon=True)
    t.start()
    logger.info("OOVFallbackConsumer started in background thread")
    yield
    await consumer.stop()
    logger.info("Shutting down SignVCB Server...")


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

    # Health
    @app.get("/health")
    async def health():
        return {"status": "ok"}

    return app


app = create_app()
