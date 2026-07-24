#!/bin/bash
# 会话归档——结束时记录摘要
ARCHIVE_DIR="${CLAUDE_PROJECT_DIR:-.}/hermes/sessions"
mkdir -p "$ARCHIVE_DIR"

{
    echo "会话结束: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "工作目录: $(pwd)"
    echo "Git分支: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo "最新提交: $(git log --oneline -1 2>/dev/null || echo 'N/A')"
    # Orca 会话结束快照
    if command -v orca &>/dev/null; then
      echo "--- Orca Snapshot ---"
      orca worktree ps --limit 10 2>/dev/null || echo "(工作树列表不可用)"
      echo "---"
    fi
} > "$ARCHIVE_DIR/session-$(date '+%Y%m%d-%H%M%S').txt"

# 清理 /plan 执行标记（避免跨会话泄漏）
rm -f /tmp/claude-plan-executed 2>/dev/null
# 清理 delegate 提醒标记
rm -f /tmp/claude-delegate-reminded-* 2>/dev/null

exit 0
