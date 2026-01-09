#!/bin/bash
# ============================================================
# 开发环境快速启动脚本
# 用法: ./dev-start.sh
# ============================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}===== 微服务开发环境启动 =====${NC}"
echo ""

# 1. 检查并启动基础设施
echo -e "${GREEN}[1/4] 检查基础设施...${NC}"

if ! docker ps | grep -q accont-mysql; then
    echo "启动 MySQL..."
    cd "$PROJECT_ROOT"
    docker-compose -f docker-compose.microservices.yml up -d mysql
fi

if ! docker ps | grep -q accont-nacos; then
    echo "启动 Nacos..."
    docker-compose -f docker-compose.microservices.yml up -d nacos
fi

if ! docker ps | grep -q accont-rabbitmq; then
    echo "启动 RabbitMQ..."
    docker-compose -f docker-compose.microservices.yml up -d rabbitmq
fi

if ! docker ps | grep -q accont-sentinel; then
    echo "启动 Sentinel..."
    docker-compose -f docker-compose.microservices.yml up -d sentinel-dashboard
fi

echo -e "${YELLOW}等待基础设施就绪...${NC}"
for i in {1..20}; do
    if curl -s http://localhost:8848/nacos/ > /dev/null 2>&1; then
        echo -e "${GREEN}基础设施已就绪${NC}"
        break
    fi
    sleep 2
    echo -n "."
done
echo ""

# 2. 构建JAR包
echo -e "${GREEN}[2/4] 检查并构建JAR包...${NC}"
cd "$PROJECT_ROOT/microservices"

NEED_BUILD=false
for svc in gateway-service user-service asset-service transaction-service statistics-service; do
    jar="$svc/target/$svc-1.0.0-SNAPSHOT.jar"
    if [ ! -f "$jar" ] || [ $(stat -c%s "$jar" 2>/dev/null || echo 0) -lt 100000 ]; then
        NEED_BUILD=true
        break
    fi
done

if [ "$NEED_BUILD" = true ]; then
    echo "需要重新构建..."
    mvn clean package -DskipTests -q
fi

# 3. 构建并启动微服务
echo -e "${GREEN}[3/4] 启动微服务...${NC}"
cd "$PROJECT_ROOT"

# 检查是否有问题容器需要清理
echo "检查并清理问题容器..."
docker ps -a | grep -E 'Created|Exited.*accont-' | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true

# 使用 docker-compose up -d 启动所有服务（避免 ContainerConfig 错误）
echo "启动所有服务..."
docker-compose -f docker-compose.microservices.yml up -d

echo -e "${YELLOW}等待微服务就绪...${NC}"
sleep 15

# 4. 启动前端
echo -e "${GREEN}[4/4] 启动前端...${NC}"
cd "$PROJECT_ROOT/accont-book-frontend"

if [ ! -d "node_modules" ]; then
    echo "安装前端依赖..."
    npm install
fi

# 停止旧的前端进程
pkill -f "vite.*5173" 2>/dev/null || true
nohup npm run dev > /tmp/frontend.log 2>&1 &

echo ""
echo -e "${GREEN}===== 启动完成！=====${NC}"
echo ""
echo "服务端点："
echo "  前端:     http://localhost:5173"
echo "  网关:     http://localhost:9000"
echo "  Nacos:    http://localhost:8848/nacos (nacos/nacos)"
echo "  Sentinel: http://localhost:8858 (sentinel/sentinel)"
echo "  RabbitMQ: http://localhost:15672 (guest/guest)"
echo ""
echo "查看服务状态: docker ps"
echo "查看日志: docker logs -f accont-gateway"
echo "停止服务: ./scripts/dev-stop.sh"
echo "测试API: ./scripts/test-api.sh"
