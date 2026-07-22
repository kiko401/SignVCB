# SignVCB Algorithm Engine

CSL（中文手语）Rewrite 算法引擎，提供 OOV 检测、向量相似度匹配、LLM 精炼和逆向归一化能力。

## 架构

```
forward_rewrite.py     — CSL 正向Rewrite 流水线（OOV检测 → 降级 → LLM精炼 → 对齐）
reverse_normalize.py   — 逆向归一化流水线（NL → CSL）
```

### 核心模块

| 模块 | 职责 |
|------|------|
| `oov_detector.py` | jieba 分词 + FAISS 向量检索检测 OOV 词 |
| `fallback_resolver.py` | 多级降级：初始词典 → 动态词典 → FAISS 近邻 |
| `llm_refiner.py` | DeepSeek LLM 将 CSL 语序精炼为自然中文 |
| `alignment_generator.py` | 生成 CSL 对齐操作序列 |
| `nmm_generator.py` | 生成 NMBA 手型提示 |

### 服务层

| 服务 | 职责 |
|------|------|
| `redis_service.py` | Redis 连接、OOV 队列消费、PubSub 订阅 |
| `dynamic_fallback_service.py` | 动态降级词管理（增量同步 + 实时更新） |

## 依赖

- Python 3.11+
- ONNX Runtime、FAISS、jieba、loguru、httpx、redis
- DeepSeek API（LLM 精炼）

## 本地运行

```bash
cd engine
pip install -r requirements.txt

# 准备模型文件（从 Offline-Tools/outputs 复制）
mkdir -p data/faiss data/fallback
cp ../Offline-Tools/outputs/faiss/faiss_index.bin data/faiss/
cp ../Offline-Tools/outputs/fallback/initial_fallback.json data/fallback/
cp ../Offline-Tools/outputs/data/csl_standard_vocab.json data/vocab.json
cp ../Offline-Tools/outputs/onnx/csl_encoder.onnx models/

# 启动服务
uvicorn app.main:app --host 0.0.0.0 --port 8001
```

## Docker 运行

```bash
# 首次部署：注入模型文件到 Docker volumes
docker compose up -d signvcb-engine  # 先启动以创建 volumes

# 注入 ONNX 模型
docker cp Offline-Tools/outputs/onnx/csl_encoder.onnx signvcb-engine:/app/models/csl_encoder.onnx

# 注入 FAISS 索引
docker cp Offline-Tools/outputs/faiss/faiss_index.bin signvcb-engine:/app/data/faiss/faiss_index.bin

# 注入词表
docker cp Offline-Tools/outputs/data/csl_standard_vocab.json signvcb-engine:/app/data/vocab.json

# 注入初始降级词典
docker cp Offline-Tools/outputs/fallback/initial_fallback.json signvcb-engine:/app/data/fallback/initial_fallback.json

# 重启使模型生效
docker compose restart signvcb-engine

# 验证模型加载
docker compose exec signvcb-engine /app/scripts/init_data.sh
```

## 接口

### 健康检查

```bash
GET /health
```

返回 `{"status": "healthy|degraded", "dependencies": {"onnx", "faiss", "dynamic_dict"}}`

### 流式 Rewrite

```bash
POST /internal/rewrite
Content-Type: application/json

{"text": "我 吃 苹果", "context": ""}
```

SSE 事件流：`first_pass` → `refined_pass`，异常时 `error`

### 逆向归一化

```bash
POST /internal/normalize
Content-Type: application/json

{"text": "苹果 我 吃", "num_options": 3}
```

返回 `{"options": [...]}`

### 动态降级词典

```bash
GET /internal/dynamic_fallback
```

返回 `{"items": [{"oov": "...", "fallback": "..."}], "count": N}`

## 消融实验

```bash
python scripts/run_ablation.py
```

输出 5 种配置组合的对比结果，保存在 `data/ablation_results.json`。

## 关键配置

| 环境变量 | 默认值 | 说明 |
|----------|--------|------|
| `MODEL_PATH` | `/app/models/csl_encoder.onnx` | ONNX 编码器路径 |
| `FAISS_INDEX_PATH` | `/app/data/faiss/faiss_index.bin` | FAISS 索引路径 |
| `VOCAB_PATH` | `/app/data/vocab.json` | 词表路径 |
| `INITIAL_FALLBACK_PATH` | `/app/data/fallback/initial_fallback.json` | 初始降级词典 |
| `DYNAMIC_FALLBACK_SYNC_INTERVAL` | `600` | 定期同步间隔（秒） |
| `REDIS_HOST` | `signvcb-redis` | Redis 主机 |
| `BACKEND_HOST` | `signvcb-server` | 后端 BFF 主机 |
| `DEEPSEEK_API_KEY` | — | DeepSeek API 密钥 |
