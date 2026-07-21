"""MiniMax TTS 服务"""
import httpx
import uuid
from pathlib import Path
import loguru

logger = loguru.logger


class MiniMaxTTSService:
    """MiniMax TTS 服务"""

    BASE_URL = "https://api.minimax.chat/v1"

    def __init__(self, api_key: str = None, group_id: str = None):
        from app.core.config import get_settings
        settings = get_settings()

        self.api_key = api_key or settings.MINIMAX_API_KEY
        self.group_id = group_id or settings.MINIMAX_GROUP_ID

    @classmethod
    def get_client(cls):
        return cls()

    def synthesize(self, text: str, speed: float = 1.0, output_dir: str = None) -> str:
        """同步合成语音"""
        from app.core.config import get_settings
        settings = get_settings()
        output_dir = output_dir or settings.TTS_AUDIO_DIR

        filename = f"{uuid.uuid4().hex}.mp3"
        filepath = Path(output_dir)
        filepath.mkdir(parents=True, exist_ok=True)
        filepath = filepath / filename

        # TODO: 调用 MiniMax API
        filepath.write_bytes(b"")

        public_url = f"{settings.SERVER_PUBLIC_HOST}/tts_audio/{filename}"
        return public_url

    async def synthesize_async(self, text: str, speed: float = 1.0, output_dir: str = None) -> str:
        """异步合成语音"""
        return self.synthesize(text, speed, output_dir)
