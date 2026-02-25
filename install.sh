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

# 定义读取输入的函数，支持 curl | bash 模式
read_input() {
    if [ -t 0 ]; then
        read -r "$@"
    else
        read -r "$@" < /dev/tty
    fi
}

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
read_input INSTALL_DIR
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
read_input input_server_port
SERVER_PORT=${input_server_port:-$SERVER_PORT}

echo -e "${BLUE}请输入 Web 端端口 (默认: ${WEB_PORT}):${NC}"
read_input input_web_port
WEB_PORT=${input_web_port:-$WEB_PORT}

echo -e "${BLUE}请输入您的服务器 IP 或域名 (用于 Web 端连接服务端，默认: ${PUBLIC_IP}):${NC}"
read_input input_ip
HOST_IP=${input_ip:-$PUBLIC_IP}

# 生成随机密码/密钥
generate_password() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 16
}

generate_secret() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 32
}

# 初始化数据库变量
MYSQL_HOST="mysql"
MYSQL_PORT="3306"
MYSQL_DB="ppanel"
MYSQL_USER="ppanel"
MYSQL_PASSWORD=$(generate_password)
MYSQL_ROOT_PASSWORD=$(generate_password)
USE_INTERNAL_MYSQL=true

# 初始化 Redis 变量
REDIS_HOST="redis"
REDIS_PORT="6379"
REDIS_PASSWORD=$(generate_password)
USE_INTERNAL_REDIS=true

# 检查是否存在同名容器
if docker ps -a --format '{{.Names}}' | grep -q "^ppanel-mysql$"; then
    echo -e "${YELLOW}检测到已存在名为 'ppanel-mysql' 的容器。${NC}"
    echo -e "${BLUE}请选择操作:${NC}"
    echo -e "1) 使用已存在的 MySQL 容器/外部数据库 (推荐)"
    echo -e "2) 删除旧容器并全新安装 (警告: 数据将丢失)"
    read_input mysql_choice
    
    if [ "$mysql_choice" == "1" ]; then
        USE_INTERNAL_MYSQL=false
    elif [ "$mysql_choice" == "2" ]; then
        echo -e "${YELLOW}正在删除旧的 MySQL 容器...${NC}"
        docker rm -f ppanel-mysql
    else
        echo -e "${RED}无效选择，默认使用外部数据库。${NC}"
        USE_INTERNAL_MYSQL=false
    fi
fi

if docker ps -a --format '{{.Names}}' | grep -q "^ppanel-redis$"; then
    echo -e "${YELLOW}检测到已存在名为 'ppanel-redis' 的容器。${NC}"
    echo -e "${BLUE}请选择操作:${NC}"
    echo -e "1) 使用已存在的 Redis 容器/外部 Redis (推荐)"
    echo -e "2) 删除旧容器并全新安装"
    read_input redis_choice
    
    if [ "$redis_choice" == "1" ]; then
        USE_INTERNAL_REDIS=false
    elif [ "$redis_choice" == "2" ]; then
        echo -e "${YELLOW}正在删除旧的 Redis 容器...${NC}"
        docker rm -f ppanel-redis
    else
        echo -e "${RED}无效选择，默认使用外部 Redis。${NC}"
        USE_INTERNAL_REDIS=false
    fi
fi

# JWT 密钥
JWT_SECRET=$(generate_secret)

# 管理员账号
ADMIN_EMAIL="admin@ppanel.dev"
ADMIN_PASSWORD="password"

# 配置数据库连接信息
if [ "$USE_INTERNAL_MYSQL" == "false" ]; then
    echo -e "${BLUE}=== 配置外部 MySQL ===${NC}"
    echo -e "${YELLOW}请输入 MySQL 地址 (Host):${NC}"
    read_input input_mysql_host
    MYSQL_HOST=${input_mysql_host:-"127.0.0.1"}

    echo -e "${YELLOW}请输入 MySQL 端口 (默认 3306):${NC}"
    read_input input_mysql_port
    MYSQL_PORT=${input_mysql_port:-3306}

    echo -e "${YELLOW}请输入 MySQL 数据库名 (默认 ppanel):${NC}"
    read_input input_mysql_db
    MYSQL_DB=${input_mysql_db:-"ppanel"}

    echo -e "${YELLOW}请输入 MySQL 用户名 (默认 root):${NC}"
    read_input input_mysql_user
    MYSQL_USER=${input_mysql_user:-"root"}

    echo -e "${YELLOW}请输入 MySQL 密码:${NC}"
    read_input input_mysql_pass
    MYSQL_PASSWORD=$input_mysql_pass
else
    # 内部 MySQL 自定义配置
    echo -e "${YELLOW}是否自定义内部 MySQL 密码等配置? (y/n, 默认 n)${NC}"
    read_input custom_mysql
    if [ "$custom_mysql" == "y" ]; then
        read_input -p "MySQL Root 密码: " input_root_pass
        [ -n "$input_root_pass" ] && MYSQL_ROOT_PASSWORD=$input_root_pass
        
        read_input -p "MySQL 数据库名 (默认 ppanel): " input_db_name
        [ -n "$input_db_name" ] && MYSQL_DB=$input_db_name

        read_input -p "MySQL 用户名 (默认 ppanel): " input_db_user
        [ -n "$input_db_user" ] && MYSQL_USER=$input_db_user

        read_input -p "MySQL 用户密码: " input_db_pass
        [ -n "$input_db_pass" ] && MYSQL_PASSWORD=$input_db_pass
    fi
fi

# 配置 Redis 连接信息
if [ "$USE_INTERNAL_REDIS" == "false" ]; then
    echo -e "${BLUE}=== 配置外部 Redis ===${NC}"
    echo -e "${YELLOW}请输入 Redis 地址 (Host):${NC}"
    read_input input_redis_host
    REDIS_HOST=${input_redis_host:-"127.0.0.1"}

    echo -e "${YELLOW}请输入 Redis 端口 (默认 6379):${NC}"
    read_input input_redis_port
    REDIS_PORT=${input_redis_port:-6379}

    echo -e "${YELLOW}请输入 Redis 密码:${NC}"
    read_input input_redis_pass
    REDIS_PASSWORD=$input_redis_pass
else
    echo -e "${YELLOW}是否自定义内部 Redis 密码? (y/n, 默认 n)${NC}"
    read_input custom_redis
    if [ "$custom_redis" == "y" ]; then
        read_input -p "Redis 密码: " input_redis_pass
        [ -n "$input_redis_pass" ] && REDIS_PASSWORD=$input_redis_pass
    fi
fi

# 管理员配置
echo -e "${YELLOW}是否自定义管理员账号? (y/n, 默认 n)${NC}"
read_input custom_admin
if [ "$custom_admin" == "y" ]; then
    read_input -p "管理员邮箱 (默认 admin@ppanel.dev): " input_admin_email
    [ -n "$input_admin_email" ] && ADMIN_EMAIL=$input_admin_email

    read_input -p "管理员密码 (默认 password): " input_admin_pass
    [ -n "$input_admin_pass" ] && ADMIN_PASSWORD=$input_admin_pass
fi

# 4. 创建 .env 文件
cat > .env <<EOF
# PPanel 环境变量配置
MYSQL_HOST=${MYSQL_HOST}
MYSQL_PORT=${MYSQL_PORT}
MYSQL_DB=${MYSQL_DB}
MYSQL_USER=${MYSQL_USER}
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
REDIS_HOST=${REDIS_HOST}
REDIS_PORT=${REDIS_PORT}
REDIS_PASSWORD=${REDIS_PASSWORD}
JWT_SECRET=${JWT_SECRET}
ADMIN_EMAIL=${ADMIN_EMAIL}
ADMIN_PASSWORD=${ADMIN_PASSWORD}
SERVER_PORT=${SERVER_PORT}
WEB_PORT=${WEB_PORT}
HOST_IP=${HOST_IP}
EOF

# 5. 创建 docker-compose.yml
# 开始构建 docker-compose 内容
cat > docker-compose.yml <<EOF
version: '3.8'

services:
EOF

# 如果使用内部 MySQL，追加 MySQL 服务配置
if [ "$USE_INTERNAL_MYSQL" == "true" ]; then
cat >> docker-compose.yml <<EOF
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

EOF
fi

# 如果使用内部 Redis，追加 Redis 服务配置
if [ "$USE_INTERNAL_REDIS" == "true" ]; then
cat >> docker-compose.yml <<EOF
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

EOF
fi

# 追加 Server 和 Web 服务配置
cat >> docker-compose.yml <<EOF
  server:
    image: ssrcoco/ppanel-server:latest
    container_name: ppanel-server
    restart: always
    ports:
      - "\${SERVER_PORT}:8080"
    volumes:
      - ./etc:/app/etc
EOF

# 如果使用内部 MySQL/Redis，添加 depends_on
if [ "$USE_INTERNAL_MYSQL" == "true" ] || [ "$USE_INTERNAL_REDIS" == "true" ]; then
    echo "    depends_on:" >> docker-compose.yml
    if [ "$USE_INTERNAL_MYSQL" == "true" ]; then
        echo "      mysql:" >> docker-compose.yml
        echo "        condition: service_healthy" >> docker-compose.yml
    fi
    if [ "$USE_INTERNAL_REDIS" == "true" ]; then
        echo "      redis:" >> docker-compose.yml
        echo "        condition: service_healthy" >> docker-compose.yml
    fi
fi

cat >> docker-compose.yml <<EOF

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
EOF

if [ "$USE_INTERNAL_MYSQL" == "true" ]; then
    echo "  mysql_data:" >> docker-compose.yml
fi
if [ "$USE_INTERNAL_REDIS" == "true" ]; then
    echo "  redis_data:" >> docker-compose.yml
fi

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
  Addr: ${MYSQL_HOST}:${MYSQL_PORT}
  Username: ${MYSQL_USER}
  Password: ${MYSQL_PASSWORD}
  Dbname: ${MYSQL_DB}
  Config: charset=utf8mb4&parseTime=true&loc=Asia%2FShanghai
  MaxIdleConns: 10
  MaxOpenConns: 10
  SlowThreshold: 1000
Redis:
  Host: ${REDIS_HOST}:${REDIS_PORT}
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

if [ "$USE_INTERNAL_MYSQL" == "false" ]; then
    echo -e "${YELLOW}注意: 您使用了外部 MySQL，请确保 Server 容器能够连接到 ${MYSQL_HOST}:${MYSQL_PORT}${NC}"
fi
