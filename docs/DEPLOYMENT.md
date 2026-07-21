# 部署指南 v3.3

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
cd SignVCB
sudo cp .env.example .env
sudo nano .env  # 编辑填入真实密钥
sudo chmod 600 .env
```

**必须配置的环境变量**:

```env
# JWT 鉴权
JWT_SECRET=<openssl rand -hex 32 生成>

# MySQL
MYSQL_ROOT_PASSWORD=<强密码>
MYSQL_PASSWORD=<应用密码>
MYSQL_USER=signvcb
MYSQL_DATABASE=signvcb

# 外部服务 API 密钥
TENCENT_ASR_SECRET_ID=<腾讯云 ASR 密钥 ID>
TENCENT_ASR_SECRET_KEY=<腾讯云 ASR 密钥 Key>
MINIMAX_API_KEY=<MiniMax API 密钥>
MINIMAX_GROUP_ID=<MiniMax Group ID>
DEEPSEEK_API_KEY=<DeepSeek API 密钥>

# 部署拓扑
SERVER_PUBLIC_HOST=http://<公网IP>:8081
```

### 4. 创建数据目录

```bash
sudo mkdir -p /data/tts_audio
sudo mkdir -p /data/logs
sudo chown -R 1000:1000 /data/tts_audio /data/logs
sudo chmod 755 /data/tts_audio /data/logs
```

### 5. 构建并启动容器

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
signvcb-server     healthy        0.0.0.0:8012->8000/tcp
signvcb-engine     healthy        8001/tcp
```

### 6. 配置 Nginx

```bash
# 复制 Nginx 配置
sudo cp /opt/SignVCB/deploy/nginx/signvcb.conf /etc/nginx/conf.d/

# 测试配置
sudo nginx -t

# 重载 Nginx
sudo systemctl reload nginx
```

### 7. 验证部署

```bash
# 健康检查
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
| signvcb-redis | 6379 | Redis 7 缓存 | 64MB RAM |
| signvcb-server | 8012:8000 | 后端 BFF 服务 | 384MB RAM |
| signvcb-engine | 8001 | 算法引擎服务 | 1300MB RAM |

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
```

## 安全建议

1. **防火墙**: 只开放 80/443 端口 (HTTP/HTTPS)
2. **环境变量**: 确保 `.env` 文件权限为 600
3. **API 密钥**: 定期轮换外部服务密钥
4. **Nginx**: 生产环境建议配置 SSL/TLS 证书
