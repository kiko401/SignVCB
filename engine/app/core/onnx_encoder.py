"""ONNX 向量编码器"""
import numpy as np
from transformers import AutoTokenizer
import onnxruntime as ort
from pathlib import Path
from typing import List
import loguru

logger = loguru.logger


class ONNXEncoder:
    """BAAI/bge-small-zh-v1.5 ONNX 编码器（全局单例）"""

    _instance = None

    def __init__(self):
        self.session = None
        self.tokenizer = None

    @classmethod
    def get_instance(cls):
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def load(self, model_path: str, vocab_path: str = None):
        """加载 ONNX 模型和 tokenizer"""
        logger.info(f"Loading ONNX model from {model_path}")
        self.session = ort.InferenceSession(model_path)

        if vocab_path and Path(vocab_path).exists():
            self.tokenizer = AutoTokenizer.from_pretrained(
                str(Path(vocab_path).parent)
            )
        elif Path(model_path).parent.exists():
            try:
                self.tokenizer = AutoTokenizer.from_pretrained(
                    str(Path(model_path).parent)
                )
            except Exception as e:
                logger.warning(f"Tokenizer not loaded: {e}")

        logger.info("ONNX model loaded successfully")

    def encode(self, texts: List[str]) -> np.ndarray:
        """编码文本为向量（Mean Pooling + L2 归一化）"""
        if not self.session:
            raise RuntimeError("Model not loaded")

        if self.tokenizer:
            inputs = self.tokenizer(
                texts,
                padding=True,
                truncation=True,
                max_length=128,
                return_tensors="np"
            )
        else:
            max_len = 128
            input_ids = np.array([
                [ord(c) % 256 for c in (text[:max_len].ljust(max_len))]
                for text in texts
            ], dtype=np.int64)
            attention_mask = (input_ids != 0).astype(np.int64)
            inputs = {"input_ids": input_ids, "attention_mask": attention_mask}

        onnx_inputs = {
            "input_ids": inputs["input_ids"].astype(np.int64),
            "attention_mask": inputs["attention_mask"].astype(np.int64),
        }

        outputs = self.session.run(None, onnx_inputs)
        embeddings = outputs[0]

        mask = inputs["attention_mask"].astype(bool)
        sum_embeddings = np.sum(embeddings * mask[:, :, np.newaxis], axis=1)
        sum_mask = np.clip(np.sum(mask, axis=1, keepdims=True), a_min=1e-9, a_max=None)
        embeddings = sum_embeddings / sum_mask

        norms = np.linalg.norm(embeddings, axis=1, keepdims=True)
        embeddings = embeddings / (norms + 1e-9)

        return embeddings.astype(np.float32)

    def is_loaded(self) -> bool:
        return self.session is not None
