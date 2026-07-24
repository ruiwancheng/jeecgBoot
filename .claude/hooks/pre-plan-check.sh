#!/bin/bash
PYTHON=$(command -v python3 || command -v python || echo python)
# Super Harness — 开发前依赖查证 (Pre-Plan Check)
# 自动化 workflow.md 中 5 项手动检查的前 2 项
# 非阻塞（纯建议，不返回非零 exit code）

INPUT=$(cat 2>/dev/null)

# 仅当调用 plan 技能时触发
IS_PLAN=$(echo "$INPUT" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print(d.get('skill',''))" 2>/dev/null || echo "")
if [ "$IS_PLAN" != "plan" ]; then
  exit 0
fi

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
#    标品脚本中的 DROP TABLE IF EXISTS / CREATE TABLE IF NOT EXISTS 是正常的，不检测
#    只检测迁移脚本中的 DROP INDEX IF EXISTS / ADD COLUMN IF NOT EXISTS
IF_EXISTS_FILES=$(grep -rl "DROP INDEX IF EXISTS\|ADD COLUMN IF NOT EXISTS" jeecg-boot/db/ 2>/dev/null | grep -v "target/" | head -3)
# 同时扫描项目模块中的 SQL 文件
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

exit 0
