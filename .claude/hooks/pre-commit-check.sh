#!/bin/bash
# Super Harness - Git Pre-commit Hook
# 检查暂存区变更是否涉及受保护目录

PROTECTED_DIRS=(
  "jeecg-boot/jeecg-boot-base-core/"
  "jeecg-boot/jeecg-module-system/jeecg-system-biz/"
  "jeecg-boot/jeecg-module-system/jeecg-system-api/"
  "jeecg-boot/jeecg-module-system/jeecg-system-start/src/"
  "jeecgboot-vue3/src/views/system/"
  "jeecgboot-vue3/src/components/"
)

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

# SQL 危险操作检查
SQL_FILES=$(echo "$STAGED_FILES" | grep '\.sql$')
if [ -n "$SQL_FILES" ]; then
  if echo "$SQL_FILES" | xargs grep -l "DROP TABLE\|DROP DATABASE\|TRUNCATE" 2>/dev/null | grep -q .; then
    echo "[Super Harness] SQL 文件包含 DROP/TRUNCATE，禁止提交"
    exit 1
  fi
fi

# 注解删除风险检测 (移除 @Transactional / @RequiresPermissions)
REMOVED_TX=$(git diff --cached | grep -E '^\-.*@Transactional' | head -5)
REMOVED_PERM=$(git diff --cached | grep -E '^\-.*@RequiresPermissions' | head -5)
if [ -n "$REMOVED_TX" ]; then
  echo "[Super Harness] ⚠️  检测到移除 @Transactional 注解:"
  echo "$REMOVED_TX"
fi
if [ -n "$REMOVED_PERM" ]; then
  echo "[Super Harness] ⚠️  检测到移除 @RequiresPermissions 注解 — 可能导致未授权访问:"
  echo "$REMOVED_PERM"
fi

# 测试门控: 检查变更模块是否有匹配测试，有则运行快速验证
CODE_FILES=$(echo "$STAGED_FILES" | grep -E '\.(java|vue|ts)$' | head -20)
if [ -n "$CODE_FILES" ] && [ -d "harness/tests" ]; then
  CHANGED_MODULES=$(echo "$STAGED_FILES" | grep -oE '(jeecg-boot-module/[^/]+|views/[^/]+/[^/]+)' | sed 's|.*/||' | sort -u)
  for MODULE in $CHANGED_MODULES; do
    if ls "harness/tests/$MODULE/"*.spec.ts 2>/dev/null | grep -q .; then
      echo "[Super Harness] 模块 $MODULE 有测试，运行快速验证..."
      if command -v npx &>/dev/null; then
        timeout 60 npx vitest run "harness/tests/$MODULE/" --reporter=verbose 2>&1 | tail -20
        TEST_EXIT=$?
        if [ $TEST_EXIT -ne 0 ]; then
          echo ""
          echo "[Super Harness] ❌ 测试未通过！请修复后重新提交。"
          echo "  跳过检查: git commit --no-verify"
          exit 1
        else
          echo "[Super Harness] ✅ 测试通过"
        fi
      else
        echo "[Super Harness] npx 不可用，跳过测试验证"
      fi
      break
    fi
  done
fi

if [ -z "$STAGED_FILES" ]; then
  exit 0
fi

BLOCKED=""
for FILE in $STAGED_FILES; do
  for PROTECTED in "${PROTECTED_DIRS[@]}"; do
    if echo "$FILE" | grep -q "^$PROTECTED"; then
      BLOCKED="$BLOCKED  $FILE\n"
    fi
  done
done

if [ -n "$BLOCKED" ]; then
  echo "[Super Harness] 以下文件位于受保护目录，不允许直接提交："
  echo -e "$BLOCKED"
  echo "请在客户模块目录下操作。如需修改框架代码，请联系技术负责人。"
  exit 1
fi

exit 0
