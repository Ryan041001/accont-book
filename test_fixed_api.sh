#!/bin/bash

echo "=== 1. 登录获取Token ==="
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123456"}')
echo "登录响应: $LOGIN_RESPONSE"
echo ""

TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
echo "Token: $TOKEN"
echo ""

echo "=== 2. 测试GET /api/assets（获取当前用户资产） ==="
curl -s -X GET http://localhost:8080/api/assets \
  -H "Authorization: Bearer $TOKEN"
echo -e "\n"

echo "=== 3. 测试GET /api/transactions（获取当前用户流水） ==="
curl -s -X GET http://localhost:8080/api/transactions \
  -H "Authorization: Bearer $TOKEN"
echo -e "\n"

echo "=== 4. 尝试注册新用户 ==="
NEW_USERNAME="demo_$(date +%s)"
curl -s -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$NEW_USERNAME\",\"password\":\"demo123456\"}"
echo -e "\n"

