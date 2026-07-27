#!/bin/bash
# 2026-07-28 修复: WindowsApps 的 python3 可能是商店占位 stub（存在但不可执行，--version 退出码 49）
# 必须实测可用性，不能只看 command -v
PYTHON=$(command -v python3 || command -v python || echo python)
$PYTHON --version >/dev/null 2>&1 || PYTHON=$(command -v python || echo python)
# 2026-07-28 修复: Windows python 默认 GBK 编码，读写含中文的内容会 UnicodeError → 统一 UTF-8
export PYTHONIOENCODING=utf-8
# 工具调用失败审计 — 结构化日志记录
# 从 stdin JSON 提取失败上下文，写入结构化 jsonl + 兼容旧 log
LOG_DIR="${CLAUDE_PROJECT_DIR:-.}/hermes/logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ISO_TIMESTAMP=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

# 尝试从 stdin 提取结构化信息
INPUT=$(cat 2>/dev/null)
if [ -n "$INPUT" ] && echo "$INPUT" | $PYTHON -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
  TOOL_NAME=$(echo "$INPUT" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print(d.get('tool_name','unknown'))" 2>/dev/null || echo "unknown")
  ERROR_MSG=$(echo "$INPUT" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print(d.get('error','')[:200])" 2>/dev/null || echo "")
  FILE_PATH=$(echo "$INPUT" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print(d.get('file_path',''))" 2>/dev/null || echo "")
  BRANCH=$(git branch --show-current 2>/dev/null || echo "N/A")
  WORKDIR=$(pwd)

  # Orca 状态检测 (非阻塞)
  ORCA_AVAILABLE="false"
  ORCA_WORKTREES="0"
  if command -v orca &>/dev/null; then
    ORCA_STATUS=$(orca status --json 2>/dev/null || echo '{"available":false}')
    ORCA_AVAILABLE=$(echo "$ORCA_STATUS" | $PYTHON -c "import sys,json; d=json.load(sys.stdin); print('true' if d.get('result',{}).get('app',{}).get('running') else 'false')" 2>/dev/null || echo "false")
    ORCA_WORKTREES=$(orca worktree ps --limit 99 2>/dev/null | grep -c "refs/heads" || echo "0")
  fi

  # 2026-07-28 修复: bash 的 true/false 直接插值进 Python 会 NameError（Python 是 True/False），
  # 导致 jsonl 写入静默失败（被 2>/dev/null 吞掉）→ 在 bash 侧先转成 Python 字面量
  ORCA_BOOL=False
  [ "$ORCA_AVAILABLE" = "true" ] && ORCA_BOOL=True

  # 结构化 JSONL 写入
  $PYTHON -c "
import json, sys
entry = {
    'timestamp': '$ISO_TIMESTAMP',
    'tool': '$TOOL_NAME',
    'file': '$FILE_PATH',
    'error': '''$ERROR_MSG''',
    'branch': '$BRANCH',
    'workdir': '$WORKDIR',
    'orca': {
        'available': $ORCA_BOOL,
        'worktrees': int($ORCA_WORKTREES)
    }
}
with open('$LOG_DIR/tool-failures.jsonl', 'a', encoding='utf-8') as f:
    f.write(json.dumps(entry, ensure_ascii=False) + '\n')
" 2>/dev/null

  # 同时写可读日志行 (向后兼容)
  echo "[$TIMESTAMP] $TOOL_NAME | file=$FILE_PATH | branch=$BRANCH | orca=$ORCA_AVAILABLE" >> "$LOG_DIR/tool-failures.log"
  if [ -n "$ERROR_MSG" ]; then
    echo "  error: $ERROR_MSG" >> "$LOG_DIR/tool-failures.log"
  fi
else
  # stdin 不可解析 → 回退到旧行为
  echo "[$TIMESTAMP] FAILURE" >> "$LOG_DIR/tool-failures.log"
fi

exit 0
