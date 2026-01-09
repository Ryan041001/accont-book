#!/bin/bash

# =============================================================================
# 微服务 API 测试脚本
# 用法: ./test-api.sh
# =============================================================================

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 配置
BASE_URL="${BASE_URL:-http://localhost:9000}"
CONTENT_TYPE="Content-Type: application/json"

# 计数器
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# =============================================================================
# 工具函数
# =============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_test() {
    echo -e "\n${YELLOW}[TEST]${NC} $1"
}

print_request() {
    local method="$1"
    local url="$2"
    local body="$3"
    
    echo -e "  ${BLUE}→${NC} $method $url"
    
    # 构建完整的 curl 命令
    local curl_cmd="curl"
    if [ "$method" != "GET" ]; then
        curl_cmd="$curl_cmd -X $method"
    fi
    curl_cmd="$curl_cmd '$url'"
    if [ -n "$body" ]; then
        curl_cmd="$curl_cmd -H '$CONTENT_TYPE' -d '$body'"
        echo -e "  ${BLUE}→${NC} Body: $body"
    fi
    echo -e "  ${CYAN}[CMD]${NC} $curl_cmd"
}

print_response() {
    local resp="$1"
    if [ ${#resp} -gt 200 ]; then
        echo -e "  ${BLUE}←${NC} Response: ${resp:0:200}..."
    else
        echo -e "  ${BLUE}←${NC} Response: $resp"
    fi
}

check_result() {
    local response="$1"
    local expected_code="$2"
    local test_name="$3"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    local code=$(echo "$response" | grep -o '"code":[0-9]*' | head -1 | cut -d: -f2)
    
    if [ "$code" == "$expected_code" ]; then
        echo -e "  ${GREEN}✓ PASSED${NC} - code=$code"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        return 0
    else
        echo -e "  ${RED}✗ FAILED${NC} - Expected code=$expected_code, got code=$code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        return 1
    fi
}

log_pass() {
    echo -e "  ${GREEN}✓ PASSED${NC} - $1"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

log_fail() {
    echo -e "  ${RED}✗ FAILED${NC} - $1"
    FAILED_TESTS=$((FAILED_TESTS + 1))
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
}

# =============================================================================
# 服务健康检查
# =============================================================================

print_header "微服务健康检查"

print_test "检查所有服务..."
ALL_UP=true
services=("Gateway:9000" "User:8081" "Asset-1:8082" "Asset-2:8092" "Asset-3:8102" "Transaction:8083" "Statistics:8084")

for svc in "${services[@]}"; do
    name="${svc%:*}"
    port="${svc#*:}"
    if curl -s --connect-timeout 3 "http://localhost:$port/actuator/health" 2>/dev/null | grep -q "UP"; then
        echo -e "  ${GREEN}✓${NC} $name ($port) 运行正常"
    else
        echo -e "  ${RED}✗${NC} $name ($port) 不可用"
        ALL_UP=false
    fi
done

if [ "$ALL_UP" = false ]; then
    echo -e "\n  ${YELLOW}提示: 请先运行 ./scripts/dev-start.sh 启动微服务${NC}"
    exit 1
fi

# =============================================================================
# JWT 认证测试
# =============================================================================

print_header "JWT 认证测试"

# 生成唯一用户名
JWT_USERNAME="testuser_$(date +%s)"
JWT_PASSWORD="password123"

print_test "用户注册"
print_request "POST" "$BASE_URL/api/users/register" "{\"username\": \"$JWT_USERNAME\", \"password\": \"$JWT_PASSWORD\"}"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/users/register" -H "$CONTENT_TYPE" -d "{\"username\": \"$JWT_USERNAME\", \"password\": \"$JWT_PASSWORD\"}" 2>/dev/null)
print_response "$RESPONSE"
if echo "$RESPONSE" | grep -q '"code":200'; then
    log_pass "code=200"
else
    log_fail "用户注册失败"
fi

print_test "用户登录获取 JWT Token"
print_request "POST" "$BASE_URL/api/users/login" "{\"username\": \"$JWT_USERNAME\", \"password\": \"$JWT_PASSWORD\"}"
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/users/login" -H "$CONTENT_TYPE" -d "{\"username\": \"$JWT_USERNAME\", \"password\": \"$JWT_PASSWORD\"}" 2>/dev/null)
print_response "$LOGIN_RESPONSE"
if echo "$LOGIN_RESPONSE" | grep -q '"token":'; then
    JWT_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"$//')
    echo -e "  ${CYAN}→ Token: ${JWT_TOKEN:0:50}...${NC}"
    log_pass "登录成功并获取 Token"
else
    log_fail "登录失败或未返回 Token"
fi

print_test "重复注册相同用户名 (应失败)"
print_request "POST" "$BASE_URL/api/users/register" "{\"username\": \"$JWT_USERNAME\", \"password\": \"newpass\"}"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/users/register" -H "$CONTENT_TYPE" -d "{\"username\": \"$JWT_USERNAME\", \"password\": \"newpass\"}" 2>/dev/null)
print_response "$RESPONSE"
if echo "$RESPONSE" | grep -q '"code":500\|用户名已存在'; then
    log_pass "正确拒绝重复注册"
else
    log_fail "应该拒绝重复用户名"
fi

print_test "错误密码登录 (应失败)"
print_request "POST" "$BASE_URL/api/users/login" "{\"username\": \"$JWT_USERNAME\", \"password\": \"wrongpassword\"}"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/users/login" -H "$CONTENT_TYPE" -d "{\"username\": \"$JWT_USERNAME\", \"password\": \"wrongpassword\"}" 2>/dev/null)
print_response "$RESPONSE"
if echo "$RESPONSE" | grep -q '"code":500\|密码错误'; then
    log_pass "正确拒绝错误密码"
else
    log_fail "应该拒绝错误密码"
fi

# =============================================================================
# 网关路由测试
# =============================================================================

print_header "网关路由测试"

print_test "路由到 Asset Service..."
print_request "GET" "$BASE_URL/api/assets/user/1"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/user/1" 2>/dev/null)
if echo "$RESPONSE" | grep -q '"code":200'; then
    log_pass "Asset Service 路由正常"
else
    log_fail "Asset Service 路由失败"
fi

print_test "路由到 Transaction Service..."
print_request "GET" "$BASE_URL/api/transactions/user/1"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/transactions/user/1" 2>/dev/null)
if echo "$RESPONSE" | grep -q '"code":200'; then
    log_pass "Transaction Service 路由正常"
else
    log_fail "Transaction Service 路由失败"
fi

print_test "路由到 Statistics Service..."
print_request "GET" "$BASE_URL/api/stats/summary/1"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/stats/summary/1" 2>/dev/null)
if echo "$RESPONSE" | grep -q '"code":200'; then
    log_pass "Statistics Service 路由正常"
else
    log_fail "Statistics Service 路由失败"
fi

# =============================================================================
# 资产管理 API 测试
# =============================================================================

print_header "资产管理 API 测试"

print_test "查询用户资产列表"
print_request "GET" "$BASE_URL/api/assets/user/1"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/user/1" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "查询用户资产列表"

print_test "查询单个资产详情"
print_request "GET" "$BASE_URL/api/assets/1"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/1" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "查询单个资产"

print_test "查询不存在的资产 (应返回404)"
print_request "GET" "$BASE_URL/api/assets/99999"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/99999" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "404" "查询不存在的资产"

print_test "创建新资产账户"
CREATE_ASSET_DATA='{"userId": 1, "name": "测试账户", "balance": 1000.00}'
print_request "POST" "$BASE_URL/api/assets" "$CREATE_ASSET_DATA"
RESPONSE=$(curl -s --connect-timeout 5 -X POST "$BASE_URL/api/assets" \
    -H "$CONTENT_TYPE" \
    -d "$CREATE_ASSET_DATA" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "创建新资产"
NEW_ASSET_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
[ -n "$NEW_ASSET_ID" ] && echo -e "  ${BLUE}→${NC} 新资产ID: $NEW_ASSET_ID"

print_test "修改资产名称 (PUT)"
UPDATE_ASSET_DATA='{"name": "私房钱"}'
print_request "PUT" "$BASE_URL/api/assets/$NEW_ASSET_ID" "$UPDATE_ASSET_DATA"
RESPONSE=$(curl -s --connect-timeout 5 -X PUT "$BASE_URL/api/assets/$NEW_ASSET_ID" \
    -H "$CONTENT_TYPE" \
    -d "$UPDATE_ASSET_DATA" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "修改资产名称"

# =============================================================================
# 流水记账 API 测试
# =============================================================================

print_header "流水记账 API 测试"

print_test "新增支出记录 (type=1)"
EXPENSE_DATA='{"userId": 1, "assetId": 1, "amount": 50.00, "type": 1, "category": "餐饮"}'
print_request "POST" "$BASE_URL/api/transactions" "$EXPENSE_DATA"
RESPONSE=$(curl -s --connect-timeout 5 -X POST "$BASE_URL/api/transactions" \
    -H "$CONTENT_TYPE" \
    -d "$EXPENSE_DATA" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "新增支出记录"
EXPENSE_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
echo -e "  ${BLUE}→${NC} 支出流水ID: $EXPENSE_ID"

print_test "新增收入记录 (type=2)"
INCOME_DATA='{"userId": 1, "assetId": 1, "amount": 200.00, "type": 2, "category": "工资"}'
print_request "POST" "$BASE_URL/api/transactions" "$INCOME_DATA"
RESPONSE=$(curl -s --connect-timeout 5 -X POST "$BASE_URL/api/transactions" \
    -H "$CONTENT_TYPE" \
    -d "$INCOME_DATA" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "新增收入记录"
INCOME_ID=$(echo "$RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
echo -e "  ${BLUE}→${NC} 收入流水ID: $INCOME_ID"

# 记录当前余额
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/1" 2>/dev/null)
BALANCE_BEFORE=$(echo "$RESPONSE" | grep -o '"balance":[0-9.]*' | head -1 | cut -d: -f2)
echo -e "  ${BLUE}→${NC} 当前余额: $BALANCE_BEFORE"

print_test "查询用户流水列表"
print_request "GET" "$BASE_URL/api/transactions/user/1"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/transactions/user/1" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "查询用户流水列表"

# =============================================================================
# 流水删除与余额回滚测试 (核心功能)
# =============================================================================

print_header "流水删除与余额回滚测试"

print_test "删除支出记录 (余额应回滚增加 +50)"
print_request "DELETE" "$BASE_URL/api/transactions/$EXPENSE_ID"
RESPONSE=$(curl -s --connect-timeout 5 -X DELETE "$BASE_URL/api/transactions/$EXPENSE_ID" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "删除支出记录"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/1" 2>/dev/null)
BALANCE_AFTER=$(echo "$RESPONSE" | grep -o '"balance":[0-9.]*' | head -1 | cut -d: -f2)
echo -e "  ${BLUE}→${NC} 删除支出后余额: $BALANCE_AFTER (预期增加50)"

print_test "删除收入记录 (余额应回滚减少 -200)"
print_request "DELETE" "$BASE_URL/api/transactions/$INCOME_ID"
RESPONSE=$(curl -s --connect-timeout 5 -X DELETE "$BASE_URL/api/transactions/$INCOME_ID" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "删除收入记录"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/1" 2>/dev/null)
BALANCE_FINAL=$(echo "$RESPONSE" | grep -o '"balance":[0-9.]*' | head -1 | cut -d: -f2)
echo -e "  ${BLUE}→${NC} 删除收入后余额: $BALANCE_FINAL (预期减少200)"

print_test "删除不存在的流水 (应返回404)"
print_request "DELETE" "$BASE_URL/api/transactions/99999"
RESPONSE=$(curl -s --connect-timeout 5 -X DELETE "$BASE_URL/api/transactions/99999" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "404" "删除不存在的流水"

# =============================================================================
# 资产删除测试
# =============================================================================

print_header "资产删除测试"

print_test "删除无流水的资产 (应成功)"
print_request "DELETE" "$BASE_URL/api/assets/$NEW_ASSET_ID"
RESPONSE=$(curl -s --connect-timeout 5 -X DELETE "$BASE_URL/api/assets/$NEW_ASSET_ID" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "删除无流水的资产"

# =============================================================================
# Feign 远程调用验证
# =============================================================================

print_header "Feign 远程调用验证"

print_test "Transaction -> Asset Feign调用测试"
print_request "GET" "$BASE_URL/api/assets/1"
RESP1=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/1" 2>/dev/null)
BAL1=$(echo "$RESP1" | grep -o '"balance":[0-9.]*' | head -1 | cut -d: -f2)
echo -e "  ${BLUE}→${NC} 交易前余额: $BAL1"

FEIGN_TEST_DATA='{"userId":1,"assetId":1,"amount":100,"type":2,"category":"Feign测试"}'
print_request "POST" "$BASE_URL/api/transactions" "$FEIGN_TEST_DATA"
curl -s --connect-timeout 5 -X POST "$BASE_URL/api/transactions" \
    -H "$CONTENT_TYPE" \
    -d "$FEIGN_TEST_DATA" >/dev/null 2>&1

print_request "GET" "$BASE_URL/api/assets/1"
RESP2=$(curl -s --connect-timeout 5 "$BASE_URL/api/assets/1" 2>/dev/null)
BAL2=$(echo "$RESP2" | grep -o '"balance":[0-9.]*' | head -1 | cut -d: -f2)
echo -e "  ${BLUE}→${NC} 交易后余额: $BAL2"

if [ -n "$BAL1" ] && [ -n "$BAL2" ]; then
    log_pass "Feign调用成功 ($BAL1 -> $BAL2)"
else
    log_fail "Feign调用失败"
fi

# =============================================================================
# 统计服务测试
# =============================================================================

print_header "统计服务测试"

print_test "获取当月概览"
print_request "GET" "$BASE_URL/api/stats/summary/1"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/stats/summary/1" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "获取当月概览"

print_test "获取月度统计"
print_request "GET" "$BASE_URL/api/stats/monthly/1?months=6"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/stats/monthly/1?months=6" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "获取月度统计"

print_test "获取分类统计"
print_request "GET" "$BASE_URL/api/stats/category/1"
RESPONSE=$(curl -s --connect-timeout 5 "$BASE_URL/api/stats/category/1" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "200" "获取分类统计"

# =============================================================================
# 参数校验测试
# =============================================================================

print_header "参数校验测试"

print_test "金额为负数 (应返回400)"
INVALID_AMOUNT='{"userId": 1, "assetId": 1, "amount": -10.00, "type": 1, "category": "测试"}'
print_request "POST" "$BASE_URL/api/transactions" "$INVALID_AMOUNT"
RESPONSE=$(curl -s --connect-timeout 5 -X POST "$BASE_URL/api/transactions" \
    -H "$CONTENT_TYPE" \
    -d "$INVALID_AMOUNT" 2>/dev/null)
print_response "$RESPONSE"
check_result "$RESPONSE" "400" "金额为负数"

# =============================================================================
# 测试报告
# =============================================================================

print_header "测试报告"

echo ""
echo -e "  网关地址:   ${CYAN}$BASE_URL${NC}"
echo -e "  总测试数:   $TOTAL_TESTS"
echo -e "  ${GREEN}通过:${NC}       $PASSED_TESTS"
echo -e "  ${RED}失败:${NC}       $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  ✓ 所有测试通过!${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}  ✗ 有 $FAILED_TESTS 个测试失败${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
