"""动态降级词典接口"""
from fastapi import APIRouter
from app.core.database import AsyncSessionLocal
from sqlalchemy import select
from app.models.fallback import DynamicFallback

router = APIRouter()


@router.get("/dynamic_fallback")
async def get_dynamic_fallback():
    """获取所有动态降级词"""
    async with AsyncSessionLocal() as session:
        result = await session.execute(select(DynamicFallback))
        entries = result.scalars().all()
        fallback_dict = {e.oov_word: e.fallback_word for e in entries}
        return {"fallback_dict": fallback_dict}
