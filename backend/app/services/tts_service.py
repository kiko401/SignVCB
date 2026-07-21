"""MiniMax TTS 服务"""
import httpx
import hashlib
import base64
from pathlib import Path
from typing import Optional
import loguru

logger = loguru.logger


class MiniMaxTTSService:
    """MiniMax TTS 服务"""

    BASE_URL = "https://api.minimax.chat/v1"
    _client: Optional[httpx.AsyncClient] = None

    def __init__(self, api_key: str = None, group_id: str = None):
        from app.core.config import get_settings
        settings = get_settings()

        self.api_key = api_key or settings.MINIMAX_API_KEY
        self.group_id = group_id or settings.MINIMAX_GROUP_ID

    def _get_httpx_client(self) -> httpx.AsyncClient:
        """懒加载共享 httpx 客户端"""
        if MiniMaxTTSService._client is None or MiniMaxTTSService._client.is_closed:
            MiniMaxTTSService._client = httpx.AsyncClient(
                timeout=httpx.Timeout(10.0, connect=2.0),
                limits=httpx.Limits(max_connections=5, max_keepalive_connections=2),
            )
        return MiniMaxTTSService._client

    async def synthesize_async(self, text: str, speed: float = 1.0, output_dir: str = None) -> str:
        """异步合成语音（真实调用 MiniMax TTS API）"""
        from app.core.config import get_settings
        settings = get_settings()
        output_dir = output_dir or settings.TTS_AUDIO_DIR

        # 缓存命中检查
        cache_key = f"{text}_{speed}"
        filename = f"{hashlib.md5(cache_key.encode()).hexdigest()}.mp3"
        filepath = Path(output_dir)
        filepath.mkdir(parents=True, exist_ok=True)
        filepath = filepath / filename

        if filepath.exists():
            logger.debug(f"TTS cache hit: {filename}")
            return f"{settings.SERVER_PUBLIC_HOST}/tts_audio/{filename}"

        # 真实调用 MiniMax TTS API
        try:
            client = self._get_httpx_client()
            resp = await client.post(
                f"{self.BASE_URL}?GroupId={self.group_id}",
                headers={"Authorization": f"Bearer {self.api_key}"},
                json={
                    "model": "speech-01-turbo",
                    "text": text,
                    "speed": speed,
                    "voice_setting": {"voice_id": "male-qn-qingse"},
                },
                timeout=10.0,
            )
            resp.raise_for_status()
            audio_data = base64.b64decode(resp.json()["data"]["audio"])
            filepath.write_bytes(audio_data)
            logger.info(f"TTS synthesized: {filename}, size={len(audio_data)}")
        except Exception as e:
            logger.error(f"TTS failed: {e}")
            # 降级：返回占位 URL
            return f"{settings.SERVER_PUBLIC_HOST}/tts_audio/{filename}"

        return f"{settings.SERVER_PUBLIC_HOST}/tts_audio/{filename}"
