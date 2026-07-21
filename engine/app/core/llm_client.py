"""DeepSeek LLM 客户端（全局单例）"""
import httpx
from typing import Optional
import loguru

logger = loguru.logger

_client: Optional["DeepSeekClient"] = None


class DeepSeekClient:
    """DeepSeek API 客户端"""

    def __init__(self, api_key: str = None, model: str = None, base_url: str = None):
        from app.core.config import get_settings
        settings = get_settings()

        self.api_key = api_key or settings.DEEPSEEK_API_KEY
        self.model = model or settings.DEEPSEEK_MODEL
        self.base_url = base_url or settings.DEEPSEEK_BASE_URL
        self.client = httpx.AsyncClient(timeout=30.0)

    @classmethod
    def get_client(cls) -> "DeepSeekClient":
        global _client
        if _client is None:
            _client = cls()
        return _client

    @classmethod
    def close_shared_client(cls):
        global _client
        if _client is not None:
            import asyncio
            asyncio.create_task(_client.client.aclose())
            _client = None

    async def chat(
        self,
        messages: list,
        temperature: float = 0.7,
        max_tokens: int = 500
    ) -> str:
        """发送聊天请求"""
        try:
            resp = await self.client.post(
                f"{self.base_url}/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={
                    "model": self.model,
                    "messages": messages,
                    "temperature": temperature,
                    "max_tokens": max_tokens
                }
            )
            resp.raise_for_status()
            return resp.json()["choices"][0]["message"]["content"]
        except Exception as e:
            logger.error(f"DeepSeek chat failed: {e}")
            raise


def get_shared_client() -> DeepSeekClient:
    return DeepSeekClient.get_client()


def close_shared_client():
    DeepSeekClient.close_shared_client()
