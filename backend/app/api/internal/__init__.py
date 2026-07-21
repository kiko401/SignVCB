"""Internal API"""
from fastapi import APIRouter
from app.api.internal.endpoints import engine_proxy, dynamic_fallback

router = APIRouter(prefix="/internal")
router.include_router(engine_proxy.router, tags=["Engine"])
router.include_router(dynamic_fallback.router, tags=["Fallback"])
