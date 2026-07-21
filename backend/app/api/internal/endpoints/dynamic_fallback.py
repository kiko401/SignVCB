"""动态降级词典接口"""
from fastapi import APIRouter
from app.core.database import AsyncSessionLocal
from sqlalchemy import select
from app.models.fallback import DynamicFallback
from app.schemas.fallback import DynamicFallbackResponse, FallbackItem
from datetime import datetime

router = APIRouter()


@router.get("/dynamic_fallback")
async def get_dynamic_fallback():
    """获取所有动态降级词"""
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(DynamicFallback))
        entries = result.scalars().all()
        items = [FallbackItem(oov=e.oov_word, fallback=e.fallback_word) for e in entries]
        return DynamicFallbackResponse(
            items=items,
            server_time=datetime.utcnow().isoformat() + "Z",
            count=len(items)
        )
