"""动态降级服务"""
import asyncio
from typing import Dict, Optional, Any
import httpx
import loguru

logger = loguru.logger

_dynamic_fallback_service: Optional["DynamicFallbackService"] = None


class DynamicFallbackService:
    """动态降级词服务"""

    def __init__(self):
        self.fallback_dict: Dict[str, str] = {}
        self.backend_url: Optional[str] = None
        self._poll_task: Optional[asyncio.Task] = None
        self._pubsub_task: Optional[asyncio.Task] = None
        self._redis_service: Any = None

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
                    # 支持新旧两种格式（后端可能尚未更新到新格式）
                    if "items" in data:
                        new_dict = {item["oov"]: item["fallback"] for item in data.get("items", [])}
                    elif "fallback_dict" in data:
                        new_dict = data.get("fallback_dict", {})
                    else:
                        new_dict = {}
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

    async def start(self, redis_service, periodic_interval: int = 60):
        """启动动态降级服务（供 lifespan 调用）

        同时启动：
        1. PubSub 订阅（实时接收后端 OOV 消费者通知）
        2. 定期全量同步（兜底，每 periodic_interval 秒一次）
        """
        self._redis_service = redis_service

        # 1. 启动 PubSub 订阅（实时增量更新）
        if redis_service:
            self._pubsub_task = asyncio.create_task(
                self._pubsub_loop(redis_service)
            )
            logger.info("DynamicFallbackService PubSub subscription started")

        # 2. 启动定期同步（兜底）
        self._poll_task = asyncio.create_task(
            self._sync_loop(periodic_interval)
        )
        logger.info(f"DynamicFallbackService periodic sync started (interval={periodic_interval}s)")

    async def _pubsub_loop(self, redis_service):
        """PubSub 订阅循环"""
        try:
            await redis_service.subscribe_dynamic_fallback(self._on_fallback_update)
        except asyncio.CancelledError:
            logger.info("PubSub loop cancelled")
            raise
        except Exception as e:
            logger.error(f"PubSub loop error: {e}")

    async def _on_fallback_update(self, oov_word: str, fallback_word: str):
        """收到 PubSub 通知时增量更新本地词典"""
        if oov_word not in self.fallback_dict or self.fallback_dict[oov_word] != fallback_word:
            old_count = len(self.fallback_dict)
            self.fallback_dict[oov_word] = fallback_word
            logger.info(f"Dynamic fallback updated via PubSub: {oov_word} -> {fallback_word} (+{len(self.fallback_dict) - old_count})")

    async def start_periodic_sync(self, interval: int = 60):
        """启动定期同步（兼容旧调用）"""
        self._poll_task = asyncio.create_task(self._sync_loop(interval))

    async def _sync_loop(self, interval: int):
        """定期同步循环"""
        while True:
            await asyncio.sleep(interval)
            try:
                await self.incremental_sync()
            except Exception as e:
                logger.error(f"Periodic sync error: {e}")

    async def stop(self):
        """停止所有后台任务（供 lifespan 关闭调用）"""
        if self._poll_task:
            self._poll_task.cancel()
            try:
                await self._poll_task
            except asyncio.CancelledError:
                pass
            self._poll_task = None

        if self._pubsub_task:
            self._pubsub_task.cancel()
            try:
                await self._pubsub_task
            except asyncio.CancelledError:
                pass
            self._pubsub_task = None

        logger.info("DynamicFallbackService stopped")


def get_dynamic_fallback_service() -> Optional[DynamicFallbackService]:
    return _dynamic_fallback_service


def set_dynamic_fallback_service(service: DynamicFallbackService):
    global _dynamic_fallback_service
    _dynamic_fallback_service = service
