#!/bin/bash
# Super Harness - Pre-Write Hook
# 拦截 AI 对标品目录的写操作，只允许写入客户模块目录
# 2026-07-24 修复: 新增 /plan 入口缺失检测（硬阻断）

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
# Portable temp dir (Windows-safe, no /tmp/ assumption)
if [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ]; then
  HOOK_TMP="$TMPDIR"
elif [ -n "$TEMP" ] && [ -d "$TEMP" ]; then
  HOOK_TMP="$TEMP"
elif [ -d /tmp ]; then
  HOOK_TMP="/tmp"
else
  HOOK_TMP="${PROJECT_DIR}/.tmp"
  mkdir -p "$HOOK_TMP"
fi

PROTECTED_PATHS=(
  "jeecg-boot/jeecg-boot-base-core/"
  "jeecg-boot/jeecg-module-system/jeecg-system-biz/"
  "jeecg-boot/jeecg-module-system/jeecg-system-api/"
  "jeecg-boot/jeecg-module-system/jeecg-system-start/src/"
  "jeecgboot-vue3/src/views/system/"
)

if [ -p /dev/stdin ]; then
  INPUT=$(cat 2>/dev/null)
  FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# 1. 保护目录检查
# 2026-07-28 修复: exit 1 → exit 2 + stderr — Claude Code 中 exit 1 不阻断，仅 stderr 会反馈给 AI
for PROTECTED in "${PROTECTED_PATHS[@]}"; do
  if echo "$FILE_PATH" | grep -q "^$PROTECTED"; then
    echo "[Super Harness] 此目录受保护: $PROTECTED。不允许写入核心框架文件。请在客户模块目录下操作。" >&2
    exit 2
  fi
done

# 2. /plan 入口检测（硬约束）← 2026-07-24 新增
# 编辑 Java/Vue/TS/SQL 业务代码前，必须已执行 /plan（走 brainstorm→plan→orca-review 流程）
# 例外: .claude/ 目录、.md 文件、纯文案修改跳过此检查
if echo "$FILE_PATH" | grep -qE '\.(java|vue|ts|tsx|sql)$' && echo "$FILE_PATH" | grep -qvE '(\.claude/|\.md$)'; then
  PLAN_MARKER="${HOOK_TMP}/claude-plan-executed"
  if [ ! -f "$PLAN_MARKER" ]; then
    # 2026-07-28 修复: exit 1 → exit 2 + stderr（硬阻断生效前提）
    echo "[Super Harness] 🚫 未检测到 /plan 执行记录。请先走完整流程: /brainstorm → /plan → orca-review → 等确认 → 再写代码。如确属文案/注释/样式修改可豁免，请用 /admin 解除。" >&2
    exit 2
  fi
fi

# 3. Delegate 轻量提醒（会话级去重）
if echo "$FILE_PATH" | grep -qE '\.(java|vue|ts|tsx|sql)$' && echo "$FILE_PATH" | grep -qvE '(\.claude/|\.md$)'; then
  SESSION_FLAG="${HOOK_TMP}/claude-delegate-reminded-$$"
  if [ ! -f "$SESSION_FLAG" ]; then
    # 2026-07-28 修复: {"action":"warn"} 旧格式不被识别 → 改用 hookSpecificOutput.additionalContext（提醒才能真正送达 AI）
    echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"[Super Harness] ⚠️ 首次编辑代码文件。按规则：默认走 /delegate 派工人执行（仅文案/注释/样式免）。如已在 delegate 模式请忽略。"}}'
    touch "$SESSION_FLAG"
  fi
fi

exit 0
