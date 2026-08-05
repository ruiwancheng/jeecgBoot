#!/bin/bash
# 回归测试体系 - 一键运行脚本（Linux/macOS）
# 用法：
#   ./scripts/run-regression.sh          # 跑全量回归（API + E2E）
#   ./scripts/run-regression.sh api      # 只跑 API 模块测试
#   ./scripts/run-regression.sh e2e      # 只跑 E2E UI 测试
#   ./scripts/run-regression.sh smoke    # 跑冒烟测试（快速验证）
#
# 前置条件：
#   - 后端 fat-jar 已启动（端口 8080）
#   - 前端 Vite dev 已启动（端口 3100）
#   - MySQL 可连接（root/root，端口 3306）
#
# 推荐启动方式：
#   1) 启动 MySQL（如果用 Docker：docker compose up -d mysql）
#   2) 启动后端（参考 mes-2026-08-04 业务记录）
#   3) 启动前端（cd jeecgboot-vue3 && pnpm dev）
#   4) 跑此脚本

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HARNESS_DIR="$(dirname "$SCRIPT_DIR")"
cd "$HARNESS_DIR"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 默认参数
MODE="${1:-all}"

echo -e "${YELLOW}=== 回归测试体系（harness v1.0）==="
echo "模式: $MODE"
echo "后端 API: ${HARNESS_BASE:-http://localhost:8080/jeecg-boot}"
echo "前端 UI: ${E2E_UI_BASE:-http://localhost:3100}"
echo ""

# 检查依赖
if ! command -v node >/dev/null 2>&1; then
  echo -e "${RED}❌ node 未安装${NC}"
  exit 1
fi

if ! command -v npx >/dev/null 2>&1; then
  echo -e "${RED}❌ npx 未安装${NC}"
  exit 1
fi

# 检查后端
if ! curl -sf "http://localhost:8080/jeecg-boot/sys/login" -X POST -H "Content-Type: application/json" -d '{}' >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  后端可能未启动（http://localhost:8080）${NC}"
  echo "   启动方式：参考 mes-2026-08-04 业务记录"
  echo ""
fi

# 检查前端
if ! curl -sf http://localhost:3100 >/dev/null 2>&1; then
  echo -e "${YELLOW}⚠️  前端可能未启动（http://localhost:3100）${NC}"
  echo "   启动方式：cd jeecgboot-vue3 && pnpm dev"
  echo ""
fi

# 跑 API 测试
run_api() {
  echo -e "${YELLOW}=== 1/2 跑 API 模块测试 ==="
  PASSED=0
  FAILED=0
  for f in tests/modules/basic-*.test.js; do
    echo "  ▶ $(basename $f)"
    if timeout 120 node "$f" >/tmp/test-$$.log 2>&1; then
      PASSED=$((PASSED+1))
      grep -E "通过率|===== " /tmp/test-$$.log | tail -2
    else
      FAILED=$((FAILED+1))
      echo -e "    ${RED}❌ FAILED${NC}"
      tail -20 /tmp/test-$$.log
    fi
    rm -f /tmp/test-$$.log
  done
  echo ""
  echo -e "API: ${GREEN}$PASSED passed${NC} / ${RED}$FAILED failed${NC}"
  [ $FAILED -eq 0 ] || return 1
}

# 跑 E2E 测试
run_e2e() {
  echo -e "${YELLOW}=== 2/2 跑 E2E UI 测试 ==="
  if ! [ -d "node_modules/@playwright" ]; then
    echo "  安装 playwright 依赖..."
    npm install --no-audit --no-fund >/dev/null 2>&1
  fi
  PLAYWRIGHT_BASE_URL=${PLAYWRIGHT_BASE_URL:-http://localhost:3100} \
  E2E_UI_BASE=${E2E_UI_BASE:-http://localhost:3100} \
  E2E_API_BASE=${E2E_API_BASE:-http://localhost:8080/jeecg-boot} \
  npx playwright test e2e/mes/basic-*.spec.ts \
    --config e2e/playwright.config.ts \
    --reporter=list \
    --retries=1 \
    --timeout=60000
}

# 跑冒烟（极简版）
run_smoke() {
  echo -e "${YELLOW}=== 冒烟测试（最简版）==="
  # 只跑 1-2 个最快用例
  if ! [ -d "node_modules/@playwright" ]; then
    npm install --no-audit --no-fund >/dev/null 2>&1
  fi
  PLAYWRIGHT_BASE_URL=${PLAYWRIGHT_BASE_URL:-http://localhost:3100} \
  E2E_UI_BASE=${E2E_UI_BASE:-http://localhost:3100} \
  E2E_API_BASE=${E2E_API_BASE:-http://localhost:8080/jeecg-boot} \
  npx playwright test e2e/smoke/ --config e2e/playwright.config.ts --reporter=list
}

# 分发
case "$MODE" in
  api)
    run_api
    ;;
  e2e)
    run_e2e
    ;;
  smoke)
    run_smoke
    ;;
  all)
    run_api && run_e2e
    ;;
  *)
    echo "用法: $0 [api|e2e|smoke|all]"
    echo "  api   - 跑 API 模块测试"
    echo "  e2e   - 跑 E2E UI 测试"
    echo "  smoke - 冒烟测试（极简）"
    echo "  all   - 全量（默认）"
    exit 1
    ;;
esac

echo ""
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ 全部通过${NC}"
else
  echo -e "${RED}❌ 有失败${NC}"
  exit 1
fi