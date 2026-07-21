#!/bin/bash
# backend/tests/smoke_e2e.sh
# 必须在后端、算法、MySQL、Redis 全部启动后运行

set -e
BASE="${SERVER_URL:-http://localhost:8012}"

echo "=== 后端 E2E 冒烟测试 ==="

echo "[1/13] GET /health"
curl -fsS "$BASE/health" | python -m json.tool
echo ""

echo "[2/13] GET /api/v1/app_config (匿名)"
curl -fsS "$BASE/api/v1/app_config" | python -m json.tool
echo ""

echo "[3/13] POST /api/v1/auth/register"
RESP=$(curl -fsS -X POST "$BASE/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"smoke_test","password":"smoke123","age_group":"L1","nickname":"smoke"}')
echo "$RESP" | python -m json.tool
TOKEN=$(echo "$RESP" | python -c "import sys,json; print(json.load(sys.stdin)['access_token'])")
echo "TOKEN obtained: ${TOKEN:0:20}..."

echo "[4/13] POST /api/v1/auth/login"
curl -fsS -X POST "$BASE/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"smoke_test","password":"smoke123"}' | python -m json.tool
echo ""

echo "[5/13] POST /api/v1/tts"
TTS_RESP=$(curl -fsS -X POST "$BASE/api/v1/tts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"你好","speed":1.0}')
echo "$TTS_RESP" | python -m json.tool
# 验证 audio_url 存在且包含 /tts_audio/
if echo "$TTS_RESP" | grep -q "tts_audio"; then echo "TTS audio_url OK"; fi
echo ""

echo "[6/13] POST /api/v1/rewrite (SSE)"
echo "  期望：preheat → first_pass → refined_pass"
curl -fsS -X POST "$BASE/api/v1/rewrite" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"text":"我吃苹果"}' --no-buffer | head -20
echo ""

echo "[7/13] POST /api/v1/suggest"
curl -fsS -X POST "$BASE/api/v1/suggest" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"我要吃苹果","context":"无"}' | python -m json.tool
echo ""

echo "[8/13] POST /api/v1/normalize"
curl -fsS -X POST "$BASE/api/v1/normalize" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"text":"苹果 我 吃","num_options":3}' | python -m json.tool
echo ""

echo "[9/13] POST /api/v1/log_mismatch"
curl -fsS -X POST "$BASE/api/v1/log_mismatch" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"original_text":"苹果","failed_options":["水果"],"context":"无"}' | python -m json.tool
echo ""

echo "[10/13] GET /api/v1/reading/books"
curl -fsS "$BASE/api/v1/reading/books" \
  -H "Authorization: Bearer $TOKEN" | python -m json.tool
echo ""

echo "[11/13] GET /api/v1/reading/content?book_id=1"
curl -fsS "$BASE/api/v1/reading/content?book_id=1" \
  -H "Authorization: Bearer $TOKEN" | python -m json.tool
echo ""

echo "[12/13] GET /api/v1/practice/question?level=L1&type=word_match"
curl -fsS "$BASE/api/v1/practice/question?level=L1&type=word_match" \
  -H "Authorization: Bearer $TOKEN" | python -m json.tool
echo ""

echo "[13/13] POST /api/v1/practice/validate"
curl -fsS -X POST "$BASE/api/v1/practice/validate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"question_id":1,"answer":["苹果"]}' | python -m json.tool
echo ""

echo "[14/14] 401 拦截验证"
HTTP_CODE=$(curl -fsS -o /dev/null -w "%{http_code}" "$BASE/api/v1/reading/books")
echo "无 token 时返回 HTTP $HTTP_CODE (期望 401)"
echo ""

echo "[15/15] 匿名访问 app_config"
HTTP_CODE=$(curl -fsS -o /dev/null -w "%{http_code}" "$BASE/api/v1/app_config")
echo "匿名访问返回 HTTP $HTTP_CODE (期望 200)"

echo ""
echo "=== 全部测试完成 ==="
