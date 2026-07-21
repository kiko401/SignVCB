# 默语共鸣 (SignVCB)

> 听障儿童无障碍沟通与学习应用

## 项目简介

默语共鸣是一款面向听障儿童的无障碍沟通与学习应用，通过手势语识别、自然语言处理和语音合成技术，帮助听障儿童实现无障碍沟通和学习。

## 技术架构

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App (前端)                      │
│              词卡动画 / 状态机 / 路由 / 本地存储               │
└─────────────────────────────────────────────────────────────┘
                              │ HTTP/SSE
                              ▼
┌─────────────────────────────────────────────────────────────┐
│              Nginx (:8081) - 反向代理与负载均衡               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│               FastAPI BFF (:8000) - 后端服务                  │
│         鉴权 / 限流 / SSE透传 / 业务落库 / 外部服务调用        │
└─────────────────────────────────────────────────────────────┘
                    │                           │
                    ▼                           ▼
         ┌──────────────────┐      ┌──────────────────────┐
         │  MySQL 8.0        │      │  Redis 7            │
         │  用户/读物/练习数据 │      │  会话/OOV队列/缓存   │
         └──────────────────┘      └──────────────────────┘
                    │
                    ▼
         ┌──────────────────────────────┐
         │   FastAPI Engine (:8001)      │
         │   ONNX推理 / FAISS检索 /       │
         │   DeepSeek LLM 调度           │
         └──────────────────────────────┘
```

## 技术栈

### 后端
- **框架**: FastAPI 0.115.0
- **数据库**: MySQL 8.0 + SQLAlchemy 2.0 (异步)
- **缓存**: Redis 7
- **认证**: JWT (python-jose)
- **限流**: SlowAPI
- **日志**: Loguru

### 算法引擎
- **框架**: FastAPI 0.115.0
- **向量编码**: ONNX Runtime (BAAI/bge-small-zh-v1.5)
- **向量检索**: FAISS
- **LLM**: DeepSeek API (deepseek-v4-flash)
- **中文分词**: Jieba

### 前端
- **框架**: Flutter 3.22+
- **状态管理**: Riverpod 2.5
- **路由**: GoRouter 14.0
- **网络**: Dio 5.4

## 目录结构

```
SignVCB/
├── backend/                  # 后端 BFF 服务
│   ├── app/
│   │   ├── api/            # API 路由层
│   │   ├── core/           # 核心配置
│   │   ├── models/         # ORM 模型
│   │   ├── schemas/        # Pydantic 模型
│   │   ├── services/       # 业务服务层
│   │   └── utils/         # 工具函数
│   ├── alembic/            # 数据库迁移
│   ├── tests/             # 测试
│   └── requirements.txt
│
├── engine/                  # 算法引擎服务
│   ├── app/
│   │   ├── api/           # 内部 API
│   │   ├── core/          # 核心配置
│   │   ├── modules/       # 算法模块
│   │   ├── pipelines/      # 处理流水线
│   │   ├── schemas/       # 数据契约
│   │   └── services/      # 外部服务
│   ├── scripts/            # 离线脚本
│   ├── tests/             # 测试
│   └── requirements.txt
│
├── deploy/                  # 部署配置
│   ├── docker-compose.yml  # Docker 编排
│   └── nginx/             # Nginx 配置
│
├── docs/                   # 文档
│   ├── api_contracts.md   # API 契约
│   └── data_contracts.md  # 数据契约
│
├── Offline-Tools/          # 离线预处理工具
│   └── outputs/           # ONNX/FAISS 产物
│
└── .env.example          # 环境变量模板
```

## 快速开始

### 前置依赖

- Python 3.11+
- Node.js 18+ (前端开发)
- Flutter 3.22+ (前端开发)
- Docker & Docker Compose

### 1. 克隆仓库

```bash
git clone https://github.com/kiko401/SignVCB.git
cd SignVCB
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 填入真实密钥
```

### 3. 启动基础设施 (MySQL + Redis)

```bash
cd deploy
docker compose up -d signvcb-mysql signvcb-redis
```

### 4. 后端开发

```bash
cd backend
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### 5. 算法引擎开发

```bash
cd engine
pip install -r requirements.txt
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

## 核心接口

| 接口 | 方法 | 说明 |
|---|---|---|
| `/api/v1/auth/register` | POST | 用户注册 |
| `/api/v1/auth/login` | POST | 用户登录 |
| `/api/v1/chat/rewrite` | POST | 文本改写 (SSE) |
| `/api/v1/chat/asr_and_rewrite` | POST | 语音改写 (SSE) |
| `/api/v1/chat/tts` | POST | 语音合成 |
| `/api/v1/reading/books` | GET | 获取书单 |
| `/api/v1/practice/question` | GET | 获取练习题 |
| `/api/v1/app_config` | GET | 获取应用配置 |

详细接口规范见 [docs/api_contracts.md](docs/api_contracts.md)

## 开发指南

### Git 工作流

```bash
# 从 dev 创建功能分支
git checkout dev
git checkout -b step/backend-<feature>

# 提交
git add .
git commit -m "feat(scope): description"

# 推送
git push origin step/backend-<feature>
```

### 分支规范

- `main` - 稳定发布分支
- `dev` - 开发集成分支
- `step/*` - 各组功能分支

## 相关文档

- [API 契约](docs/api_contracts.md)
- [数据契约](docs/data_contracts.md)
- [部署指南](docs/DEPLOYMENT.md)

## License

MIT
