# PPanel 生产环境迁移与平滑切换指南

如果你已经在生产环境部署了原作者的版本，现在想切换到你自己 Fork 并修改过的版本，同时**保留所有用户、节点和配置数据**，请按照以下步骤操作。

---

## 核心逻辑
PPanel 的数据主要存储在 **MySQL 数据库**中。切换版本的本质是：**停止旧程序 -> 备份数据 -> 启动新程序 -> 连接原数据库**。

---

## 🛠️ 操作步骤

### 1. 备份现有数据 (安全第一)
在进行任何切换操作前，务必先备份数据库。
```bash
# 如果使用 Docker 部署
docker exec ppanel-mysql mysqldump -u root -p ppanel > ppanel_backup_$(date +%F).sql

# 如果是手动部署
mysqldump -u your_user -p ppanel > ppanel_backup_$(date +%F).sql
```

### 2. 停止原作者的服务
停止当前正在运行的服务端和 Web 端容器或进程。
```bash
# Docker Compose 模式
docker-compose down

# 手动模式
# 找到进程并 kill
```

### 3. 更新代码与镜像
由于你已经 Fork 并修改了代码，你需要将这些更改部署到生产环境。

#### 方案 A：使用 Docker Compose (推荐)
修改你的 `docker-compose.yml`，将 `build` 路径指向你克隆的本地代码（即你修改过的版本）。

```yaml
services:
  server:
    build: 
      context: ./ppanel-server # 指向你 Fork 的代码目录
    # ... 其他配置保持不变，确保连接的是同一个 MySQL ...
  
  admin-web:
    build:
      context: ./ppanel-web
      dockerfile: docker/ppanel-admin-web/Dockerfile
    # ... 
```

#### 方案 B：直接拉取最新代码并重新编译
如果你是源码部署：
```bash
# 进入服务端目录
cd ppanel-server
git remote set-url origin https://github.com/zzzx8888/ppanel-server.git
git pull origin main
go build -o ppanel-server main.go

# 进入 Web 端目录
cd ppanel-web
git remote set-url origin https://github.com/zzzx8888/ppanel-web.git
git pull origin main
bun install && bun run build
```

### 4. 继承配置文件
确保新版本的配置文件（`ppanel.yaml` 或环境变量）中的以下关键项与旧版本**完全一致**：
- **数据库连接 (MySQL Host/Port/User/Pass)**
- **Redis 连接**
- **SECRET_KEY**: 必须一致，否则旧用户的所有登录 Token 将失效，需要重新登录。

### 5. 启动新版本
```bash
docker-compose up -d --build
```
`--build` 参数会确保 Docker 根据你修改后的代码重新构建镜像。

---

## 🔄 如何验证切换成功？

1. **登录管理后台**：进入“系统服务”卡片，检查“当前系统版本”是否显示为你自己仓库的状态。
2. **数据检查**：确认用户列表、节点列表、订单数据是否完整。
3. **在线升级测试**：
   - 在你的 GitHub 仓库发布一个新的 Release Tag (如 `v1.6.5`)。
   - 等待几分钟后，在 Admin 后台刷新，看是否能正确检测到来自你仓库的新版本提醒。

---

## ⚠️ 注意事项
1. **数据库结构**：如果你 Fork 的版本落后于你当前运行的版本，可能会出现数据库字段不匹配。建议始终保持 Fork 的代码是基于原项目最新 Tag 的。
2. **静态资源**：如果你修改了 Web 端的 Logo 或自定义数据，重启后应立即生效。
3. **域名与 SSL**：切换过程不涉及 Nginx 配置，因此你的域名和 SSL 证书可以保持现状。

> 只要数据库连接信息正确且 `SECRET_KEY` 一致，整个迁移过程对用户是无感的。
