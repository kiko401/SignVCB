"""Internal API（供后端内部调用或运维管理）"""
from fastapi import APIRouter
from app.api.internal.endpoints import dynamic_fallback

router = APIRouter(prefix="/internal")
router.include_router(dynamic_fallback.router, tags=["Fallback"])
