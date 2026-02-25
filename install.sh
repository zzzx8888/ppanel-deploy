#!/bin/bash

# PPanel 一键安装脚本
# 适用环境: Linux (Ubuntu/Debian/CentOS)
# 作用: 自动安装 Docker (如果未安装), 配置环境, 启动 PPanel 服务

set -e

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 默认安装目录
DEFAULT_INSTALL_DIR="/opt/ppanel"

echo -e "${BLUE}==== PPanel 一键安装脚本 ====${NC}"

# 1. 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}未检测到 Docker，正在尝试安装...${NC}"
    curl -fsSL https://get.docker.com | bash -s docker
    systemctl enable docker
    systemctl start docker
else
    echo -e "${GREEN}Docker 已安装。${NC}"
fi

# 检查 Docker Compose
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}未检测到 Docker Compose，请手动安装 Docker Compose 插件。${NC}"
    echo -e "${YELLOW}尝试安装 docker-compose-plugin...${NC}"
    apt-get update && apt-get install docker-compose-plugin -y || yum install docker-compose-plugin -y
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE_CMD="docker compose"
    else
        echo -e "${RED}安装失败，请手动安装 Docker Compose。${NC}"
        exit 1
    fi
fi

# 2. 设置安装目录
echo -e "${BLUE}请输入安装目录 (默认: ${DEFAULT_INSTALL_DIR}):${NC}"
read -r INSTALL_DIR
INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}

if [ ! -d "$INSTALL_DIR" ]; then
    mkdir -p "$INSTALL_DIR"
    echo -e "${GREEN}创建目录: $INSTALL_DIR${NC}"
else
    echo -e "${YELLOW}目录已存在: $INSTALL_DIR${NC}"
fi

cd "$INSTALL_DIR"

# 3. 配置参数
echo -e "${BLUE}正在配置参数...${NC}"

# 端口配置
SERVER_PORT=8080
WEB_PORT=3000

# 获取服务器 IP
PUBLIC_IP=$(curl -s ifconfig.me || echo "127.0.0.1")

echo -e "${BLUE}请输入服务端端口 (默认: ${SERVER_PORT}):${NC}"
read -r input_server_port
SERVER_PORT=${input_server_port:-$SERVER_PORT}

echo -e "${BLUE}请输入 Web 端端口 (默认: ${WEB_PORT}):${NC}"
read -r input_web_port
WEB_PORT=${input_web_port:-$WEB_PORT}

echo -e "${BLUE}请输入您的服务器 IP 或域名 (用于 Web 端连接服务端，默认: ${PUBLIC_IP}):${NC}"
read -r input_ip
HOST_IP=${input_ip:-$PUBLIC_IP}

# 生成随机密码/密钥
generate_password() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

generate_secret() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32
}

# 数据库配置
MYSQL_ROOT_PASSWORD=$(generate_password)
MYSQL_DB="ppanel"
MYSQL_USER="ppanel"
MYSQL_PASSWORD=$(generate_password)

# Redis 配置
REDIS_PASSWORD=$(generate_password)

# JWT 密钥
JWT_SECRET=$(generate_secret)

# 管理员账号
ADMIN_EMAIL="admin@ppanel.dev"
ADMIN_PASSWORD="password"

# 询问用户是否自定义高级配置
echo -e "${YELLOW}是否自定义数据库和管理员配置? (y/n, 默认 n)${NC}"
read -r CUSTOM_CONFIG

if [ "$CUSTOM_CONFIG" == "y" ]; then
    read -p "MySQL Root 密码: " input_root_pass
    [ -n "$input_root_pass" ] && MYSQL_ROOT_PASSWORD=$input_root_pass
    
    read -p "MySQL 数据库名 (默认 ppanel): " input_db_name
    [ -n "$input_db_name" ] && MYSQL_DB=$input_db_name

    read -p "MySQL 用户名 (默认 ppanel): " input_db_user
    [ -n "$input_db_user" ] && MYSQL_USER=$input_db_user

    read -p "MySQL 用户密码: " input_db_pass
    [ -n "$input_db_pass" ] && MYSQL_PASSWORD=$input_db_pass

    read -p "Redis 密码: " input_redis_pass
    [ -n "$input_redis_pass" ] && REDIS_PASSWORD=$input_redis_pass

    read -p "管理员邮箱 (默认 admin@ppanel.dev): " input_admin_email
    [ -n "$input_admin_email" ] && ADMIN_EMAIL=$input_admin_email

    read -p "管理员密码 (默认 password): " input_admin_pass
    [ -n "$input_admin_pass" ] && ADMIN_PASSWORD=$input_admin_pass
fi

# 4. 创建 .env 文件
cat > .env <<EOF
# PPanel 环境变量配置
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
MYSQL_DB=${MYSQL_DB}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
REDIS_PASSWORD=${REDIS_PASSWORD}
JWT_SECRET=${JWT_SECRET}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
SERVER_PORT=${SERVER_PORT}
WEB_PORT=${WEB_PORT}
HOST_IP=${HOST_IP}
EOF

# 5. 创建 docker-compose.yml
cat > docker-compose.yml <<EOF
version: '3.8'

services:
  mysql:
    image: mysql:8.0
    container_name: ppanel-mysql
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: \${MYSQL_DB}
      MYSQL_USER: \${MYSQL_USER}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD}
      TZ: Asia/Shanghai
    volumes:
      - mysql_data:/var/lib/mysql
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-u", "\${MYSQL_USER}", "-p\${MYSQL_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: ppanel-redis
    restart: always
    command: redis-server --requirepass \${REDIS_PASSWORD} --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  server:
    image: ssrcoco/ppanel-server:latest
    container_name: ppanel-server
    restart: always
    ports:
      - "\${SERVER_PORT}:8080"
    volumes:
      - ./etc:/app/etc
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy

  admin-web:
    image: ssrcoco/ppanel-web:latest
    container_name: ppanel-admin-web
    restart: always
    ports:
      - "\${WEB_PORT}:3000"
    environment:
      - NEXT_PUBLIC_API_URL=http://\${HOST_IP}:\${SERVER_PORT}
    depends_on:
      - server

volumes:
  mysql_data:
  redis_data:
EOF

# 6. 创建配置文件
mkdir -p etc
cat > etc/ppanel.yaml <<EOF
Host: 0.0.0.0
Port: 8080
Debug: false
JwtAuth:
  AccessSecret: ${JWT_SECRET}
  AccessExpire: 604800
Logger:
  FilePath: ./ppanel.log
  Level: info
MySQL:
  Addr: mysql:3306
  Username: ${MYSQL_USER}
  Password: ${MYSQL_PASSWORD}
  Dbname: ${MYSQL_DB}
  Config: charset=utf8mb4&parseTime=true&loc=Asia%2FShanghai
  MaxIdleConns: 10
  MaxOpenConns: 10
  SlowThreshold: 1000
Redis:
  Host: redis:6379
  Pass: ${REDIS_PASSWORD}
  DB: 0
Administrator:
  Email: ${ADMIN_EMAIL}
  Password: ${ADMIN_PASSWORD}
EOF

# 7. 启动服务
echo -e "${BLUE}正在拉取镜像并启动服务...${NC}"
${DOCKER_COMPOSE_CMD} up -d

echo -e "${GREEN}==== 安装完成 ====${NC}"
echo -e "管理面板地址: http://${HOST_IP}:${WEB_PORT}"
echo -e "服务端地址: http://${HOST_IP}:${SERVER_PORT}"
echo -e "管理员账号: ${ADMIN_EMAIL}"
echo -e "管理员密码: ${ADMIN_PASSWORD}"
echo -e "安装目录: ${INSTALL_DIR}"
