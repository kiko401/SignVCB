"""建议回复服务（DeepSeek）"""
import httpx
from typing import Optional
import loguru

logger = loguru.logger


class SuggestService:
    """DeepSeek 建议回复服务（懒加载单例）"""

    _instance: Optional["SuggestService"] = None
    _client: Optional[httpx.AsyncClient] = None

    def __init__(self, api_key: str = None, model: str = None):
        from app.core.config import get_settings
        settings = get_settings()

        self.api_key = api_key or settings.DEEPSEEK_API_KEY
        self.model = model or settings.DEEPSEEK_MODEL
        self.base_url = settings.DEEPSEEK_BASE_URL

    @classmethod
    def get_client(cls) -> "SuggestService":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    @classmethod
    async def close(cls):
        """关闭共享客户端"""
        if cls._client is not None and not cls._client.is_closed:
            await cls._client.aclose()
            cls._client = None
            cls._instance = None

    def _get_httpx_client(self) -> httpx.AsyncClient:
        """懒加载共享 httpx 客户端"""
        if SuggestService._client is None or SuggestService._client.is_closed:
            SuggestService._client = httpx.AsyncClient(
                timeout=httpx.Timeout(30.0),
                limits=httpx.Limits(max_connections=5, max_keepalive_connections=2),
            )
        return SuggestService._client

    async def generate_suggestions(self, text: str, context: str = None, num: int = 3) -> list[dict]:
        """生成建议回复"""
        if not self.api_key:
            logger.warning("DEEPSEEK_API_KEY not configured, returning empty suggestions")
            return []

        ctx_info = f"\n对话上下文：{context}" if context else ""
        prompt = f"""你是一个辅助听障人士沟通的助手。用户表达了以下意思，请生成 {num} 个简短的自然中文回复建议，方便听障人士选择回复。

要求：
1. 每个回复不超过15个字
2. 回复要自然、口语化
3. 适合日常对话场景
4. 只返回回复内容，每行一个，不要编号

用户表达：{text}{ctx_info}

建议回复："""

        try:
            client = self._get_httpx_client()
            resp = await client.post(
                f"{self.base_url}/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={
                    "model": self.model,
                    "messages": [{"role": "user", "content": prompt}]
                }
            )
            content = resp.json()["choices"][0]["message"]["content"]
            suggestions = [
                {"text": line.strip(), "reason": ""}
                for line in content.split("\n")
                if line.strip() and not line.strip().startswith(("1", "2", "3", "-", "*", "·"))
            ]
            return suggestions[:num]
        except Exception as e:
            logger.error(f"SuggestService failed: {e}")
            return []
