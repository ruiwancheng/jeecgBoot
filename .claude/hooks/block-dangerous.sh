#!/bin/bash
# Super Harness - 拦截危险 Bash 命令
PATTERNS=("git push --force" "DROP TABLE" "rm -rf /" "git reset --hard")
INPUT=$(cat 2>/dev/null)
# 2026-07-28 修复: 阻断消息改走 stderr — Claude Code 协议中 exit 2 时只有 stderr 会反馈给 AI，stdout 的 {"action":"block"} 旧格式不被识别
for PATTERN in "${PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qi "$PATTERN"; then
    echo "[Super Harness] 禁止: $PATTERN" >&2
    exit 2
  fi
done
exit 0
