"""API v1"""
from fastapi import APIRouter
from app.api.v1.endpoints import auth, chat, reading, practice, config

router = APIRouter(prefix="/api/v1")
router.include_router(auth.router, prefix="/auth", tags=["Auth"])
router.include_router(chat.router, prefix="/chat", tags=["Chat"])
router.include_router(reading.router, prefix="/reading", tags=["Reading"])
router.include_router(practice.router, prefix="/practice", tags=["Practice"])
router.include_router(config.router, prefix="", tags=["Config"])
