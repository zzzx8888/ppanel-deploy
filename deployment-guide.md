# PPanel 全栈部署指南 (专业版)

本指南详细介绍了如何部署 PPanel 的服务端 (Server) 和管理端/用户端 (Web)。为了确保生产环境的稳定与安全，推荐使用 Docker Compose 进行容器化部署。

---

## 🏗️ 架构概览

- **服务端 (Server)**: 基于 Go 语言开发，提供 RESTful API、节点管理及核心业务逻辑。
- **Web 端 (Web)**: 基于 Next.js 开发，包含管理端 (Admin) 和用户端 (User)。
- **数据库**: MySQL 8.0+。
- **缓存**: Redis 6.0+。

---

## 🚀 快速部署 (Docker Compose)

这是最推荐的生产环境部署方案，能够一键启动所有组件。

### 1. 准备工作
克隆你自己的代码仓库：
```bash
# 克隆服务端
git clone https://github.com/zzzx8888/ppanel-server.git
# 克隆 Web 端
git clone https://github.com/zzzx8888/ppanel-web.git
```

### 2. 配置环境变量
在项目根目录下创建一个 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: ppanel-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: your_strong_password
      MYSQL_DATABASE: ppanel
    volumes:
      - ./data/mysql:/var/lib/mysql

  redis:
    image: redis:6-alpine
    container_name: ppanel-redis
    restart: always

  server:
    build: 
      context: ./ppanel-server
      dockerfile: Dockerfile
    container_name: ppanel-server
    restart: always
    ports:
      - "8080:8080"
    environment:
      - SECRET_KEY=your_secret_key
    volumes:
      - ./ppanel-server/etc:/app/etc
    depends_on:
      - mysql
      - redis

  admin-web:
    build:
      context: ./ppanel-web
      dockerfile: docker/ppanel-admin-web/Dockerfile
    container_name: ppanel-admin
    restart: always
    ports:
      - "3000:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://your_domain:8080
    depends_on:
      - server
```

### 3. 启动服务
```bash
docker-compose up -d
```

---

## 🛠️ 源码编译部署 (手动模式)

### 服务端 (ppanel-server)
1. **环境依赖**: Go 1.21+
2. **安装依赖**: `go mod download`
3. **配置文件**: 复制 `etc/ppanel.yaml.example` 为 `etc/ppanel.yaml` 并修改数据库连接。
4. **编译**: `go build -o ppanel-server main.go`
5. **运行**: `./ppanel-server run --config etc/ppanel.yaml`

### Web 端 (ppanel-web)
1. **环境依赖**: Node.js 18+ / Bun (推荐)
2. **安装依赖**: `bun install`
3. **构建管理端**:
   ```bash
   cd apps/admin
   bun run build
   bun run start
   ```
4. **构建用户端**:
   ```bash
   cd apps/user
   bun run build
   bun run start
   ```

---

## 🛡️ 生产环境建议

1. **反向代理**: 使用 Nginx 进行 SSL 卸载和反向代理，隐藏 8080 端口。
2. **安全密钥**: 务必修改 `SECRET_KEY`，它用于 JWT 签名。
3. **监控**: 建议开启 Prometheus 监控接口（PPanel 已内置支持）。
4. **在线升级**: 
   - 确保 `ppanel-server` 的 `constant.Repository` 已指向你的公共仓库。
   - 在发布新版本时，在 GitHub 上创建一个以 `v` 开头的 Release (如 `v1.6.4`)。

---

## ❓ 常见问题
- **数据库连接失败**: 确保 Docker 网络内 `mysql` 的主机名正确。
- **Web 端 API 404**: 检查 `NEXT_PUBLIC_API_URL` 是否指向了正确的 Server 地址。

> 更多详细信息请参考项目内的 `README.md`。
