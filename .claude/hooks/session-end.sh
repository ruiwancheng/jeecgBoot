#!/bin/bash
# 会话归档——结束时记录摘要
ARCHIVE_DIR="${CLAUDE_PROJECT_DIR:-.}/hermes/sessions"
mkdir -p "$ARCHIVE_DIR"

{
    echo "会话结束: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "工作目录: $(pwd)"
    echo "Git分支: $(git branch --show-current 2>/dev/null || echo 'N/A')"
    echo "最新提交: $(git log --oneline -1 2>/dev/null || echo 'N/A')"
} > "$ARCHIVE_DIR/session-$(date '+%Y%m%d-%H%M%S').txt"

exit 0
