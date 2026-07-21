"""建议回复服务（DeepSeek）"""
import httpx
import loguru

logger = loguru.logger


class SuggestService:
    """DeepSeek 建议回复服务"""

    BASE_URL = "https://api.deepseek.com/v1"

    def __init__(self, api_key: str = None, model: str = None):
        from app.core.config import get_settings
        settings = get_settings()

        self.api_key = api_key or settings.DEEPSEEK_API_KEY
        self.model = model or settings.DEEPSEEK_MODEL
        self.client = httpx.AsyncClient(timeout=30.0)

    @classmethod
    def get_client(cls):
        return cls()

    async def generate_suggestions(self, text: str, num: int = 3) -> list[dict]:
        """生成建议回复"""
        prompt = f"用户说了：{text}\n请生成 {num} 个合适的回复建议，每个建议要简短自然。"

        try:
            resp = await self.client.post(
                f"{self.BASE_URL}/chat/completions",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={
                    "model": self.model,
                    "messages": [{"role": "user", "content": prompt}]
                }
            )
            content = resp.json()["choices"][0]["message"]["content"]
            return [{"text": line.strip(), "reason": ""}
                    for line in content.split("\n") if line.strip()]
        except Exception as e:
            logger.error(f"SuggestService failed: {e}")
            return []

    async def close(self):
        await self.client.aclose()
