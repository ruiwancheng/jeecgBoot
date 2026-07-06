#!/bin/bash
echo "[Super Harness v2] 当前项目: $(grep active .claude/memory/active-project.md 2>/dev/null | cut -d' ' -f2 || echo '未设置')"
echo "命令: /new-project /switch-project /admin"
