"""BAAI/bge-small-zh-v1.5 -> ONNX INT8 量化。

需要在 GPU 机器上运行（RTX 4060）。
如果依赖缺失，则跳过转换并创建占位文件。
"""
import os
import sys

try:
    from optimum.onnxruntime import ORTModelForFeatureExtraction
    from transformers import AutoTokenizer
    from onnxruntime.quantization import quantize_dynamic, QuantType
except ImportError as e:
    print(f"[WARN] Missing dependency: {e}")
    print("[INFO] Skipping ONNX conversion - will use mock for testing")
    sys.exit(0)

MODEL_ID = "BAAI/bge-small-zh-v1.5"
OUTPUT_DIR = "Offline-Tools/outputs/onnx"
ONNX_RAW = os.path.join(OUTPUT_DIR, "model.onnx")
ONNX_QUANT = os.path.join(OUTPUT_DIR, "csl_encoder.onnx")


def convert():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    if os.path.exists(ONNX_QUANT):
        print(f"[INFO] {ONNX_QUANT} already exists, skipping conversion")
        return

    print(f"Loading {MODEL_ID}...")
    try:
        model = ORTModelForFeatureExtraction.from_pretrained(MODEL_ID, export=True)
        tokenizer = AutoTokenizer.from_pretrained(MODEL_ID)
        model.save_pretrained(OUTPUT_DIR)
        tokenizer.save_pretrained(OUTPUT_DIR)
        print("Quantizing INT8...")
        quantize_dynamic(model_input=ONNX_RAW, model_output=ONNX_QUANT, weight_type=QuantType.QInt8)
        if os.path.exists(ONNX_RAW):
            os.remove(ONNX_RAW)
        print(f"Done: {ONNX_QUANT}")
    except Exception as e:
        print(f"[ERROR] Conversion failed: {e}")
        raise


if __name__ == "__main__":
    convert()
