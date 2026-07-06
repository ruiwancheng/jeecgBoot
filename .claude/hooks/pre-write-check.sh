#!/bin/bash
# Super Harness - Pre-Write Hook
# 拦截 AI 对标品目录的写操作，只允许写入客户模块目录

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-/mnt/d/project/JeecgBoot}"

PROTECTED_PATHS=(
  "jeecg-boot/jeecg-boot-base-core/"
  "jeecg-boot/jeecg-module-system/"
  "jeecgboot-vue3/src/views/system/"
)

if [ -p /dev/stdin ]; then
  INPUT=$(cat 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

for PROTECTED in "${PROTECTED_PATHS[@]}"; do
  if echo "$FILE_PATH" | grep -q "^$PROTECTED"; then
    echo "{\"action\": \"block\", \"message\": \"[Super Harness] 此目录受保护: $PROTECTED。不允许写入核心框架文件。请在客户模块目录下操作。\"}"
    exit 1
  fi
done

exit 0
