#!/bin/bash

# PPanel 一键环境初始化与部署脚本
# 适用环境: Linux

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

GITHUB_USER="zzzx8888"
BASE_DIR=$(pwd)

echo -e "${BLUE}==== PPanel 全自动部署初始化 ====${NC}"

# 1. 检查并克隆缺少的仓库
echo -e "${BLUE}[1/3] 检查项目完整性...${NC}"

if [ ! -d "../ppanel-server" ]; then
    echo -e "${BLUE}正在克隆 Server 端...${NC}"
    git clone https://github.com/${GITHUB_USER}/ppanel-server.git ../ppanel-server
else
    echo -e "${GREEN}检测到 Server 端已存在。${NC}"
fi

if [ ! -d "../ppanel-web" ]; then
    echo -e "${BLUE}正在克隆 Web 端...${NC}"
    git clone https://github.com/${GITHUB_USER}/ppanel-web.git ../ppanel-web
else
    echo -e "${GREEN}检测到 Web 端已存在。${NC}"
fi

# 2. 调用原有的部署脚本
echo -e "${BLUE}[2/3] 进入部署流程...${NC}"
chmod +x deploy.sh
./deploy.sh

echo -e "${GREEN}==== 所有操作已完成 ====${NC}"
