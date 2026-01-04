#!/bin/bash

echo "=== 测试注册接口 ==="
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:8080/api/users/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123456"}')
echo "注册响应: $REGISTER_RESPONSE"
echo ""

echo "=== 测试登录接口 ==="
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:8080/api/users/login \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"test123456"}')
echo "登录响应: $LOGIN_RESPONSE"
echo ""

# 提取Token
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"token":"[^"]*"' | sed 's/"token":"//;s/"//')
echo "提取的Token: $TOKEN"
echo ""

echo "=== 测试获取当前用户信息接口 ==="
USER_RESPONSE=$(curl -s -X GET http://localhost:8080/api/users/me \
  -H "Authorization: Bearer $TOKEN")
echo "用户信息响应: $USER_RESPONSE"
echo ""

echo "=== 测试无Token访问受保护接口 ==="
NO_AUTH_RESPONSE=$(curl -s -w "\nHTTP状态码: %{http_code}" -X GET http://localhost:8080/api/assets)
echo "$NO_AUTH_RESPONSE"

