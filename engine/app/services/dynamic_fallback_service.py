"""动态降级服务"""
import json
import asyncio
from typing import Dict, Optional
import httpx
import loguru

from app.services.redis_service import get_redis_service

logger = loguru.logger

_dynamic_fallback_service: Optional["DynamicFallbackService"] = None


class DynamicFallbackService:
    """动态降级词服务"""

    def __init__(self):
        self.fallback_dict: Dict[str, str] = {}
        self.backend_url = None
        self._poll_task = None

    async def initial_load(self, initial_fallback: Dict[str, str]):
        """初始加载"""
        self.fallback_dict = initial_fallback.copy()
        logger.info(f"Loaded {len(self.fallback_dict)} initial fallback entries")

    def set_backend_url(self, url: str):
        """设置后端 URL"""
        self.backend_url = url

    async def incremental_sync(self):
        """增量同步：从后端拉取最新动态降级"""
        if not self.backend_url:
            return

        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                resp = await client.get(f"{self.backend_url}/internal/dynamic_fallback")
                if resp.status_code == 200:
                    data = resp.json()
                    new_dict = data.get("fallback_dict", {})
                    old_count = len(self.fallback_dict)
                    self.fallback_dict.update(new_dict)
                    new_count = len(self.fallback_dict)
                    if new_count > old_count:
                        logger.info(f"Dynamic fallback synced: +{new_count - old_count} entries")
        except Exception as e:
            logger.warning(f"Failed to sync dynamic fallback: {e}")

    def get(self, oov_word: str) -> Optional[str]:
        """获取降级词"""
        return self.fallback_dict.get(oov_word)

    async def start_periodic_sync(self, interval: int = 60):
        """启动定期同步"""
        async def _sync_loop():
            while True:
                await asyncio.sleep(interval)
                try:
                    await self.incremental_sync()
                except Exception as e:
                    logger.error(f"Periodic sync error: {e}")

        self._poll_task = asyncio.create_task(_sync_loop())


def get_dynamic_fallback_service() -> Optional[DynamicFallbackService]:
    return _dynamic_fallback_service


def set_dynamic_fallback_service(service: DynamicFallbackService):
    global _dynamic_fallback_service
    _dynamic_fallback_service = service
