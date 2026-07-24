#!/bin/bash
PYTHON=$(command -v python3 || command -v python || echo python)
# Super Harness — 开发前依赖查证 (Pre-Plan Check)
# 自动化 workflow.md 中 5 项手动检查的前 2 项
# 2026-07-24 修复: delegate 判定从 exit 0(警告) 改 exit 1(硬阻断)

INPUT=$(cat 2>/dev/null)

# 仅当调用 plan 技能时触发
IS_PLAN=$(echo "$INPUT" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print(d.get('skill',''))" 2>/dev/null || echo "")
if [ "$IS_PLAN" != "plan" ]; then
  exit 0
fi

# 写入 /plan 执行标记（pre-write-check 用此标记判断是否已走 plan→orca-review 流程）
date +%s > /tmp/claude-plan-executed 2>/dev/null

PASS=0
FAIL=0
MANUAL=0
RESULTS=""

# 1. Shiro 权限链: 验证 MesMenuRegistry 已注册
if grep -rl "MesMenuRegistry" jeecg-boot/jeecg-boot-module/ 2>/dev/null | grep -q .; then
  RESULTS="$RESULTS\n  ✅ 1. Shiro权限链: MesMenuRegistry 已注册"
  PASS=$((PASS+1))
else
  RESULTS="$RESULTS\n  ❌ 1. Shiro权限链: 未找到 MesMenuRegistry — 菜单和权限码可能未注册"
  FAIL=$((FAIL+1))
fi

# 2. SQL 兼容性: 检测 MySQL 5.7 不支持的语法
IF_EXISTS_FILES=$(grep -rl "DROP INDEX IF EXISTS\|ADD COLUMN IF NOT EXISTS" jeecg-boot/db/ 2>/dev/null | grep -v "target/" | head -3)
IF_EXISTS_FILES="$IF_EXISTS_FILES
$(grep -rl "DROP INDEX IF EXISTS\|ADD COLUMN IF NOT EXISTS" jeecg-boot/jeecg-boot-module/ 2>/dev/null | grep -v "target/" | head -3)"
IF_EXISTS_FILES=$(echo "$IF_EXISTS_FILES" | grep -v '^$' | sort -u)
if [ -z "$IF_EXISTS_FILES" ]; then
  RESULTS="$RESULTS\n  ✅ 2. SQL兼容性: 无 DROP INDEX IF EXISTS / ADD COLUMN IF NOT EXISTS (兼容 MySQL 5.7)"
  PASS=$((PASS+1))
else
  RESULTS="$RESULTS\n  ❌ 2. SQL兼容性: 发现 MySQL 5.7 不兼容语法:"
  while IFS= read -r f; do
    [ -n "$f" ] && RESULTS="$RESULTS\n     → $f"
  done <<< "$IF_EXISTS_FILES"
  RESULTS="$RESULTS\n     请改为: DROP INDEX 直接删除 / 存储过程先判断再 ADD COLUMN"
  FAIL=$((FAIL+1))
fi

# 3-5: 需要 AI 手动确认的项
RESULTS="$RESULTS\n  ❓ 3. 前端组件: 确认使用 JSearchSelect (dict合写格式) 而非 a-form-item"
RESULTS="$RESULTS\n  ❓ 4. 字典存在: 确认所需 sys_dict + sys_dict_item 已在 SQL 中注册 (DELETE+INSERT幂等)"
RESULTS="$RESULTS\n  ❓ 5. 父菜单存在: 确认 parentId 指向的菜单已在 MesMenuRegistry 注册"
MANUAL=3

# ============================================
# 6. Delegate 强制判定（硬约束）← 2026-07-24 修复
#   检测到未提交代码文件 → exit 1 阻断 /plan
#   强制走 /delegate 派工人执行
# ============================================
UNSTAGED_CODE=$(git diff --name-only 2>/dev/null | grep -v '\.md$' | grep -E '\.(java|vue|ts|tsx|sql)$' | head -20)
UNSTAGED_COUNT=$(echo "$UNSTAGED_CODE" | grep -c '.' 2>/dev/null || echo 0)
BLOCKED=0
if [ "$UNSTAGED_COUNT" -gt 0 ]; then
  BLOCKED=1
  RESULTS="$RESULTS"
  RESULTS="$RESULTS\n"
  RESULTS="$RESULTS\n  ╔══════════════════════════════════════════╗"
  RESULTS="$RESULTS\n  ║  🚫 DELEGATE 硬约束 — /plan 已阻断       ║"
  RESULTS="$RESULTS\n  ╠══════════════════════════════════════════╣"
  RESULTS="$RESULTS\n  ║  检测到 $UNSTAGED_COUNT 个代码文件未提交      ║"
  RESULTS="$RESULTS\n  ║  按规则：默认走 /delegate 派工人执行    ║"
  RESULTS="$RESULTS\n  ║                                        ║"
  RESULTS="$RESULTS\n  ║  操作路径：                              ║"
  RESULTS="$RESULTS\n  ║  1. git commit 提交已有改动              ║"
  RESULTS="$RESULTS\n  ║  2. 或 /delegate 走工人模式              ║"
  RESULTS="$RESULTS\n  ║  3. 纯文案/注释/样式 → 可豁免            ║"
  while IFS= read -r f; do
    [ -n "$f" ] && RESULTS="$RESULTS\n  ║    → $f"
  done <<< "$UNSTAGED_CODE"
  RESULTS="$RESULTS\n  ╚══════════════════════════════════════════╝"
fi

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Super Harness — 开发前依赖查证              ║"
echo "╚══════════════════════════════════════════════╝"
echo -e "$RESULTS"
echo ""
echo "  自动通过: $PASS | 自动失败: $FAIL | 需手动确认: $MANUAL"
echo ""

if [ $FAIL -gt 0 ]; then
  echo "⚠️  有 $FAIL 项自动检查未通过，建议修复后再制定实施计划。"
fi

# 硬约束：代码文件未提交 + 调 /plan → 阻断，强制走 delegate
if [ "$BLOCKED" -eq 1 ]; then
  echo ""
  echo "⛔ 已阻断 /plan。请先处理未提交的代码文件（commit 或 /delegate）。"
  exit 1
fi

exit 0
