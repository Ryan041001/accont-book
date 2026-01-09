#!/bin/bash
# ============================================================
# 快速停止所有微服务
# 用法: ./dev-stop.sh [all]
#   无参数: 只停止微服务，保留基础设施
#   all: 停止所有服务包括基础设施
# ============================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}===== 停止微服务 =====${NC}"

cd "$PROJECT_ROOT"

# 1. 使用 docker-compose down 完全停止并清理容器
echo "停止所有服务..."
if [ "$1" == "all" ]; then
    echo "停止所有服务（包括基础设施）..."
    docker-compose -f docker-compose.microservices.yml down
    # 清理可能残留的容器
    docker ps -a | grep -E 'accont-' | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null || true
    echo -e "${GREEN}所有服务已停止${NC}"
else
    # 只停止微服务，保留基础设施
    echo "停止微服务容器..."
    docker stop accont-gateway accont-user accont-asset-1 accont-asset-2 accont-asset-3 accont-transaction accont-statistics 2>/dev/null || true
    docker rm accont-gateway accont-user accont-asset-1 accont-asset-2 accont-asset-3 accont-transaction accont-statistics 2>/dev/null || true
    echo -e "${GREEN}微服务已停止${NC}"
    echo -e "${YELLOW}提示：基础设施(MySQL/Nacos/RabbitMQ/Sentinel)仍在运行${NC}"
fi

# 2. 停止前端进程
echo "停止前端进程..."
pkill -f "vite.*5173" 2>/dev/null || true
pid=$(lsof -ti:5173 2>/dev/null)
if [ -n "$pid" ]; then
    kill $pid 2>/dev/null || true
fi

# 3. 清理残留Java进程
echo "清理残留进程..."
pkill -f "service.*\.jar" 2>/dev/null || true

echo ""
if [ "$1" != "all" ]; then
    echo "完全停止所有服务（包括基础设施）："
    echo "  ./scripts/dev-stop.sh all"
fi

echo ""
echo "重新启动服务："
echo "  ./scripts/dev-start.sh"
