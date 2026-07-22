#!/bin/bash
# engine/scripts/init_data.sh
# 检查数据文件是否正确挂载，打印状态供调试

echo "=== Engine Data Status ==="
echo "Models directory:"
ls -la /app/models/ 2>/dev/null || echo "  (empty or not mounted)"

echo "FAISS index:"
ls -la /app/data/faiss/ 2>/dev/null || echo "  (empty or not mounted)"

echo "Vocabulary:"
ls -la /app/data/ 2>/dev/null || echo "  (not mounted)"

echo "Fallback dict:"
ls -la /app/data/fallback/ 2>/dev/null || echo "  (empty or not mounted)"

echo ""
echo "=== Engine Readiness ==="
# 检查关键文件是否存在
if [ -f /app/models/csl_encoder.onnx ]; then
    echo "ONNX model: OK"
else
    echo "ONNX model: NOT FOUND (graceful degradation mode)"
fi

if [ -f /app/data/faiss/faiss_index.bin ]; then
    echo "FAISS index: OK"
else
    echo "FAISS index: NOT FOUND (graceful degradation mode)"
fi

if [ -f /app/data/fallback/initial_fallback.json ]; then
    echo "Fallback dict: OK ($(cat /app/data/fallback/initial_fallback.json | python3 -c 'import sys,json; print(len(json.load(sys.stdin)), \"entries\")' 2>/dev/null || echo "parse error"))"
else
    echo "Fallback dict: NOT FOUND"
fi

echo "=== Done ==="
