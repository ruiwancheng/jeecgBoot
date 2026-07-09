#!/bin/bash
# 工具调用失败审计——记录到 hermes/logs 便于排查
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/hermes/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] FAILURE" >> "$LOG_DIR/tool-failures.log"
exit 0
