#!/bin/bash

# 测试AI分析功能

BASE_URL="http://localhost:8080/api"

echo "=== 1. 登录获取Token ==="
LOGIN_RESPONSE=$(curl -s -X POST "${BASE_URL}/users/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}')

echo "登录响应: $LOGIN_RESPONSE"

TOKEN=$(echo $LOGIN_RESPONSE | jq -r '.data.token')

if [ "$TOKEN" = "null" ] || [ -z "$TOKEN" ]; then
  echo "❌ 登录失败，无法获取Token"
  exit 1
fi

echo "✅ Token: $TOKEN"
echo ""

echo "=== 2. 调用AI分析接口 ==="
AI_RESPONSE=$(curl -s -X POST "${BASE_URL}/ai/analyze" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "type": "summary",
    "timeRange": "month"
  }')

echo "AI分析响应:"
echo $AI_RESPONSE | jq '.'

if echo $AI_RESPONSE | jq -e '.code == 200' > /dev/null; then
  echo ""
  echo "✅ AI分析成功！"
  echo ""
  echo "=== 分析内容 ==="
  echo $AI_RESPONSE | jq -r '.data.content'
else
  echo ""
  echo "❌ AI分析失败"
  echo "错误信息:" $(echo $AI_RESPONSE | jq -r '.message')
fi
