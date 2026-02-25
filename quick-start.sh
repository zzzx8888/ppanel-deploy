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

# 2. 调用部署脚本并处理
echo -e "${BLUE}[2/3] 进入部署流程...${NC}"
chmod +x deploy.sh
./deploy.sh

# 3. 清理生产环境冗余文件
echo -e "${BLUE}[3/3] 正在清理生产环境冗余文件...${NC}"
# 删除 Windows 脚本和多余的文档
rm -f push.bat deployment-guide.md migration-guide.md upgrade-guide.md
# 隐藏 Git 信息
rm -rf .git ../ppanel-server/.git ../ppanel-web/.git

echo -e "${GREEN}==== PPanel 全自动部署已完成！ ====${NC}"
echo -e "您可以访问:"
echo -e "管理端: http://您的服务器IP:3000"
echo -e "用户端: http://您的服务器IP:3001"
echo -e "服务端: http://您的服务器IP:8080"
