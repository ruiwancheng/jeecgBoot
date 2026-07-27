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

# 2026-07-28 提醒累加器：PreToolUse exit 0 时 stdout 不送达 AI，所有提醒在文末通过 additionalContext 统一发射
# 注意：追加内容保持单行、不含双引号（文末裸 echo JSON 需防转义）
WARNINGS=""
# 移除 @RequiresPermissions 的阻断标记（独立变量——质量门控段的 QUALITY_GATE_BLOCK=0 初始化会抹掉前置写入，2026-07-28 踩坑）
REMOVE_PERM_BLOCK=0

STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

# SQL 危险操作检查
SQL_FILES=$(echo "$STAGED_FILES" | grep '\.sql$')
if [ -n "$SQL_FILES" ]; then
  if echo "$SQL_FILES" | xargs grep -l "DROP TABLE\|DROP DATABASE\|TRUNCATE" 2>/dev/null | grep -q .; then
    # 2026-07-28 修复: exit 1 → exit 2 + stderr（Claude Code 中 exit 1 不阻断）
    echo "[Super Harness] SQL 文件包含 DROP/TRUNCATE，禁止提交" >&2
    exit 2
  fi
fi

# 前端语法检查: .ts/.vue 文件变更时自动验证语法，拦截低级编译错误
TS_VUE_FILES=$(echo "$STAGED_FILES" | grep -E '\.(ts|vue)$')
if [ -n "$TS_VUE_FILES" ] && command -v npx &>/dev/null; then
  echo "[Super Harness] 检查前端语法..."
  TS_ERRORS=$(cd jeecgboot-vue3 2>/dev/null && npx vue-tsc --noEmit 2>&1 | grep -c "error TS\|Unexpected" || echo "0")
  if [ "$TS_ERRORS" -gt 0 ]; then
    # 2026-07-28 修复: 阻断消息走 stderr + exit 2
    echo "[Super Harness] ❌ 前端语法错误 $TS_ERRORS 处 — 请修复后重新提交" >&2
    (cd jeecgboot-vue3 && npx vue-tsc --noEmit 2>&1 | grep "error TS\|Unexpected" | head -5) >&2
    echo "  跳过检查: git commit --no-verify" >&2
    exit 2
  fi
  echo "[Super Harness] ✅ 前端语法检查通过"
fi

# 注解删除风险检测 (移除 @Transactional / @RequiresPermissions)
REMOVED_TX=$(git diff --cached | grep -E '^\-.*@Transactional' | head -5)
REMOVED_PERM=$(git diff --cached | grep -E '^\-.*@RequiresPermissions' | head -5)
if [ -n "$REMOVED_TX" ]; then
  echo "[Super Harness] ⚠️  检测到移除 @Transactional 注解:"
  echo "$REMOVED_TX"
  WARNINGS="${WARNINGS}检测到移除 @Transactional 注解; "
fi
if [ -n "$REMOVED_PERM" ]; then
  echo "[Super Harness] 🔴 检测到移除 @RequiresPermissions 注解 — 可能导致未授权访问:"
  echo "$REMOVED_PERM"
  echo ""
  REMOVE_PERM_BLOCK=1
  WARNINGS="${WARNINGS}检测到移除 @RequiresPermissions 注解(可能致未授权访问); "
fi

# 测试门控: 检查变更模块是否有匹配测试，有则运行快速验证
CODE_FILES=$(echo "$STAGED_FILES" | grep -E '\.(java|vue|ts)$' | head -20)
if [ -n "$CODE_FILES" ] && [ -d "harness/tests" ]; then
  CHANGED_MODULES=$(echo "$STAGED_FILES" | grep -oE '(jeecg-boot-module/[^/]+|views/[^/]+/[^/]+)' | sed 's|.*/||' | sort -u)
  for MODULE in $CHANGED_MODULES; do
    if ls "harness/tests/$MODULE/"*.spec.ts 2>/dev/null | grep -q .; then
      echo "[Super Harness] 模块 $MODULE 有测试，运行快速验证..."
      if command -v npx &>/dev/null; then
        # 2026-07-28 修复: 原写法 TEST_EXIT=$? 取的是管道末尾 tail 的退出码，测试失败永远无法阻断 → 改用 PIPESTATUS 取 vitest 真实退出码
        if command -v timeout >/dev/null 2>&1; then
          TEST_OUT=$(timeout 60 npx vitest run "harness/tests/$MODULE/" --reporter=verbose 2>&1 | tail -20)
          TEST_EXIT=${PIPESTATUS[0]}
        else
          # macOS/BSD fallback: no native timeout, run without time limit
          TEST_OUT=$(npx vitest run "harness/tests/$MODULE/" --reporter=verbose 2>&1 | tail -20)
          TEST_EXIT=${PIPESTATUS[0]}
        fi
        if [ $TEST_EXIT -ne 0 ]; then
          # 2026-07-28 修复: 失败详情+阻断消息走 stderr（exit 2 时只有 stderr 送达 AI）
          echo "$TEST_OUT" >&2
          echo "[Super Harness] ❌ 测试未通过！请修复后重新提交。" >&2
          echo "  跳过检查: git commit --no-verify" >&2
          exit 2
        else
          echo "$TEST_OUT"
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
# .last-verify 格式: "YYYY-MM-DD HH:MM:SS <commit_hash>"
# HEAD 变化后旧记录自动失效（防止一次touch永久通过）
# ============================================
STAGED_JAVA_VUE=$(echo "$STAGED_FILES" | grep -E "\.(java|vue|ts)$" | head -20)
# Portable port check: try lsof, fallback to ss/netstat
PORT_8080_UP=false
if command -v lsof >/dev/null 2>&1; then
  lsof -i :8080 2>/dev/null | grep -q LISTEN && PORT_8080_UP=true
elif command -v ss >/dev/null 2>&1; then
  ss -tlnp 2>/dev/null | grep -q ':8080 ' && PORT_8080_UP=true
elif command -v netstat >/dev/null 2>&1; then
  netstat -tlnp 2>/dev/null | grep -q ':8080 ' && PORT_8080_UP=true
fi
if [ -n "$STAGED_JAVA_VUE" ] && [ "$PORT_8080_UP" = true ]; then
  CURRENT_HEAD=$(git rev-parse HEAD 2>/dev/null)
  VERIFY_VALID=0
  if [ -f ".last-verify" ]; then
    LAST_VERIFY=$(cat .last-verify 2>/dev/null)
    # 提取 .last-verify 中记录的 commit hash（格式: "YYYY-MM-DD HH:MM:SS <hash>"）
    VERIFY_COMMIT=$(echo "$LAST_VERIFY" | awk '{print $NF}')
    if [ "$VERIFY_COMMIT" = "$CURRENT_HEAD" ]; then
      echo "[Super Harness] ✅ /verify 通过 (commit: ${CURRENT_HEAD:0:7})"
      VERIFY_VALID=1
    else
      echo "[Super Harness] ⚠️  .last-verify 记录的是旧 commit (${VERIFY_COMMIT:0:7})，当前 HEAD 已变 (${CURRENT_HEAD:0:7})"
      WARNINGS="${WARNINGS}.last-verify 记录已过期(HEAD 已变); "
    fi
  fi
  if [ "$VERIFY_VALID" -eq 0 ]; then
    echo ""
    echo "[Super Harness] ╔══════════════════════════════════════════╗"
    echo "[Super Harness] ║  🚫 /verify 证据缺失或过期              ║"
    echo "[Super Harness] ╠══════════════════════════════════════════╣"
    echo "[Super Harness] ║  本地后端在运行 (8080) + 代码变更       ║"
    echo "[Super Harness] ║  按铁律：必须先 /verify（curl实测）     ║"
    echo "$STAGED_JAVA_VUE" | while read f; do printf "[Super Harness] ║    %-40s ║\n" "$f"; done
    echo "[Super Harness] ╠══════════════════════════════════════════╣"
    echo "[Super Harness] ║  修复: 运行 /verify → 自动记录证据      ║"
    echo "[Super Harness] ║  紧急: git commit --no-verify            ║"
    echo "[Super Harness] ╚══════════════════════════════════════════╝"
    echo ""
  fi
fi

# ===== 质量门控（Phase 1：轻量静态检查，秒级完成）=====
# 完整代理分析通过 /quality-gate 命令执行
# 2026-07-28 注意：此处只初始化质量门控段变量，勿把前置检测的标记（REMOVE_PERM_BLOCK）纳入重置
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
      WARNINGS="${WARNINGS}新增 Controller 方法缺少 @RequiresPermissions; "
    fi
  fi

  # 检测硬编码密钥/密码
  # 2026-07-28 修复: 以下 3 处 🚫 发现项改走 stderr — 后续 exit 2 时只有 stderr 送达 AI
  HARDCODED_SECRET=$(git diff --cached | grep -iE '^\+.*(password|secret|token|apikey|api_key)\s*=\s*"[^"]{3,}"' | head -5)
  if [ -n "$HARDCODED_SECRET" ]; then
    echo "[Quality Gate] 🚫 检测到硬编码密钥/密码：" >&2
    echo "$HARDCODED_SECRET" >&2
    QUALITY_GATE_BLOCK=1
  fi

  # 检测 SQL 字符串拼接（Java 文件中，排除注释行和 log 调用行避免误判）
  SQL_CONCAT=$(git diff --cached | grep -E '^\+.*\+.*"SELECT|^\+.*\+.*"INSERT.*VALUES' | grep -v -E '^\+\s*//|^\+\s*\*|log\.|logger\.' | head -5)
  if [ -n "$SQL_CONCAT" ]; then
    echo "[Quality Gate] 🚫 检测到 SQL 字符串拼接（应使用 MyBatis-Plus 参数化）：" >&2
    echo "$SQL_CONCAT" >&2
    QUALITY_GATE_BLOCK=1
  fi
fi

# 2. Mapper XML 变更：检测 ${} 非参数化
XML_FILES=$(echo "$STAGED_FILES" | grep '\.xml$')
if [ -n "$XML_FILES" ]; then
  UNSAFE_PARAM=$(git diff --cached -- $XML_FILES | grep -E '^\+.*\$\{' | head -5)
  if [ -n "$UNSAFE_PARAM" ]; then
    echo "[Quality Gate] 🚫 Mapper XML 使用了 \${} 非参数化（应使用 #{}）：" >&2
    echo "$UNSAFE_PARAM" >&2
    QUALITY_GATE_BLOCK=1
  fi
fi

# 3. 输出质量门控判定
# 2026-07-28 合并前置的移除-注解阻断标记（独立变量，避免被段内初始化抹掉）
if [ "$REMOVE_PERM_BLOCK" -eq 1 ]; then
  QUALITY_GATE_BLOCK=1
fi
if [ "$QUALITY_GATE_BLOCK" -eq 1 ]; then
  echo "" >&2
  echo "[Quality Gate] 🔴 判定：BLOCKED — 安全问题必须修复" >&2
  echo "  运行 /quality-gate 查看完整诊断报告" >&2
  echo "  跳过检查: git commit --no-verify" >&2
  exit 2
elif [ "$QUALITY_GATE_WARN" -eq 1 ]; then
  echo ""
  echo "[Quality Gate] 🟡 判定：WARN — 建议运行 /quality-gate 检查"
  WARNINGS="${WARNINGS}质量门控判定 WARN(建议运行 /quality-gate); "
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
  # 2026-07-28 修复: exit 1 → exit 2 + stderr
  echo "[Super Harness] 以下文件位于受保护目录，不允许直接提交：" >&2
  echo -e "$BLOCKED" >&2
  echo "请在客户模块目录下操作。如需修改框架代码，请联系技术负责人。" >&2
  exit 2
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
  WARNINGS="${WARNINGS}检测到 c_mes_ 表字典反模式(应改用 ApiSelect + /selectPage); "
fi


# ============================================
# 本地验证提醒：后端运行时必须 curl 实测
# ============================================
STAGED_JAVA_VUE=$(echo "$STAGED_FILES" | grep -E ".(java|vue|ts)$" | head -20)
# Portable port check: try lsof, fallback to ss/netstat
PORT_8080_UP=false
if command -v lsof >/dev/null 2>&1; then
  lsof -i :8080 2>/dev/null | grep -q LISTEN && PORT_8080_UP=true
elif command -v ss >/dev/null 2>&1; then
  ss -tlnp 2>/dev/null | grep -q ':8080 ' && PORT_8080_UP=true
elif command -v netstat >/dev/null 2>&1; then
  netstat -tlnp 2>/dev/null | grep -q ':8080 ' && PORT_8080_UP=true
fi
if [ -n "$STAGED_JAVA_VUE" ] && [ "$PORT_8080_UP" = true ]; then
  echo ""
  echo "[Super Harness] ╔══════════════════════════════════════╗"
  echo "[Super Harness] ║  本地后端在运行 (8080) — /verify 完成了吗？ ║"
  echo "[Super Harness] ╠══════════════════════════════════════╣"
  echo "[Super Harness] ║  本次变更涉及以下文件：                ║"
  echo "$STAGED_JAVA_VUE" | while read f; do printf "[Super Harness] ║    %-36s ║\n" "$f"; done
  echo "[Super Harness] ╠══════════════════════════════════════╣"
  echo "[Super Harness] ║  请在提交前 curl 实测改动点核心逻辑     ║"
  echo "[Super Harness] ║  mvn compile ≠ 验证通过              ║"
  echo "[Super Harness] ╚══════════════════════════════════════╝"
  echo ""
  # 2026-07-28 与上方 /verify 证据检查合并为一条提醒（证据有效则不重复提醒）
  [ "${VERIFY_VALID:-0}" -eq 0 ] && WARNINGS="${WARNINGS}本地后端在线(8080)+代码变更,提交前须 /verify curl 实测; "
fi

# 2026-07-28 修复: exit 0 的 stdout 不送达 AI → 提醒通过 additionalContext 统一发射
# （裸 echo 零依赖；WARNINGS 为受控单行文本、无双引号，无 JSON 转义风险）
if [ -n "$WARNINGS" ]; then
  echo "{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"additionalContext\":\"[Super Harness] 提交前提醒: ${WARNINGS}（跳过检查: git commit --no-verify）\"}}"
fi

exit 0
