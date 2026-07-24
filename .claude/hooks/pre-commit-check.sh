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

# 前端语法检查: .ts/.vue 文件变更时自动验证语法，拦截低级编译错误
TS_VUE_FILES=$(echo "$STAGED_FILES" | grep -E '\.(ts|vue)$')
if [ -n "$TS_VUE_FILES" ] && command -v npx &>/dev/null; then
  echo "[Super Harness] 检查前端语法..."
  TS_ERRORS=$(cd jeecgboot-vue3 2>/dev/null && npx vue-tsc --noEmit 2>&1 | grep -c "error TS\|Unexpected" || echo "0")
  if [ "$TS_ERRORS" -gt 0 ]; then
    echo "[Super Harness] ❌ 前端语法错误 $TS_ERRORS 处 — 请修复后重新提交"
    cd jeecgboot-vue3 && npx vue-tsc --noEmit 2>&1 | grep "error TS\|Unexpected" | head -5
    echo "  跳过检查: git commit --no-verify"
    exit 1
  fi
  echo "[Super Harness] ✅ 前端语法检查通过"
fi

# 注解删除风险检测 (移除 @Transactional / @RequiresPermissions)
REMOVED_TX=$(git diff --cached | grep -E '^\-.*@Transactional' | head -5)
REMOVED_PERM=$(git diff --cached | grep -E '^\-.*@RequiresPermissions' | head -5)
if [ -n "$REMOVED_TX" ]; then
  echo "[Super Harness] ⚠️  检测到移除 @Transactional 注解:"
  echo "$REMOVED_TX"
fi
if [ -n "$REMOVED_PERM" ]; then
  echo "[Super Harness] 🔴 检测到移除 @RequiresPermissions 注解 — 可能导致未授权访问:"
  echo "$REMOVED_PERM"
  echo ""
  QUALITY_GATE_BLOCK=1
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

# ============================================
# /verify 阶段验证（硬约束）
# 本地后端在线 + 代码变更 → 必须已跑 /verify
# ============================================
STAGED_JAVA_VUE=$(echo "$STAGED_FILES" | grep -E "\.(java|vue|ts)$" | head -20)
if [ -n "$STAGED_JAVA_VUE" ] && lsof -i :8080 | grep -q LISTEN 2>/dev/null; then
  # 检查 /verify 证据：.last-verify 时间戳文件
  if [ -f ".last-verify" ]; then
    LAST_VERIFY=$(cat .last-verify 2>/dev/null)
    echo "[Super Harness] ✅ /verify 证据: $LAST_VERIFY"
  else
    echo ""
    echo "[Super Harness] ╔══════════════════════════════════════════╗"
    echo "[Super Harness] ║  🚫 未找到 /verify 证据！              ║"
    echo "[Super Harness] ╠══════════════════════════════════════════╣"
    echo "[Super Harness] ║  本地后端在运行 (8080) + 代码变更       ║"
    echo "[Super Harness] ║  按铁律：必须先 /verify（curl实测）     ║"
    echo "[Super Harness] ║  mvn compile ≠ 验证通过               ║"
    echo "$STAGED_JAVA_VUE" | while read f; do printf "[Super Harness] ║    %-40s ║\n" "$f"; done
    echo "[Super Harness] ╠══════════════════════════════════════════╣"
    echo "[Super Harness] ║  如已实测验证：touch .last-verify         ║"
    echo "[Super Harness] ║  跳过检查: git commit --no-verify         ║"
    echo "[Super Harness] ╚══════════════════════════════════════════╝"
    echo ""
  fi
fi

# ===== 质量门控（Phase 1：轻量静态检查，秒级完成）=====
# 完整代理分析通过 /quality-gate 命令执行
QUALITY_GATE_WARN=0
QUALITY_GATE_BLOCK=0

# 1. Java 变更：检查 @RequiresPermissions 完整性
JAVA_FILES=$(echo "$STAGED_FILES" | grep '\.java$')
if [ -n "$JAVA_FILES" ]; then
  # 检测新增 Controller 方法缺少权限注解
  NEW_PUBLIC_METHODS=$(git diff --cached | grep -E '^\+.*public.*Result' | head -20)
  if [ -n "$NEW_PUBLIC_METHODS" ]; then
    # 检查这些新增方法所在文件的 diff 中是否有 @RequiresPermissions
    MISSING_PERM=""
    while IFS= read -r file; do
      if echo "$file" | grep -qi "Controller"; then
        HAS_NEW_METHOD=$(git diff --cached "$file" | grep -E '^\+.*public.*Result')
        HAS_PERM=$(git diff --cached "$file" | grep -E '^\+.*@RequiresPermissions')
        if [ -n "$HAS_NEW_METHOD" ] && [ -z "$HAS_PERM" ]; then
          MISSING_PERM="$MISSING_PERM  $file\n"
        fi
      fi
    done <<< "$(echo "$JAVA_FILES")"
    if [ -n "$MISSING_PERM" ]; then
      echo "[Quality Gate] ⚠️  新增 Controller 方法缺少 @RequiresPermissions："
      echo -e "$MISSING_PERM"
      QUALITY_GATE_WARN=1
    fi
  fi

  # 检测硬编码密钥/密码
  HARDCODED_SECRET=$(git diff --cached | grep -iE '^\+.*(password|secret|token|apikey|api_key)\s*=\s*"[^"]{3,}"' | head -5)
  if [ -n "$HARDCODED_SECRET" ]; then
    echo "[Quality Gate] 🚫 检测到硬编码密钥/密码："
    echo "$HARDCODED_SECRET"
    QUALITY_GATE_BLOCK=1
  fi

  # 检测 SQL 字符串拼接（Java 文件中，排除注释行和 log 调用行避免误判）
  SQL_CONCAT=$(git diff --cached | grep -E '^\+.*\+.*"SELECT|^\+.*\+.*"INSERT.*VALUES' | grep -v -E '^\+\s*//|^\+\s*\*|log\.|logger\.' | head -5)
  if [ -n "$SQL_CONCAT" ]; then
    echo "[Quality Gate] 🚫 检测到 SQL 字符串拼接（应使用 MyBatis-Plus 参数化）："
    echo "$SQL_CONCAT"
    QUALITY_GATE_BLOCK=1
  fi
fi

# 2. Mapper XML 变更：检测 ${} 非参数化
XML_FILES=$(echo "$STAGED_FILES" | grep '\.xml$')
if [ -n "$XML_FILES" ]; then
  UNSAFE_PARAM=$(git diff --cached -- $XML_FILES | grep -E '^\+.*\$\{' | head -5)
  if [ -n "$UNSAFE_PARAM" ]; then
    echo "[Quality Gate] 🚫 Mapper XML 使用了 \${} 非参数化（应使用 #{}）："
    echo "$UNSAFE_PARAM"
    QUALITY_GATE_BLOCK=1
  fi
fi

# 3. 输出质量门控判定
if [ "$QUALITY_GATE_BLOCK" -eq 1 ]; then
  echo ""
  echo "[Quality Gate] 🔴 判定：BLOCKED — 安全问题必须修复"
  echo "  运行 /quality-gate 查看完整诊断报告"
  echo "  跳过检查: git commit --no-verify"
  exit 1
elif [ "$QUALITY_GATE_WARN" -eq 1 ]; then
  echo ""
  echo "[Quality Gate] 🟡 判定：WARN — 建议运行 /quality-gate 检查"
else
  echo "[Quality Gate] 🟢 轻量检查通过"
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


# ============================================
# 反模式检测：MES表字典（JSearchSelect dict="c_mes_*"）
# 平台SysDictMapper的原始SQL不经MyBatis-Plus → 下拉与列表数据必不一致
# 应使用 ApiSelect + /selectPage 端点
# ============================================
MES_DICT_PATTERN=$(git diff --cached | grep -E '^\+.*dict.*c_mes_' | head -5)
if [ -n "$MES_DICT_PATTERN" ]; then
  echo "[Super Harness] ⚠️  检测到 c_mes_ 表字典模式（JSearchSelect + dict=\"c_mes_xxx\"）："
  echo "$MES_DICT_PATTERN"
  echo "  → 平台字典查询不经过MyBatis-Plus，下拉数据与列表数据必然不一致"
  echo "  → 请改用 ApiSelect + 目标Controller的 /selectPage 端点"
  echo "  → 详见: .claude/rules/frontend.md 禁止模式"
  echo ""
fi


# ============================================
# 本地验证提醒：后端运行时必须 curl 实测
# ============================================
STAGED_JAVA_VUE=$(echo "$STAGED_FILES" | grep -E ".(java|vue|ts)$" | head -20)
if [ -n "$STAGED_JAVA_VUE" ] && lsof -i :8080 | grep -q LISTEN 2>/dev/null; then
  echo ""
  echo "[Super Harness] ╔══════════════════════════════════════╗"
  echo "[Super Harness] ║  本地后端在运行 (8080) — /verify 完成了吗？ ║"
  echo "[Super Harness] ╠══════════════════════════════════════╣"
  echo "[Super Harness] ║  本次变更涉及以下文件：                ║"
  echo "$STAGED_JAVA_VUE" | while read f; do printf "[Super Harness] ║    %-36s ║n" "$f"; done
  echo "[Super Harness] ╠══════════════════════════════════════╣"
  echo "[Super Harness] ║  请在提交前 curl 实测改动点核心逻辑     ║"
  echo "[Super Harness] ║  mvn compile ≠ 验证通过              ║"
  echo "[Super Harness] ╚══════════════════════════════════════╝"
  echo ""
fi

exit 0
