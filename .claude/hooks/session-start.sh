#!/bin/bash
# 2026-07-28 修复: WindowsApps 的 python3 可能是商店占位 stub（存在但不可执行，--version 退出码 49）
# 必须实测可用性，不能只看 command -v
PYTHON=$(command -v python3 || command -v python || echo python)
$PYTHON --version >/dev/null 2>&1 || PYTHON=$(command -v python || echo python)
# 2026-07-28 修复: Windows python 默认 GBK，读取含中文的 JSON 会解码失败 → 统一 UTF-8
export PYTHONIOENCODING=utf-8
PROJECT=$(grep active .claude/memory/active-project.md 2>/dev/null | cut -d' ' -f2 || echo '未设置')
echo "[Super Harness v2] 当前项目: $PROJECT"
echo "命令: /new-project /switch-project /admin"

# 防失忆：检查工作流阶段
PHASE=$(grep '^| phase ' .claude/memory/progress.md 2>/dev/null | awk -F'|' '{gsub(/ /,"",$3); print $3}')
PENDING=$(grep '^| pending_step ' .claude/memory/progress.md 2>/dev/null | awk -F'|' '{gsub(/ /,"",$3); print $3}')

case "$PHASE" in
  "brainstorm")
    echo ""
    echo "⚠️  上次会话进行了需求讨论（/brainstorm），还没进入实施计划。如果是继续之前的需求，需要先 /plan。"
    ;;
  "plan")
    echo ""
    echo "⚠️  上次会话制定了实施计划（/plan），还没开始写代码。如果是继续之前的计划，确认无误后开始编码。"
    ;;
  "coding")
    echo ""
    echo "⚠️  上次会话写了代码但还没验证！记得先跑 /verify，再按分级测试走。"
    ;;
  "verify")
    echo ""
    echo "⚠️  上次会话自验证通过，下一步是分级测试（/test-api /test-e2e 等）。"
    ;;
  "testing")
    echo ""
    echo "⚠️  测试已跑但还没 /done 收尾，记得完成检查和提交。"
    ;;
esac

if [ -n "$PENDING" ] && [ "$PENDING" != "—" ]; then
  echo "📋 待办: $PENDING"
fi

# Orca 上下文感知 (非阻塞)
if command -v orca &>/dev/null; then
  ORCA_JSON=$(orca status --json 2>/dev/null || echo '{"available":false}')
  ORCA_AVAILABLE=$(echo "$ORCA_JSON" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print('true' if d.get('result',{}).get('app',{}).get('running') else 'false')" 2>/dev/null || echo "false")
  if [ "$ORCA_AVAILABLE" = "true" ]; then
    # 2026-07-28 修复: grep -c 无匹配时输出 0 且 exit 1，|| echo "0" 会追加第二个 0 → || true
    WORKTREE_COUNT=$(orca worktree ps --limit 10 2>/dev/null | grep -c "refs/heads" || true)
    echo "🔧 Orca: 可用 (工作树: ${WORKTREE_COUNT:-0} 个)"
    # 2026-07-28 修复: 删除 worktree ps 详情展示——其输出含终端 preview（会泄漏当前对话内容到会话上下文），只保留计数
  else
    echo "🔧 Orca: 不可用 (降级模式)"
  fi
else
  echo "🔧 Orca: 未安装 (标准模式)"
fi

# 测试状态恢复检测

# 深度巡检逾期检查（Phase 2：提醒用户运行 /deep-inspect）
LAST_DEEP=$(cat hermes/eagle-eye/.last-deep-inspect 2>/dev/null || echo "")
if [ -n "$LAST_DEEP" ]; then
  # OS-safe date parsing (macOS uses -j -f, Linux uses -d)
  if date -j -f "%Y-%m-%d" "2026-01-01" +%s >/dev/null 2>&1; then
    DEEP_DATE=$(date -j -f "%Y-%m-%d" "$LAST_DEEP" +%s 2>/dev/null || echo 0)
  else
    DEEP_DATE=$(date -d "$LAST_DEEP" +%s 2>/dev/null || echo 0)
  fi
  NOW=$(date +%s)
  DAYS_SINCE=$(( ($NOW - $DEEP_DATE) / 86400 ))
  if [ "$DAYS_SINCE" -gt 14 ]; then
    echo ""
    echo "⚠️  深度巡检已超过 14 天未执行（上次: $LAST_DEEP），强烈建议运行 /deep-inspect"
  elif [ "$DAYS_SINCE" -gt 7 ]; then
    echo ""
    echo "🕐 深度巡检已超过 7 天未执行（上次: $LAST_DEEP），建议运行 /deep-inspect"
  fi
else
  echo ""
  echo "📊 尚未建立性能/视觉基线，建议运行 /deep-inspect <模块> 初始化"
fi
if [ -f "hermes/eagle-eye/state.json" ]; then
  echo ""
  echo "⚠️  检测到未完成的测试运行:"
  $PYTHON -c "
import json
with open('hermes/eagle-eye/state.json') as f:
    s = json.load(f)
print(f\"  Run ID: {s.get('runId','?')}\")
print(f\"  阶段: {s.get('phase','?')} ({len(s.get('completed',[]))}/{len(s.get('completed',[]))+len(s.get('pending',[]))} 完成)\")
print(f\"  最后心跳: {s.get('lastHeartbeat','?')}\")
print(f\"\\n  输入 /test-all --resume 恢复测试，或忽略则重新开始。\")
" 2>/dev/null || echo "  (state.json 解析失败)"
fi
