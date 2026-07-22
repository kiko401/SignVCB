"""OOV 降级解析模块"""
from typing import Dict
import loguru

logger = loguru.logger

# 词性 → 默认降级词映射（基于 jieba.posseg）
POS_DEFAULT_FALLBACK = {
    "nr":  "某人",   # 人名
    "ns":  "某地",   # 地名
    "nt":  "某组织", # 团体名
    "nz":  "这个",   # 其他专有名词
    "v":   "做",     # 动词
    "a":   "这样的", # 形容词
    "d":   "这样地", # 副词
}


class FallbackResolver:
    """OOV 词多级降级解析器"""

    def __init__(self, oov_detector, initial_fallback: Dict[str, str] = None):
        self.oov_detector = oov_detector
        self.initial_fallback = initial_fallback or {}
        self.dynamic_fallback = {}

    def resolve(self, word: str) -> str:
        """解析 OOV 词的降级词（四级降级策略）"""
        # 第1级：初始降级词典
        if word in self.initial_fallback:
            return self.initial_fallback[word]

        # 第2级：动态降级词典（Redis PubSub 实时更新）
        if word in self.dynamic_fallback:
            return self.dynamic_fallback[word]

        # 第3级：FAISS 向量近邻检索
        similar = self.oov_detector.find_similar(word, top_k=1)
        if similar:
            return similar[0][0]

        # 第4级：基于词性的智能默认降级
        return self._get_pos_based_fallback(word)

    def _get_pos_based_fallback(self, word: str) -> str:
        """基于 jieba 词性标注的默认降级"""
        try:
            import jieba.posseg as pseg
            words = list(pseg.cut(word))
            if words:
                pos = words[0].flag
                if pos in POS_DEFAULT_FALLBACK:
                    return POS_DEFAULT_FALLBACK[pos]
        except Exception:
            pass
        return "这个"

    def build_oov_map(self, oov_words: list) -> Dict[str, str]:
        """构建 OOV 降级映射"""
        return {word: self.resolve(word) for word in oov_words}

    def update_dynamic_fallback(self, oov_word: str, fallback_word: str):
        """更新动态降级词典"""
        self.dynamic_fallback[oov_word] = fallback_word
        logger.info(f"Updated dynamic fallback: {oov_word} -> {fallback_word}")
