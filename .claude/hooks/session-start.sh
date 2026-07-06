#!/bin/bash
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
