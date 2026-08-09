#!/bin/bash
# Super Harness - Pre-commit: 版本号一致性检查
# 规则文件 glob 变更 → 必须同步 bump version

STAGED_RULES=$(git diff --cached --name-only --diff-filter=M | grep '^\.claude/rules/.*\.md$' || true)
if [ -z "$STAGED_RULES" ]; then
  exit 0
fi

VIOLATIONS=0
for FILE in $STAGED_RULES; do
  # 检查本次 diff 是否改了 glob 但没改 version
  GLOB_CHANGED=$(git diff --cached "$FILE" | grep -c '^[-+].*glob:' || true)
  VERSION_CHANGED=$(git diff --cached "$FILE" | grep -c '^[-+].*version:' || true)
  
  if [ "$GLOB_CHANGED" -gt 0 ] && [ "$VERSION_CHANGED" -eq 0 ]; then
    echo "⚠️  $FILE: glob 变更但 version 未 bump"
    VIOLATIONS=$((VIOLATIONS + 1))
  fi
done

if [ "$VIOLATIONS" -gt 0 ]; then
  echo ""
  echo "❌ Pre-commit: $VIOLATIONS 个规则文件改了 glob 但没升版号。"
  echo "   改 glob = 语义变化 = 必须 bump version。"
  echo "   audit-classification.md: glob收紧 → bump minor (1.0→1.1)"
  echo "   engineering-artifacts.md: glob收紧 → bump minor (1.0→1.1)"
  exit 2
fi

echo "✅ version-glob 一致性检查通过"
exit 0
