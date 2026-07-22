"""正向 Rewrite 流水线"""
import jieba
from typing import AsyncGenerator, Tuple
import json
import loguru

from app.modules.oov_detector import OOVDetector
from app.modules.fallback_resolver import FallbackResolver
from app.modules.llm_refiner import LLMRefiner
from app.modules.alignment_generator import AlignmentGenerator
from app.modules.nmm_generator import NMMGenerator
from app.core.llm_client import get_shared_client
from app.schemas.rewrite import RefinedPassData
from app.utils.sse import format_sse_event

logger = loguru.logger


class ForwardRewritePipeline:
    """CSL Rewrite 流水线"""

    def __init__(self):
        self.oov_detector = OOVDetector()
        self.fallback_resolver = None
        self.llm_refiner = None
        self.alignment_generator = AlignmentGenerator()
        self.nmm_generator = NMMGenerator()
        self._initialized = False
        self._redis_service = None

    def initialize(self, index_path: str, vocab_path: str, fallback_path: str, redis_service=None):
        """初始化流水线组件"""
        try:
            self.oov_detector.load(index_path, vocab_path, fallback_path)
        except Exception as e:
            logger.warning(f"OOV detector load failed: {e}, running in degraded mode")

        initial_fallback = {}
        try:
            with open(fallback_path, encoding="utf-8") as f:
                initial_fallback = json.load(f)
        except Exception:
            pass

        self.fallback_resolver = FallbackResolver(self.oov_detector, initial_fallback)
        self.llm_refiner = LLMRefiner(get_shared_client())
        self._redis_service = redis_service
        self._initialized = True
        logger.info("ForwardRewritePipeline initialized")

    async def rewrite(self, text: str, context: str = None) -> AsyncGenerator[Tuple[str, dict], None]:
        """执行 rewrite 流水线"""
        if not self._initialized:
            yield "error", {"message": "Pipeline not initialized"}
            return

        yield "preheat", {"original": text}

        first_pass_text, oov_status, oov_words = self.oov_detector.detect(text)

        yield "first_pass", {"text": first_pass_text, "oov_status": oov_status}

        if not oov_status:
            refined_text = first_pass_text
            oov_map = {}
        else:
            oov_map = self.fallback_resolver.build_oov_map(oov_words)

            refined_text = first_pass_text
            for oov_word, fallback_word in oov_map.items():
                refined_text = refined_text.replace(oov_word, fallback_word)

        nmm_hints = self.nmm_generator.generate(refined_text)

        if oov_status or context:
            try:
                refined_text = await self.llm_refiner.refine(first_pass_text, oov_map)
            except Exception as e:
                logger.warning(f"LLM refine failed, using first_pass: {e}")
                refined_text = first_pass_text

        alignment_ops = self.alignment_generator.generate(first_pass_text, refined_text)

        refined_data = RefinedPassData(
            text=refined_text,
            oov_map=oov_map,
            nmm_hints=nmm_hints,
            alignment_ops=[op.model_dump() for op in alignment_ops]
        )

        yield "refined_pass", refined_data.model_dump()

        if oov_status and self._redis_service:
            try:
                for oov_word, fallback_word in oov_map.items():
                    await self._redis_service.lpush("queue:oov_fallback", json.dumps({
                        "oov_word": oov_word,
                        "fallback_word": fallback_word
                    }))
            except Exception as e:
                logger.warning(f"Failed to push OOV to queue: {e}")


forward_rewrite_pipeline = ForwardRewritePipeline()
