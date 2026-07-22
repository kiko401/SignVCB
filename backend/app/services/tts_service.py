"""腾讯云 TTS 服务"""
import base64
import hashlib
import hmac
import json
import time
from pathlib import Path
import loguru
import httpx

logger = loguru.logger


class TencentTTSService:
    """腾讯云 TTS 服务"""

    def __init__(self, secret_id=None, secret_key=None):
        from app.core.config import get_settings
        s = get_settings()
        self.secret_id = secret_id or s.TENCENT_TTS_SECRET_ID
        self.secret_key = secret_key or s.TENCENT_TTS_SECRET_KEY

    async def synthesize_async(self, text: str, speed: float = 1.0, output_dir=None) -> str:
        from app.core.config import get_settings
        s = get_settings()
        output_dir = output_dir or s.TTS_AUDIO_DIR

        cache_key = f"{text}_{speed}"
        filename = f"{hashlib.md5(cache_key.encode()).hexdigest()}.wav"
        filepath = Path(output_dir) / filename
        filepath.parent.mkdir(parents=True, exist_ok=True)

        if filepath.exists():
            logger.debug(f"TTS cache hit: {filename}")
            return f"{s.SERVER_PUBLIC_HOST}/tts_audio/{filename}"

        try:
            # 腾讯云 TTS API
            host = "tts.tencentcloudapi.com"
            action = "TextToVoice"
            version = "2019-08-23"
            service = "tts"

            session_id = hashlib.md5(f"{text}_{speed}".encode()).hexdigest()
            payload = json.dumps({
                "Text": text[:500],
                "SessionId": session_id,
            })

            timestamp = int(time.time())
            date = time.strftime("%Y-%m-%d", time.gmtime(timestamp))
            algorithm = "TC3-HMAC-SHA256"

            http_request_method = "POST"
            canonical_uri = "/"
            canonical_query_string = ""
            canonical_headers = f"content-type:application/json\nhost:{host}\n"
            signed_headers = "content-type;host"
            hashed_request_payload = hashlib.sha256(payload.encode()).hexdigest()
            canonical_request = (
                f"{http_request_method}\n{canonical_uri}\n{canonical_query_string}\n"
                f"{canonical_headers}\n{signed_headers}\n{hashed_request_payload}"
            )
            credential_scope = f"{date}/{service}/tc3_request"
            hashed_canonical_request = hashlib.sha256(canonical_request.encode()).hexdigest()
            string_to_sign = f"{algorithm}\n{timestamp}\n{credential_scope}\n{hashed_canonical_request}"

            secret_date = hmac.new(f"TC3{self.secret_key}".encode(), date.encode(), hashlib.sha256).digest()
            secret_service = hmac.new(secret_date, service.encode(), hashlib.sha256).digest()
            secret_signing = hmac.new(secret_service, "tc3_request".encode(), hashlib.sha256).digest()
            signature = hmac.new(secret_signing, string_to_sign.encode(), hashlib.sha256).hexdigest()

            authorization = (
                f"{algorithm} Credential={self.secret_id}/{credential_scope}, "
                f"SignedHeaders={signed_headers}, Signature={signature}"
            )

            async with httpx.AsyncClient(timeout=httpx.Timeout(10.0, connect=2.0)) as client:
                resp = await client.post(
                    f"https://{host}",
                    headers={
                        "Authorization": authorization,
                        "Content-Type": "application/json",
                        "Host": host,
                        "X-TC-Action": action,
                        "X-TC-Timestamp": str(timestamp),
                        "X-TC-Version": version,
                        "X-TC-Region": "ap-guangzhou",
                    },
                    content=payload,
                )

            if resp.status_code == 200:
                data = resp.json()
                resp_data = data.get("Response", {})
                audio_base64 = resp_data.get("Audio")
                if audio_base64:
                    audio_bytes = base64.b64decode(audio_base64)
                    filepath.write_bytes(audio_bytes)
                    logger.info(f"TTS synthesized: {filename}, size={len(audio_bytes)}")
                else:
                    logger.error(f"TTS response missing Audio: {resp_data}")
            else:
                logger.error(f"TTS API error: {resp.status_code} {resp.text[:300]}")

        except Exception as e:
            logger.error(f"TTS failed: {e}")
            return f"{s.SERVER_PUBLIC_HOST}/tts_audio/{filename}"

        return f"{s.SERVER_PUBLIC_HOST}/tts_audio/{filename}"

    @classmethod
    def get_client(cls):
        return cls()


MiniMaxTTSService = TencentTTSService
