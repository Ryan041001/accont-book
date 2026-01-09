#!/bin/bash
# ============================================================
# Sentinel 熔断验证脚本 - 使用测试接口
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

TRANSACTION_URL="http://localhost:8083"

echo -e "${BLUE}===== Sentinel 熔断功能验证 =====${NC}"
echo ""

# 步骤1: 预热接口
echo -e "${GREEN}[步骤1] 预热测试接口${NC}"
echo "发送几个请求让 Sentinel 识别资源..."

for i in {1..3}; do
    curl -s "$TRANSACTION_URL/api/test/slow?delay=50" > /dev/null
    echo "  ✓ 预热请求 $i"
done

echo ""
echo -e "${YELLOW}现在请在 Sentinel 控制台配置熔断规则：${NC}"
echo "  1. 刷新页面，点击左侧 'transaction-service' -> '簇点链路'"
echo "  2. 找到 '/api/test/slow' 资源"
echo "  3. 点击右侧 '熔断' 按钮"
echo "  4. 配置规则："
echo "     - 熔断策略: 慢调用比例"
echo "     - 最大RT: 30 (毫秒)"
echo "     - 比例阈值: 0.3"
echo "     - 熔断时长: 10 (秒)"
echo "     - 最小请求数: 3"
echo "     - 统计时长: 1000 (毫秒)"
echo "  5. 点击 '保存'"
echo ""
read -p "配置完成后按回车继续测试..."

# 步骤2: 触发熔断
echo ""
echo -e "${GREEN}[步骤2] 发送慢请求触发熔断${NC}"
echo "发送20个请求（延迟100ms），应该触发熔断..."
echo ""

success=0
blocked=0
error=0

for i in {1..20}; do
    # 发送慢请求（100ms延迟，超过30ms阈值）
    result=$(curl -s -o /dev/null -w "%{http_code}" "$TRANSACTION_URL/api/test/slow?delay=100" 2>/dev/null)
    
    if [ "$result" = "200" ]; then
        echo -ne "${GREEN}✓${NC}"
        ((success++))
    elif [ "$result" = "429" ] || [ "$result" = "500" ]; then
        echo -ne "${YELLOW}B${NC}"
        ((blocked++))
    else
        echo -ne "${RED}E${NC}"
        ((error++))
    fi
    
    if [ $((i % 10)) -eq 0 ]; then
        echo " ($i/20)"
    fi
    
    sleep 0.3
done

echo ""
echo ""
echo -e "${BLUE}====== 测试结果 ======${NC}"
echo -e "  ${GREEN}成功: $success${NC}"
echo -e "  ${YELLOW}被熔断: $blocked${NC}"
echo -e "  ${RED}错误: $error${NC}"
echo ""

if [ $blocked -gt 0 ]; then
    echo -e "${GREEN}✅ 熔断规则已成功触发！${NC}"
    echo ""
    echo "观察 Sentinel 控制台："
    echo "  - '实时监控' 页面会显示拒绝的QPS（红色曲线）"
    echo "  - '熔断规则' 页面显示规则状态"
    echo ""
    echo "等待10秒后熔断会自动恢复，可以再次测试"
else
    echo -e "${RED}❌ 熔断未触发${NC}"
    echo ""
    echo "可能原因："
    echo "  1. 规则未正确保存"
    echo "  2. 资源名不匹配"
    echo "  3. 参数设置不合理"
    echo ""
    echo "建议检查："
    echo "  - 在 '簇点链路' 确认规则是否显示"
    echo "  - 资源名是否为 '/api/test/slow'"
fi

echo ""
echo "测试完成！"
echo ""

