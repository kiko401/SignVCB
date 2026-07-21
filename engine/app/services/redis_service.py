"""Redis 服务"""
import redis.asyncio as redis
from typing import Optional
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
