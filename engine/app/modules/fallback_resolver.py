"""OOV 降级解析模块"""
from typing import Dict
import loguru

logger = loguru.logger


class FallbackResolver:
    """OOV 词降级解析"""

    def __init__(self, oov_detector, initial_fallback: Dict[str, str] = None):
        self.oov_detector = oov_detector
        self.initial_fallback = initial_fallback or {}
        self.dynamic_fallback = {}

    def resolve(self, word: str) -> str:
        """解析 OOV 词的降级词"""
        if word in self.initial_fallback:
            return self.initial_fallback[word]

        if word in self.dynamic_fallback:
            return self.dynamic_fallback[word]

        similar = self.oov_detector.find_similar(word, top_k=1)
        if similar:
            return similar[0][0]

        return "东西"

    def build_oov_map(self, oov_words: list) -> Dict[str, str]:
        """构建 OOV 降级映射"""
        oov_map = {}
        for word in oov_words:
            oov_map[word] = self.resolve(word)
        return oov_map

    def update_dynamic_fallback(self, oov_word: str, fallback_word: str):
        """更新动态降级词典"""
        self.dynamic_fallback[oov_word] = fallback_word
        logger.info(f"Updated dynamic fallback: {oov_word} -> {fallback_word}")
