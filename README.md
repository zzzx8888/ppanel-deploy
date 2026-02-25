# PPanel 自动化部署中心 (ppanel-deploy)

本仓库是 PPanel 系统的全自动部署与运维中心。通过集成 GitHub Actions、Docker 和自动化脚本，实现“本地一键推送、云端自动构建、服务器秒速更新”的专业级 DevOps 流程。

---

## 🚀 快速开始 (服务器端)

如果你是第一次在服务器上部署，请按照以下步骤操作：

### 1. 环境准备
确保服务器已安装 **Docker** 和 **Docker Compose**。

### 2. 克隆部署项目
建议在服务器创建一个统一的目录（如 `/app/ppanel`），并将三个相关仓库克隆到同一目录下：

```bash
mkdir -p /app/ppanel && cd /app/ppanel

# 克隆部署中心
git clone https://github.com/zzzx8888/ppanel-deploy.git
# 克隆源码项目 (用于 Docker 挂载配置文件或本地构建备份)
git clone https://github.com/zzzx8888/ppanel-server.git
git clone https://github.com/zzzx8888/ppanel-web.git
```

### 3. 初始化配置
```bash
cd ppanel-deploy
cp .env.example .env
# 使用 vi 或 nano 修改 .env 中的数据库密码、Redis 密码及 SECRET_KEY
vi .env
```

### 4. 执行一键部署
```bash
chmod +x deploy.sh
./deploy.sh
```
> **注意**：由于采用了 GitHub Actions 自动构建方案，`deploy.sh` 会直接从 Docker Hub 拉取已编译好的镜像，**不再消耗服务器内存进行现场编译**，2G 内存机器也可稳定运行。

---

## 🛠️ 日常开发与更新流程 (本地端)

当你修改了 `ppanel-server` 或 `ppanel-web` 的代码后，只需执行以下操作：

1.  **一键推送**：进入本地 `ppanel-deploy` 文件夹，双击运行 **`push.bat`**。
2.  **自动构建**：GitHub Actions 会自动感应推送并开始构建 Docker 镜像。
3.  **服务器更新**：等待 GitHub Actions 构建成功（绿色勾勾）后，在服务器执行：
    ```bash
    cd /app/ppanel/ppanel-deploy
    ./deploy.sh
    ```
    选择 `n`（不拉取源码，只拉取镜像）或 `y` 均可，系统会自动拉取最新镜像并平滑重启。

---

## 📁 文件夹说明

- `deploy.sh`: 服务器端部署总控脚本。
- `push.bat`: Windows 端代码一键同步工具。
- `docker-compose.yml`: 容器编排定义。
- `.env.example`: 环境变量模板。
- `deployment-guide.md`: 详细部署手册。
- `migration-guide.md`: 生产环境数据迁移指南。
- `upgrade-guide.md`: 在线升级逻辑说明。

---

## 🛡️ 安全建议
- 生产环境务必修改 `.env` 中的 `MYSQL_ROOT_PASSWORD` 和 `SECRET_KEY`。
- 建议定期运行 `docker system prune` 清理服务器无用镜像。
