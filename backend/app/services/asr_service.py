"""腾讯 ASR 服务"""
import asyncio
from tencentcloud.common import credential
from tencentcloud.asr.v20190614 import asr_client, models
import base64
import loguru

logger = loguru.logger


class ASRService:
    """腾讯云 ASR 服务"""

    def __init__(self, secret_id: str = None, secret_key: str = None):
        from app.core.config import get_settings
        settings = get_settings()

        secret_id = secret_id or settings.TENCENT_ASR_SECRET_ID
        secret_key = secret_key or settings.TENCENT_ASR_SECRET_KEY

        cred = credential.Credential(secret_id, secret_key)
        self.client = asr_client.AsrClient(cred, "ap-shanghai")

    def _sync_recognize(self, audio_data: bytes) -> str:
        """同步识别（在线程池中执行）"""
        req = models.SimpleRecognizeRequest()
        req.Channel = 1
        req.SampleRate = 16000
        req.ServiceType = "16k_zh"
        req.FileContent = base64.b64encode(audio_data).decode()
        resp = self.client.SimpleRecognize(req)
        return resp.Result or ""

    async def recognize(self, audio_data: bytes) -> str:
        """异步识别，内部用 asyncio.to_thread 包装同步调用"""
        try:
            return await asyncio.to_thread(self._sync_recognize, audio_data)
        except Exception as e:
            logger.error(f"ASR failed: {e}")
            raise
