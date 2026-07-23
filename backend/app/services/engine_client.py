"""算法引擎客户端"""
import httpx
import json
import threading
from typing import AsyncGenerator, Optional
import loguru

logger = loguru.logger


class EngineTimeoutError(Exception):
    """引擎超时异常"""
    pass


class EngineClient:
    """算法引擎 HTTP 客户端（懒加载单例，线程安全）"""

    _instance: Optional["EngineClient"] = None
    _client: Optional[httpx.AsyncClient] = None
    _lock: threading.Lock = threading.Lock()

    def __init__(self, base_url: str = None, timeout: float = None):
        from app.core.config import get_settings
        settings = get_settings()
        self.base_url = base_url or settings.ALGORITHM_ENGINE_URL
        self.timeout = timeout or settings.ENGINE_TIMEOUT

    @classmethod
    def get_instance(cls) -> "EngineClient":
        if cls._instance is None:
            with cls._lock:
                # 双重检查锁定（Double-Checked Locking）
                if cls._instance is None:
                    cls._instance = cls()
        return cls._instance

    @classmethod
    def get_client(cls) -> httpx.AsyncClient:
        """懒加载共享 httpx 客户端"""
        if cls._client is None or cls._client.is_closed:
            with cls._lock:
                if cls._client is None or cls._client.is_closed:
                    timeout = cls._instance.timeout if cls._instance else 10.0
                    cls._client = httpx.AsyncClient(
                        timeout=httpx.Timeout(timeout),
                        follow_redirects=True,
                        limits=httpx.Limits(max_connections=10, max_keepalive_connections=5),
                    )
        return cls._client

    @classmethod
    async def close(cls):
        """关闭共享客户端（在 lifespan 关闭阶段调用）"""
        if cls._client is not None and not cls._client.is_closed:
            await cls._client.aclose()
            cls._client = None

    async def stream_rewrite(
        self, text: str, context: str = None, request_id: str = ""
    ) -> AsyncGenerator[tuple[str, dict], None]:
        """流式调用 rewrite 接口"""
        headers = {}
        if request_id:
            headers["X-Request-ID"] = request_id

        try:
            async with self.get_client().stream(
                "POST",
                f"{self.base_url}/internal/rewrite",
                json={"text": text, "context": context},
                headers=headers
            ) as resp:
                async for line in resp.aiter_lines():
                    if line.startswith("event:"):
                        event_name = line.replace("event:", "").strip()
                    elif line.startswith("data:"):
                        data_str = line.replace("data:", "").strip()
                        if data_str:
                            try:
                                data = json.loads(data_str)
                                yield (event_name or "message"), data
                            except json.JSONDecodeError:
                                pass
        except httpx.TimeoutException:
            raise EngineTimeoutError("Engine timeout")

    async def normalize(self, text: str, num_options: int = 3) -> list[str]:
        """调用 normalize 接口"""
        try:
            resp = await self.get_client().post(
                f"{self.base_url}/internal/normalize",
                json={"text": text, "num_options": num_options}
            )
            return resp.json().get("options", [])
        except Exception as e:
            logger.error(f"Normalize failed: {e}")
            return []

    async def health_check(self) -> bool:
        """检查引擎健康状态"""
        try:
            resp = await self.get_client().get(f"{self.base_url}/health")
            return resp.status_code == 200
        except:
            return False


def format_sse_event(event: str, data: dict) -> str:
    """格式化 SSE 事件"""
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"
