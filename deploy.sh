#!/bin/bash

# PPanel 一键部署脚本 (专业版)
# 适用环境: Ubuntu/Debian/CentOS

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}==== PPanel 一键部署系统 ====${NC}"

# 1. 检查 Docker 环境
if ! [ -x "$(command -v docker)" ]; then
  echo -e "${RED}错误: 未安装 Docker。请先安装 Docker。${NC}"
  exit 1
fi

# 智能识别 Docker Compose 版本
if docker compose version >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
  DOCKER_COMPOSE_CMD="docker-compose"
else
  echo -e "${RED}错误: 未安装 Docker Compose。${NC}"
  echo -e "${BLUE}你可以使用以下命令安装 (Ubuntu/Debian):${NC}"
  echo -e "apt-get update && apt-get install docker-compose-plugin -y"
  exit 1
fi

echo -e "${GREEN}检测到 Compose 命令: ${DOCKER_COMPOSE_CMD}${NC}"

# 2. 检查并创建配置文件
if [ ! -f docker-compose.yml ] && [ ! -f docker-compose.yaml ]; then
  echo -e "${RED}错误: 在当前目录下未找到 docker-compose.yml 文件。${NC}"
  echo -e "${BLUE}请确保你已经上传了该文件到 $(pwd) 目录下。${NC}"
  exit 1
fi

if [ ! -f .env ]; then
  echo -e "${BLUE}正在创建 .env 配置文件...${NC}"
  cp .env.example .env
  echo -e "${GREEN}请修改 .env 文件中的数据库密码和 SECRET_KEY 后再运行脚本。${NC}"
  exit 0
fi

# 3. 拉取最新代码 (可选)
echo -e "${BLUE}是否拉取最新代码? (y/n)${NC}"
read -r pull_code
if [ "$pull_code" == "y" ]; then
  echo -e "${BLUE}正在拉取 Server 端代码...${NC}"
  cd ../ppanel-server && git pull origin main && cd ../ppanel-deploy
  echo -e "${BLUE}正在拉取 Web 端代码...${NC}"
  cd ../ppanel-web && git pull origin main && cd ../ppanel-deploy
fi

# 4. 拉取镜像并启动服务
echo -e "${BLUE}正在拉取最新镜像...${NC}"
${DOCKER_COMPOSE_CMD} pull

echo -e "${BLUE}正在启动容器...${NC}"
${DOCKER_COMPOSE_CMD} up -d

# 5. 检查运行状态
echo -e "${BLUE}检查容器状态:${NC}"
${DOCKER_COMPOSE_CMD} ps

echo -e "${GREEN}==== 部署完成 ====${NC}"
echo -e "服务端接口地址: http://localhost:8080"
echo -e "管理后台地址: http://localhost:3000"
echo -e "请务必检查 ppanel-server/etc/ppanel.yaml 中的数据库配置是否与 .env 一致。"
