"""OOV 消费者 - 监听 Redis 队列并写入数据库"""
import asyncio
import redis.asyncio as redis
import json
from sqlalchemy import select
from app.core.database import AsyncSessionLocal
from app.models.fallback import DynamicFallback
import loguru

logger = loguru.logger


class OOVFallbackConsumer:
    """OOV 降级词消费者"""

    def __init__(self, redis_url: str = None, queue_key: str = "queue:oov_fallback"):
        from app.core.config import get_settings
        settings = get_settings()

        self.redis_url = redis_url or f"redis://{settings.REDIS_HOST}:{settings.REDIS_PORT}"
        self.queue_key = queue_key
        self.running = False

    async def start(self):
        """启动消费者"""
        self.running = True
        self.redis_client = redis.from_url(self.redis_url)

        while self.running:
            try:
                result = await self.redis_client.blpop(self.queue_key, timeout=5)
                if result:
                    _, message = result
                    await self._process_message(message)
            except asyncio.CancelledError:
                # 收到取消信号，安全退出循环
                break
            except Exception as e:
                logger.error(f"OOV consumer error: {e}")
                await asyncio.sleep(1)

    async def _process_message(self, message: bytes):
        """处理消息"""
        try:
            data = json.loads(message)
            oov_word = data.get("oov_word")
            fallback_word = data.get("fallback_word")

            if not oov_word or not fallback_word:
                return

            async with AsyncSessionLocal() as session:
                stmt = select(DynamicFallback).where(
                    DynamicFallback.oov_word == oov_word
                )
                result = await session.execute(stmt)
                existing = result.scalar_one_or_none()

                if existing:
                    existing.fallback_word = fallback_word
                else:
                    new_fallback = DynamicFallback(
                        oov_word=oov_word,
                        fallback_word=fallback_word
                    )
                    session.add(new_fallback)

                await session.commit()

            pubsub_msg = json.dumps({"oov": oov_word, "fallback": fallback_word}, ensure_ascii=False)
            await self.redis_client.publish("pubsub:dynamic_fallback_updated", pubsub_msg)

        except Exception as e:
            logger.error(f"Failed to process OOV message: {e}")

    async def stop(self):
        """停止消费者"""
        self.running = False
        await self.redis_client.close()

    def run_sync(self):
        """同步运行（供 Thread 调用）"""
        asyncio.run(self.start())
