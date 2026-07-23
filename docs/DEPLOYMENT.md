# 部署指南 v3.4

本文档说明如何在云端服务器部署 SignVCB 应用。

## 服务器要求

- **配置**: 4C4G (最低)
- **系统**: Ubuntu 22.04 LTS
- **软件**:
  - Docker 20.10+
  - Docker Compose 2.0+
  - Nginx

## 部署架构

```
Internet
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│                     云端服务器 (4C4G)                        │
│                                                             │
│   Nginx (:80/443)                                          │
│       │                                                     │
│       ▼                                                     │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              Docker Network (signvcb-net)             │  │
│   │                                                     │  │
│   │   ┌─────────────┐  ┌─────────────┐                  │  │
│   │   │ signvcb-   │  │ signvcb-   │                  │  │
│   │   │ server     │──│ engine     │                  │  │
│   │   │ (:8000)    │  │ (:8001)    │                  │  │
│   │   └─────────────┘  └─────────────┘                  │  │
│   │         │                                                   │
│   │         ▼                                                   │
│   │   ┌─────────────┐  ┌─────────────┐                  │  │
│   │   │ signvcb-   │  │ signvcb-   │                  │  │
│   │   │ mysql      │  │ redis      │                  │  │
│   │   │ (:3306)    │  │ (:6379)    │                  │  │
│   │   └─────────────┘  └─────────────┘                  │  │
│   │                                                     │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐  │
│   │              Nginx (:8081) - 对外入口                │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## 部署步骤

### 1. 服务器环境准备

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装 Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# 安装 Docker Compose
sudo apt install docker-compose -y

# 安装 Nginx
sudo apt install nginx -y
```

### 2. 克隆代码

```bash
cd /opt
sudo git clone https://github.com/kiko401/SignVCB.git
cd SignVCB
```

### 3. 配置环境变量

```bash
cd /opt/SignVCB
sudo cp .env.example .env
sudo nano .env  # 编辑填入真实密钥
sudo chmod 600 .env
```

**必须配置的环境变量**:

```env
# ===== JWT 鉴权 =====
JWT_SECRET=<openssl rand -hex 32 生成>

# ===== MySQL =====
MYSQL_ROOT_PASSWORD=<强密码>
MYSQL_PASSWORD=<应用密码>
MYSQL_USER=signvcb
MYSQL_DATABASE=signvcb

# ===== 外部服务 API 密钥 =====
# DeepSeek LLM（算法引擎核心依赖）
DEEPSEEK_API_KEY=<DeepSeek API 密钥>
DEEPSEEK_BASE_URL=https://api.deepseek.com/v1
DEEPSEEK_MODEL=deepseek-v4-flash

# 腾讯云 TTS（语音合成）
TENCENT_TTS_SECRET_ID=<腾讯云 TTS 密钥 ID>
TENCENT_TTS_SECRET_KEY=<腾讯云 TTS 密钥 Key>

# 腾讯云 ASR（语音识别，当前代码中已定义但未实际调用，可暂时留空）
TENCENT_ASR_SECRET_ID=<腾讯云 ASR 密钥 ID>
TENCENT_ASR_SECRET_KEY=<腾讯云 ASR 密钥 Key>

# MiniMax（当前代码中已定义但未实际调用，可暂时留空）
MINIMAX_API_KEY=
MINIMAX_GROUP_ID=

# ===== 部署拓扑 =====
SERVER_PUBLIC_HOST=http://<公网IP>:8081
```

> **注意**：环境变量名必须与上面完全一致。部分变量（如 `TENCENT_ASR_*`、`MINIMAX_*`）虽在代码中已定义但尚未被实际调用，是为未来功能预留的，**可以留空但不能删除**，否则 docker-compose build 会失败。

### 4. 创建数据目录

```bash
sudo mkdir -p /data/tts_audio
sudo mkdir -p /data/logs
sudo chown -R 1000:1000 /data/tts_audio /data/logs
sudo chmod 755 /data/tts_audio /data/logs
```

### 5. 准备算法模型文件

引擎容器启动前，需要将 ONNX 模型及相关文件注入到 `engine_models` 数据卷中。

**所需文件清单**（所有文件缺一不可）：

| 源文件（宿主机） | 目标路径（容器内） | 说明 |
|---|---|---|
| `csl_encoder.onnx` | `/app/models/csl_encoder.onnx` | ONNX 编码器模型 |
| `vocab.json` | `/app/data/vocab.json` | **必须重命名**为 `vocab.json` |
| `tokenizer.json` | `/app/data/tokenizer.json` | HuggingFace tokenizer 配置（与 vocab.json 同目录） |
| `tokenizer_config.json` | `/app/data/tokenizer_config.json` | tokenizer 配置（与 vocab.json 同目录） |
| `special_tokens_map.json` | `/app/data/special_tokens_map.json` | 特殊词映射（与 vocab.json 同目录） |
| `faiss_index.bin` | `/app/data/faiss/faiss_index.bin` | FAISS 向量索引 |
| `initial_fallback.json` | `/app/data/fallback/initial_fallback.json` | 初始降级词典 |

> **Tokenizer 文件目录说明**：Engine 代码通过 `AutoTokenizer.from_pretrained(Path(vocab_path).parent)` 加载 tokenizer，即从 `/app/data/` 目录读取。因此 `tokenizer.json`、`tokenizer_config.json`、`special_tokens_map.json` 必须与 `vocab.json` 放在同一目录（`/app/data/`），**不是** `/app/models/`。

**注入步骤**：

```bash
cd /opt/SignVCB

# 创建临时容器（不启动）用于注入文件
docker compose -f deploy/docker-compose.yml create --no-start signvcb-engine

# 将模型文件复制到引擎容器的数据卷
# 1. ONNX 模型
docker cp ../Offline-Tools/outputs/csl_encoder.onnx signvcb-engine:/app/models/csl_encoder.onnx

# 2. 词汇表（必须重命名 csl_standard_vocab.json → vocab.json）
docker cp ../Offline-Tools/outputs/data/csl_standard_vocab.json signvcb-engine:/app/data/vocab.json

# 3. Tokenizer 文件（3个，必须与 vocab.json 同目录，即 /app/data/）
docker cp ../Offline-Tools/outputs/tokenizer.json signvcb-engine:/app/data/tokenizer.json
docker cp ../Offline-Tools/outputs/tokenizer_config.json signvcb-engine:/app/data/tokenizer_config.json
docker cp ../Offline-Tools/outputs/special_tokens_map.json signvcb-engine:/app/data/special_tokens_map.json

# 4. FAISS 索引
docker cp ../Offline-Tools/outputs/faiss/faiss_index.bin signvcb-engine:/app/data/faiss/faiss_index.bin

# 5. 初始降级词典
docker cp ../Offline-Tools/outputs/fallback/initial_fallback.json signvcb-engine:/app/data/fallback/initial_fallback.json

# 启动引擎容器（现在有模型文件了）
docker start signvcb-engine

# 验证模型加载成功
docker exec signvcb-engine curl -s http://localhost:8001/health
# 预期：{"status":"healthy","dependencies":{"onnx":"ok","faiss":"ok",...}}
```

> **如果缺少任何模型文件**：引擎启动后会处于 `degraded` 状态，ONNX/FAISS 相关功能不可用，但 rewrite 流程仍可降级到 LLM 直译模式。

### 6. 构建并启动所有容器

```bash
cd /opt/SignVCB/deploy

# 构建后端镜像
sudo docker compose build signvcb-server

# 构建算法引擎镜像
sudo docker compose build signvcb-engine

# 启动所有服务
sudo docker compose up -d

# 查看服务状态
sudo docker compose ps
```

**预期输出**:
```
NAME                STATUS          PORTS
signvcb-mysql      healthy        3306/tcp, 0.0.0.0:3308->3306/tcp
signvcb-redis      healthy        6379/tcp
signvcb-server     healthy        0.0.0.0:8012->8000/tcp, 0.0.0.0:8081->8000/tcp
signvcb-engine     healthy        8001/tcp, 0.0.0.0:8001->8001/tcp
```

> **注意**：容器首次启动时，后端容器会自动执行数据库迁移（`alembic upgrade head`）和种子数据初始化（读物、练习题），无需手动操作。

### 7. 配置 Nginx

```bash
# 复制 Nginx 配置
sudo cp /opt/SignVCB/deploy/nginx/signvcb.conf /etc/nginx/conf.d/

# 测试配置
sudo nginx -t

# 重载 Nginx
sudo systemctl reload nginx
```

### 8. 验证部署

```bash
# 后端健康检查（验证 MySQL、Redis、Engine 连接）
curl http://localhost:8081/health

# 预期响应
{
  "status": "healthy",
  "dependencies": {
    "mysql": "ok",
    "redis": "ok",
    "engine": "ok"
  }
}

# 引擎健康检查（验证 ONNX、FAISS 模型加载）
curl http://localhost:8001/health

# 预期响应
{
  "status": "healthy",
  "dependencies": {
    "onnx": "ok",
    "faiss": "ok",
    "llm": "ok",
    "rewrite_pipeline": "ok",
    "normalize_pipeline": "ok",
    "dynamic_dict": "ok|not_loaded"
  }
}

# 获取应用配置
curl http://localhost:8081/api/v1/app_config

# 预期响应
{
  "enable_stream_masking": true,
  "show_oov_map": true,
  "show_nmm_hints": true,
  "sse_timeout_ms": 10000
}
```

## Docker Compose 服务说明

| 服务 | 端口 | 说明 | 资源 |
|---|---|---|---|
| signvcb-mysql | 3308:3306 | MySQL 8.0 数据库 | 384MB RAM |
| signvcb-redis | 6379 | Redis 7 缓存 + PubSub | 64MB RAM |
| signvcb-server | 8012:8000, 8081:8000 | 后端 BFF 服务 | 384MB RAM |
| signvcb-engine | 8001:8001 | 算法引擎服务 | 1300MB RAM |

## 运维命令

```bash
# 查看日志
sudo docker compose logs -f signvcb-server
sudo docker compose logs -f signvcb-engine

# 重启服务
sudo docker compose restart signvcb-server
sudo docker compose restart signvcb-engine

# 更新代码后重build
sudo docker compose build signvcb-server
sudo docker compose up -d signvcb-server

# 停止服务
sudo docker compose down

# 完全清理（包括数据）
sudo docker compose down -v
```

## 数据备份

```bash
# 备份 MySQL 数据
sudo docker exec signvcb-mysql mysqldump -u root -p<password> signvcb > backup_$(date +%Y%m%d).sql

# 备份 Redis 数据
sudo docker exec signvcb-redis redis-cli SAVE
sudo docker cp signvcb-redis:/data/dump.rdb ./redis_backup.rdb
```

## 故障排查

### 服务无法启动

```bash
# 查看容器日志
sudo docker compose logs

# 检查端口占用
sudo netstat -tlnp | grep -E '3306|6379|8000|8001|8081'
```

### 数据库连接失败

```bash
# 检查 MySQL 健康状态
sudo docker compose ps signvcb-mysql

# 手动连接测试
sudo docker exec -it signvcb-mysql mysql -u signvcb -p
```

### 算法引擎响应超时

```bash
# 检查引擎日志
sudo docker compose logs signvcb-engine | tail -50

# 检查 ONNX 模型是否正确挂载
sudo docker exec signvcb-engine ls -la /app/models/
sudo docker exec signvcb-engine ls -la /app/data/
```

### 引擎处于 degraded 状态

```bash
# 查看具体哪些依赖异常
curl -s http://localhost:8001/health | python -m json.tool

# 如果 ONNX 异常：检查模型文件是否存在
sudo docker exec signvcb-engine test -f /app/models/csl_encoder.onnx && echo "ONNX OK" || echo "ONNX missing"

# 如果 FAISS 异常：检查索引文件是否存在
sudo docker exec signvcb-engine test -f /app/data/faiss/faiss_index.bin && echo "FAISS OK" || echo "FAISS missing"

# 如果 dynamic_dict 为 not_loaded：这是正常的（Redis 中无动态降级词），不影响核心功能
```

## 安全建议

1. **防火墙**: 只开放 80/443 端口 (HTTP/HTTPS)
2. **环境变量**: 确保 `.env` 文件权限为 600
3. **API 密钥**: 定期轮换外部服务密钥
4. **Nginx**: 生产环境建议配置 SSL/TLS 证书
