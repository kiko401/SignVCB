# SignVCB 后端 BFF

FastAPI 后端服务，提供用户认证、CSL Rewrite、语音合成、练习等业务接口。

## 技术栈

FastAPI + SQLAlchemy [asyncio] + MySQL + Redis + httpx

## 本地开发

### 1. 安装依赖

```bash
cd backend
pip install -r requirements.txt
```

### 2. 配置环境变量

```bash
cp ../.env.example .env
# 编辑 .env 填入真实密钥
```

### 3. 启动基础设施（Docker）

```bash
cd ../deploy
docker compose up -d signvcb-mysql signvcb-redis
```

### 4. 运行数据库迁移

```bash
cd ../backend
alembic upgrade head
```

### 5. 初始化种子数据

```bash
# 方式一：使用独立脚本（推荐，容器内也用这个）
python -m app.scripts.seed_local

# 方式二：使用 Offline-Tools
cd ../Offline-Tools
python seed_db.py
```

### 6. 启动后端

```bash
cd ../backend
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 7. 验证

```bash
curl http://localhost:8000/health
```

## Docker 部署

```bash
cd deploy
docker compose up -d signvcb-server
```

容器启动时自动执行：
1. 等待 MySQL 就绪
2. 运行 `alembic upgrade head`（数据库迁移）
3. 运行 `python -m app.scripts.seed_local`（种子数据）
4. 启动 uvicorn

## 目录结构

```
backend/
├── app/
│   ├── api/          # API 路由（v1 + internal）
│   ├── core/         # 配置、数据库、安全、中间件
│   ├── models/       # SQLAlchemy ORM 模型
│   ├── schemas/      # Pydantic 请求/响应模型
│   ├── scripts/      # 工具脚本（seed_local.py）
│   ├── services/     # 业务逻辑服务
│   └── main.py       # FastAPI 入口 + lifespan
├── alembic/          # 数据库迁移
├── tests/            # 冒烟测试
├── Dockerfile
└── requirements.txt
```

## 核心接口

| 接口 | 方法 | 说明 |
|------|------|------|
| `/health` | GET | 健康检查（含 MySQL/Redis/Engine 依赖状态） |
| `/api/v1/auth/register` | POST | 用户注册 |
| `/api/v1/auth/login` | POST | 用户登录 |
| `/api/v1/app_config` | GET | 应用配置（匿名） |
| `/api/v1/rewrite` | POST | CSL 文本改写（SSE 流） |
| `/api/v1/asr_and_rewrite` | POST | ASR + 改写（SSE 流） |
| `/api/v1/tts` | POST | 语音合成 |
| `/api/v1/suggest` | POST | 建议回复 |
| `/api/v1/normalize` | POST | 逆向归一化 |
| `/api/v1/reading/books` | GET | 获取书单 |
| `/api/v1/reading/content` | GET | 获取读物内容 |
| `/api/v1/practice/question` | GET | 获取练习题 |
| `/api/v1/practice/validate` | POST | 验证答案 |
| `/api/v1/log_mismatch` | POST | 记录意图不匹配 |

详细接口规范见 `docs/api_contracts.md`
