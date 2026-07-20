#!/bin/bash
# Orca Repo Setup — 新工作树创建时自动运行
# 注册命令: orca repo set --repo id:fe61ad12-89c9-4ec5-8795-5a9e3ff88ceb --setup-script .claude/hooks/orca-setup.sh
# 每次 orca worktree create 时自动触发

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  JeecgBoot Harness — 开发环境初始化          ║"
echo "╚══════════════════════════════════════════════╝"
echo ""

# 1. 依赖检查
echo "── 1. 依赖检查 ──"
check_dep() {
  if command -v "$1" &>/dev/null; then
    echo "  ✅ $2"
    return 0
  else
    echo "  ❌ $2 未安装"
    return 1
  fi
}

DEPS_OK=0
check_dep java "Java" && DEPS_OK=$((DEPS_OK+1))
check_dep mvn "Maven" && DEPS_OK=$((DEPS_OK+1))
check_dep node "Node.js" && DEPS_OK=$((DEPS_OK+1))
check_dep pnpm "pnpm" && DEPS_OK=$((DEPS_OK+1))
echo "  依赖就绪: $DEPS_OK/4"

# 2. 创建标准终端布局
echo ""
echo "── 2. 终端布局 ──"

create_term() {
  local title="$1"
  local cmd="$2"
  if command -v orca &>/dev/null; then
    orca terminal create --worktree active --title "$title" --command "$cmd" 2>/dev/null && \
      echo "  ✅ $title" || echo "  ⚠️  $title 创建失败(可能已存在)"
  else
    echo "  ⚠️  Orca 不可用，跳过终端创建"
  fi
}

create_term "后端服务" "echo '准备就绪 — cd jeecg-boot/jeecg-module-system/jeecg-system-start && mvn spring-boot:run -DskipTests'"
create_term "前端服务" "echo '准备就绪 — cd jeecgboot-vue3 && pnpm dev'"
create_term "构建/Git" "echo '准备就绪 — 自由命令'"
create_term "测试/数据库" "echo '准备就绪 — vitest / playwright / mysql'"

# 3. Harness 目录验证
echo ""
echo "── 3. Harness 工程检查 ──"
check_file() {
  if [ -f "$1" ] || [ -d "$1" ]; then
    echo "  ✅ $1"
    return 0
  else
    echo "  ❌ $1 缺失"
    return 1
  fi
}

check_file "CLAUDE.md"
check_file ".claude/hooks/"
check_file ".claude/skills/"
check_file ".claude/commands/"
check_file ".claude/rules/"
check_file ".claude/settings.json"

echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  ✅ 环境初始化完成                            ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  快速开始:"
echo "    cd jeecg-boot/jeecg-module-system/jeecg-system-start && mvn spring-boot:run -DskipTests"
echo "    cd jeecgboot-vue3 && pnpm dev"
echo ""
