#!/bin/bash
# Super Harness - Vue 黄金模板 UX 基线审计 hook
# 触发器：PostToolUse + matcher "Bash(git commit*)" 之前
# 行为：扫描 git 暂存区的 Vue 文件，跑 vue-audit.sh
#       FAIL 文件 → exit 1 阻断 commit

SCRIPT_DIR="${CLAUDE_PROJECT_DIR}/.claude/scripts"
AUDIT_SCRIPT="$SCRIPT_DIR/vue-audit.sh"

# 0) 逃生门
INPUT_CMD=$(cat 2>/dev/null)
if echo "$INPUT_CMD" | grep -qE -- '--no-verify'; then
  exit 0
fi
if echo "$INPUT_CMD" | grep -qE -- '--skip-vue-audit'; then
  exit 0
fi

# 1) 检查脚本是否存在
if [ ! -f "$AUDIT_SCRIPT" ]; then
  exit 0  # 脚本缺失不阻断
fi

# 2) 找暂存区的 Vue 文件（index.vue / *Drawer.vue）
STAGED_VUE=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null | \
  grep -E "(index\.vue|.*Drawer\.vue)$" | head -10)

if [ -z "$STAGED_VUE" ]; then
  exit 0
fi

# 3) 逐个跑审计
TOTAL=0; FAIL_COUNT=0; FAIL_FILES=""
echo "[vue-audit] 检查 $(echo "$STAGED_VUE" | wc -l) 个暂存 Vue 文件..." >&2

while IFS= read -r f; do
  [ -z "$f" ] && continue
  [ ! -f "$f" ] && continue
  TOTAL=$((TOTAL+1))

  RESULT=$("$AUDIT_SCRIPT" "$f" --strict 2>&1)
  EXIT=$?

  if [ $EXIT -ne 0 ]; then
    FAIL_COUNT=$((FAIL_COUNT+1))
    FAIL_FILES="$FAIL_FILES\n  - $f"
  fi
done <<< "$STAGED_VUE"

# 4) 输出结果
echo "" >&2
if [ $FAIL_COUNT -gt 0 ]; then
  echo -e "${RED}[vue-audit]${NC} $FAIL_COUNT/$TOTAL 文件未通过黄金模板 UX 审计" >&2
  echo -e "$FAIL_FILES" >&2
  echo "" >&2
  echo "建议：" >&2
  echo "  1. 跑 /vue-audit <file> 看具体 FAIL 项" >&2
  echo "  2. 跑 /vue-migrate <file> 自动生成改造方案" >&2
  echo "  3. 或 git commit --skip-vue-audit 跳过本次审计" >&2
  exit 1
else
  echo -e "${GREEN}[vue-audit]${NC} $TOTAL 个 Vue 文件全部通过" >&2
  exit 0
fi