#!/bin/bash
# Super Harness - 拦截危险 Bash 命令
PATTERNS=("git push --force" "DROP TABLE" "rm -rf /" "git reset --hard")
INPUT=$(cat 2>/dev/null)
for PATTERN in "${PATTERNS[@]}"; do
  if echo "$INPUT" | grep -qi "$PATTERN"; then
    echo "{\"action\":\"block\",\"message\":\"[Super Harness] 禁止: $PATTERN\"}"
    exit 2
  fi
done
exit 0
