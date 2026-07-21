"""聊天服务编排层"""
from typing import AsyncGenerator
from app.services.engine_client import EngineClient, EngineTimeoutError
from app.services.asr_service import ASRService
from app.services.tts_service import MiniMaxTTSService
from app.services.suggest_service import SuggestService
import loguru

logger = loguru.logger


class ChatService:
    """聊天服务编排"""

    @staticmethod
    async def stream_rewrite(
        text: str,
        context: str = None,
        request_id: str = ""
    ) -> AsyncGenerator[tuple[str, dict], None]:
        """流式 rewrite 编排"""
        engine = EngineClient.get_instance()

        try:
            async for event_name, event_data in engine.stream_rewrite(text, context, request_id):
                yield event_name, event_data
        except EngineTimeoutError:
            yield "fallback", {"fallback_text": "网络有点慢哦，再试一次？"}
        finally:
            await engine.close()

    @staticmethod
    async def asr_and_stream_rewrite(
        audio_data: bytes,
        context: str = None,
        request_id: str = ""
    ) -> AsyncGenerator[tuple[str, dict], None]:
        """ASR + rewrite 编排"""
        yield "preheat", {"original": ""}

        asr_service = ASRService()
        text = asr_service.recognize(audio_data)

        yield "preheat", {"original": text}

        async for event in ChatService.stream_rewrite(text, context, request_id):
            yield event

    @staticmethod
    async def tts(text: str, speed: float = 1.0) -> str:
        """TTS 合成"""
        tts_service = MiniMaxTTSService.get_client()
        return await tts_service.synthesize_async(text, speed)

    @staticmethod
    async def suggest_reply(text: str) -> list[dict]:
        """生成建议回复"""
        suggest_service = SuggestService.get_client()
        try:
            return await suggest_service.generate_suggestions(text)
        finally:
            await suggest_service.close()

    @staticmethod
    async def normalize_options(text: str, num: int = 3) -> list[str]:
        """逆向归一化"""
        engine = EngineClient.get_instance()
        try:
            return await engine.normalize(text, num)
        finally:
            await engine.close()
