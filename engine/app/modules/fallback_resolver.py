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

    # FAISS 相似度最低阈值，低于此值不采用相似词结果
    _FAISS_MIN_SIMILARITY: float = 0.6

    def resolve(self, word: str) -> str:
        """解析 OOV 词的降级词（四级降级策略）"""
        # 第1级：初始降级词典（最高优先级）
        if word in self.initial_fallback:
            return self.initial_fallback[word]

        # 第2级：动态降级词典（Redis PubSub 实时更新，从全局服务读取）
        from app.services.dynamic_fallback_service import get_dynamic_fallback_service
        svc = get_dynamic_fallback_service()
        if svc:
            resolved = svc.get(word)
            if resolved:
                return resolved

        # 第3级：FAISS 向量近邻检索（需满足最低相似度阈值）
        similar = self.oov_detector.find_similar(word, top_k=1)
        if similar and similar[0][1] >= self._FAISS_MIN_SIMILARITY:
            return similar[0][0]

        # 第4级：基于词性的智能默认降级（兜底，不返回未处理的 OOV 词）
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
