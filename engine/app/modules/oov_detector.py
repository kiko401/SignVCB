"""OOV 检测模块"""
import jieba
import numpy as np
import faiss
import json
from typing import List, Tuple
from pathlib import Path
import loguru

logger = loguru.logger


class OOVDetector:
    """Out-of-Vocabulary 词检测器"""

    def __init__(self):
        self.encoder = None
        self.index = None
        self.vocab = []
        self.vocab_set = set()
        self.fallback_dict = {}

    def load(self, index_path: str, vocab_path: str, fallback_path: str = None):
        """加载 FAISS 索引和词表"""
        from app.core.config import get_settings
        from app.core.onnx_encoder import ONNXEncoder

        settings = get_settings()
        self.encoder = ONNXEncoder.get_instance()
        onnx_path = settings.MODEL_PATH
        if Path(onnx_path).exists():
            self.encoder.load(onnx_path, vocab_path)
        else:
            logger.warning(f"ONNX model not found at {onnx_path}, OOV detection will use fallback only")

        logger.info(f"Loading FAISS index from {index_path}")
        self.index = faiss.read_index(index_path)

        with open(vocab_path, encoding="utf-8") as f:
            self.vocab = json.load(f)
        self.vocab_set = set(self.vocab)

        if fallback_path and Path(fallback_path).exists():
            with open(fallback_path, encoding="utf-8") as f:
                self.fallback_dict = json.load(f)

        logger.info(f"OOVDetector loaded: {len(self.vocab)} words, {len(self.fallback_dict)} fallback entries")

    def detect(self, text: str) -> Tuple[str, bool, List[str]]:
        """检测 OOV 词"""
        words = list(jieba.cut(text))
        words = [w.strip() for w in words if w.strip()]

        oov_words = []
        for w in words:
            if w not in self.vocab_set:
                oov_words.append(w)

        oov_status = len(oov_words) > 0
        first_pass_text = " ".join(words)

        return first_pass_text, oov_status, oov_words

    def get_fallback(self, word: str) -> str:
        """获取 OOV 词的降级词"""
        return self.fallback_dict.get(word, "东西")

    def find_similar(self, word: str, top_k: int = 5) -> List[Tuple[str, float]]:
        """找到最相似的词"""
        if not self.encoder or not self.encoder.is_loaded() or not self.index:
            return []

        try:
            emb = self.encoder.encode([word])
            distances, indices = self.index.search(emb, top_k + 1)

            results = []
            for d, i in zip(distances[0], indices[0]):
                if 0 <= i < len(self.vocab) and self.vocab[i] != word:
                    similarity = 1 / (1 + d)
                    results.append((self.vocab[i], similarity))

            return results[:top_k]
        except Exception as e:
            logger.warning(f"find_similar failed: {e}")
            return []
