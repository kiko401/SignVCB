"""标准词表向量化 + FAISS IndexFlatL2 索引构建。

如果 ONNX 模型不存在，则创建 mock FAISS 索引用于测试。
"""
import json
import os
import sys
from pathlib import Path

import numpy as np

VOCAB = "Offline-Tools/outputs/data/csl_standard_vocab.json"
ONNX = "Offline-Tools/outputs/onnx/csl_encoder.onnx"
FAISS_OUT = "Offline-Tools/outputs/faiss/faiss_index.bin"


def build():
    if not Path(VOCAB).exists():
        print(f"[WARN] {VOCAB} not found, running clean_vocab first...")
        import clean_vocab
        clean_vocab.clean()

    words = json.loads(open(VOCAB, encoding="utf-8").read())
    print(f"Loaded {len(words)} words")

    if not Path(ONNX).exists():
        print(f"[WARN] {ONNX} not found, creating mock FAISS index for testing")
        dim = 512
        os.makedirs(os.path.dirname(FAISS_OUT), exist_ok=True)
        import faiss
        index = faiss.IndexFlatL2(dim)
        dummy_data = np.random.random((len(words), dim)).astype(np.float32)
        index.add(dummy_data)
        faiss.write_index(index, FAISS_OUT)
        print(f"Created mock FAISS index: {FAISS_OUT}, ntotal={index.ntotal}")
        return

    try:
        import faiss
        sys.path.insert(0, "engine")
        from app.core.onnx_encoder import ONNXEncoder

        encoder = ONNXEncoder()
        encoder.load(ONNX)
        embeddings = []
        for i in range(0, len(words), 32):
            batch = words[i:i+32]
            embs = encoder.encode(batch)
            embeddings.append(embs)
            print(f"Encoded {i+len(batch)}/{len(words)}")
        embeddings = np.vstack(embeddings).astype(np.float32)
        print(f"Shape: {embeddings.shape}")
        dim = embeddings.shape[1]
        index = faiss.IndexFlatL2(dim)
        index.add(embeddings)
        os.makedirs(os.path.dirname(FAISS_OUT), exist_ok=True)
        faiss.write_index(index, FAISS_OUT)
        print(f"Done: {FAISS_OUT}, ntotal={index.ntotal}")
    except Exception as e:
        print(f"[WARN] ONNX encoding failed: {e}, creating mock index")
        import faiss
        dim = 512
        os.makedirs(os.path.dirname(FAISS_OUT), exist_ok=True)
        index = faiss.IndexFlatL2(dim)
        dummy_data = np.random.random((len(words), dim)).astype(np.float32)
        index.add(dummy_data)
        faiss.write_index(index, FAISS_OUT)
        print(f"Created mock FAISS index: {FAISS_OUT}")


if __name__ == "__main__":
    build()
