# PPanel 自动化部署中心 (ppanel-deploy)

本仓库是 PPanel 系统的全自动部署与运维中心。通过集成 GitHub Actions、Docker 和自动化脚本，实现“本地一键推送、云端自动构建、服务器秒速更新”的专业级 DevOps 流程。

---

## 🚀 一键安装 (推荐)

无需下载任何代码，只需在服务器执行以下命令即可完成安装：

```bash
curl -fsSL https://raw.githubusercontent.com/zzzx8888/ppanel-deploy/main/install.sh | bash
```

---

## 🛠️ 手动部署 (源码安装)

如果你希望通过源码进行部署，请按照以下步骤操作：

### 1. 环境准备
确保服务器已安装 **Docker** 和 **Docker Compose**。

### 2. 克隆部署中心并一键初始化
建议在服务器创建一个统一的目录（如 `/app/ppanel`）：

```bash
mkdir -p /app/ppanel && cd /app/ppanel

# 1. 只需克隆部署中心
git clone https://github.com/zzzx8888/ppanel-deploy.git

# 2. 进入目录并运行一键初始化脚本
cd ppanel-deploy
chmod +x quick-start.sh
./quick-start.sh
```
> **提示**：`quick-start.sh` 会自动帮你克隆缺少的 `ppanel-server` 和 `ppanel-web` 仓库，并引导你完成 `.env` 配置和容器启动。

---

## 🛠️ 日常开发与更新流程 (本地端)

当你修改了 `ppanel-server`、`ppanel-web` 或 `ppanel-deploy` 中的任何代码后，只需执行以下操作：

1.  **一键全推**：进入本地 `ppanel-deploy` 文件夹，双击运行 **`push.bat`**。它会一次性将**三个项目**的所有改动全部推送到 GitHub。
2.  **自动构建**：GitHub Actions 会自动感应推送并开始构建新的 Docker 镜像。
3.  **服务器更新**：等待构建成功后，在服务器执行：
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
