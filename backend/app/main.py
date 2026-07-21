"""FastAPI 应用入口"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import loguru

from app.core.config import get_settings
from app.core.logging import init_logging
from app.core.middleware import RequestIDMiddleware
from app.core.exceptions import register_exception_handlers
from app.api.v1 import router as v1_router
from app.api.internal import router as internal_router

init_logging()
logger = loguru.logger


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting SignVCB Server...")
    yield
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
