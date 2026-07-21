"""Redis 服务"""
import asyncio
import json as json_module
import redis.asyncio as redis
from typing import Optional, Callable, Awaitable
import loguru

logger = loguru.logger

_redis_instance: Optional["RedisService"] = None


class RedisService:
    """Redis 服务（连接复用）"""

    def __init__(self):
        self.client: Optional[redis.Redis] = None

    async def connect(self, host: str, port: int):
        """建立连接"""
        try:
            self.client = redis.Redis(host=host, port=port, decode_responses=False)
            await self.client.ping()
            logger.info(f"Redis connected: {host}:{port}")
        except Exception as e:
            logger.error(f"Redis connection failed: {e}")
            raise

    async def close(self):
        """关闭连接"""
        if self.client:
            await self.client.close()
            self.client = None

    async def lpush(self, key: str, value: str):
        """左推"""
        if not self.client:
            return
        try:
            await self.client.lpush(key, value)
        except Exception as e:
            logger.error(f"LPUSH failed: {e}")

    async def blpop(self, key: str, timeout: int = 5) -> Optional[tuple]:
        """阻塞左弹出"""
        if not self.client:
            return None
        try:
            result = await self.client.blpop(key, timeout=timeout)
            return result
        except Exception as e:
            logger.error(f"BLPOP failed: {e}")
            return None

    async def publish(self, channel: str, message: str):
        """发布"""
        if not self.client:
            return
        try:
            await self.client.publish(channel, message)
        except Exception as e:
            logger.error(f"Publish failed: {e}")

    async def subscribe(self, channel: str) -> redis.client.PubSub:
        """订阅频道，返回 PubSub 对象"""
        if not self.client:
            raise RuntimeError("Redis not connected")
        pubsub = self.client.pubsub()
        await pubsub.subscribe(channel)
        return pubsub

    async def subscribe_dynamic_fallback(self, callback: Callable[[str, str], Awaitable[None]]):
        """订阅 dynamic_fallback_updated 频道，收到消息时调用 callback(oov_word, fallback_word)。

        后端 OOV 消费者 UPSERT 到 MySQL 后发布 PubSub，
        算法引擎订阅并实时增量更新本地 fallback_dict。
        异常后指数退避重连（最大 30s）。
        """
        channel = "pubsub:dynamic_fallback_updated"
        retry_delay = 3
        max_delay = 30

        while True:
            try:
                pubsub = await self.subscribe(channel)
                logger.info(f"Subscribed to {channel}")
                retry_delay = 3  # 重置退避

                async for message in pubsub.listen():
                    if message["type"] == "message":
                        try:
                            data = json_module.loads(message["data"])
                            oov_word = data.get("oov", "")
                            fallback_word = data.get("fallback", "")
                            if oov_word and fallback_word:
                                await callback(oov_word, fallback_word)
                                logger.debug(f"PubSub update: {oov_word} -> {fallback_word}")
                        except Exception as e:
                            logger.warning(f"PubSub message parse error: {e}")
            except Exception as e:
                logger.warning(f"PubSub subscribe error: {e}, retrying in {retry_delay}s...")
                await asyncio.sleep(retry_delay)
                retry_delay = min(retry_delay * 2, max_delay)


def get_redis_service() -> Optional[RedisService]:
    return _redis_instance


async def init_redis_service(host: str, port: int):
    global _redis_instance
    _redis_instance = RedisService()
    await _redis_instance.connect(host, port)


async def close_redis_service():
    global _redis_instance
    if _redis_instance:
        await _redis_instance.close()
        _redis_instance = None
