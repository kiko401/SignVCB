"""算法引擎客户端"""
import httpx
import json
from typing import AsyncGenerator
import loguru

logger = loguru.logger


class EngineTimeoutError(Exception):
    """引擎超时异常"""
    pass


class EngineClient:
    """算法引擎 HTTP 客户端"""

    def __init__(self, base_url: str = None, timeout: float = None):
        from app.core.config import get_settings
        settings = get_settings()

        self.base_url = base_url or settings.ALGORITHM_ENGINE_URL
        self.timeout = timeout or settings.ENGINE_TIMEOUT
        self.client = httpx.AsyncClient(
            timeout=httpx.Timeout(self.timeout),
            follow_redirects=True
        )

    @classmethod
    def get_instance(cls):
        return cls()

    async def stream_rewrite(
        self, text: str, context: str = None, request_id: str = ""
    ) -> AsyncGenerator[tuple[str, dict], None]:
        """流式调用 rewrite 接口"""
        headers = {}
        if request_id:
            headers["X-Request-ID"] = request_id

        try:
            async with self.client.stream(
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
            resp = await self.client.post(
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
            resp = await self.client.get(f"{self.base_url}/health")
            return resp.status_code == 200
        except:
            return False

    async def close(self):
        await self.client.aclose()


def format_sse_event(event: str, data: dict) -> str:
    """格式化 SSE 事件"""
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"
