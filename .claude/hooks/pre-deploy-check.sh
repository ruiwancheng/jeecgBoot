#!/bin/bash
PYTHON=$(command -v python3 || command -v python || echo python)
# Super Harness — 部署前用户流程验证
# 在 docker compose up 或 start-docker-compose 前自动运行
# 验证 3 项核心用户流程是否可达（非阻塞，纯报告）

BASE_URL="${DEPLOY_TARGET:-http://localhost:8080}"
FRONTEND_URL="${FRONTEND_TARGET:-http://localhost:3100}"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Super Harness — 部署前用户流程验证           ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

PASS=0
FAIL=0
WARN=0

# 1. 登录接口验证
echo "  1. 登录接口..."
LOGIN_RESP=$(curl -s -w "\n%{http_code}" --max-time 10 \
  -X POST "$BASE_URL/jeecg-boot/sys/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456","captcha":"","remember":true}' 2>/dev/null)
HTTP_CODE=$(echo "$LOGIN_RESP" | tail -1)
if [ "$HTTP_CODE" = "200" ]; then
  TOKEN=$(echo "$LOGIN_RESP" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print(d.get('result',{}).get('token','NONE')[:20])" 2>/dev/null || echo "PARSE_ERR")
  if [ "$TOKEN" != "NONE" ] && [ "$TOKEN" != "PARSE_ERR" ]; then
    echo "    ✅ 登录接口正常 (HTTP 200, Token: ${TOKEN}...)"
    PASS=$((PASS+1))
  else
    echo "    ⚠️  登录接口返回200但Token解析异常"
    WARN=$((WARN+1))
  fi
else
  echo "    ❌ 登录接口返回 $HTTP_CODE — 后端可能未启动"
  FAIL=$((FAIL+1))
fi

# 2. 菜单权限树加载
echo "  2. 菜单加载..."
if [ -n "$TOKEN" ] && [ "$TOKEN" != "NONE" ] && [ "$TOKEN" != "PARSE_ERR" ]; then
  PERM_RESP=$(curl -s --max-time 10 \
    -X GET "$BASE_URL/jeecg-boot/sys/permission/queryTreeList" \
    -H "X-Access-Token: $TOKEN" 2>/dev/null)
  if echo "$PERM_RESP" | grep -q '"success":true'; then
    PERM_COUNT=$(echo "$PERM_RESP" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print(len(d.get('result',[])))" 2>/dev/null || echo "?")
    echo "    ✅ 菜单树加载正常 ($PERM_COUNT 条)"
    PASS=$((PASS+1))
  else
    echo "    ❌ 菜单树加载失败"
    FAIL=$((FAIL+1))
  fi
else
  echo "    ⚠️  跳过（登录未获取到Token）"
  WARN=$((WARN+1))
fi

# 3. 前端服务可达性
echo "  3. 前端服务..."
FRONTEND_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$FRONTEND_URL" 2>/dev/null)
if [ -n "$FRONTEND_CODE" ] && echo "200 302 304" | grep -q "$FRONTEND_CODE"; then
  echo "    ✅ 前端服务可达 (HTTP $FRONTEND_CODE)"
  PASS=$((PASS+1))
elif [ -z "$FRONTEND_CODE" ]; then
  echo "    ? 前端服务未检测到（可能使用服务端部署，跳过）"
else
  echo "    ⚠️  前端返回 $FRONTEND_CODE（可能使用服务端部署）"
  WARN=$((WARN+1))
fi

echo ""
echo "  结果: ✅ $PASS 通过 | ⚠️ $WARN 警告 | ❌ $FAIL 失败"

if [ $FAIL -gt 0 ]; then
  echo ""
  echo "  ⚠️  有 $FAIL 项验证失败，部署后可能需要排查。"
  echo "  建议: 部署完成后运行 /test-e2e smoke 确认冒烟测试通过。"
fi

echo ""
exit 0
