#!/bin/bash
# Super Harness - Git Pre-commit Hook
# 检查暂存区变更是否涉及受保护目录

PROTECTED_DIRS=(
  "jeecg-boot/jeecg-boot-base-core/"
  "jeecg-boot/jeecg-module-system/"
  "jeecgboot-vue3/src/views/system/"
  "jeecgboot-vue3/src/components/"
  ".claude/"
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
