#!/bin/bash
# Super Harness — Post-merge deploy verification hook
# 触发器：PostToolUse + matcher "Bash(git pull)"
# 行为：git pull 完成后，检测 .last-deploy-commit 是否变化
#       若变化 → 后台跑 /deploy-verify --api-only（不阻塞）

DEPLOY_FILE=".last-deploy-commit"
VERIFIED_FILE=".last-deploy-verified"
LOG_DIR="/tmp"

# 0) PreToolUse 钩子返回值处理（避免输出被吞）
# 注意：PostToolUse 钩子的 stdout 会作为 additionalContext 注入 AI 会话
# 这里只输出必要的提醒，不输出进度噪声

# 1) 跳过显式逃生门
INPUT_CMD=$(cat 2>/dev/null)
if echo "$INPUT_CMD" | grep -qE -- '--no-deploy-check|skip-deploy-check'; then
  exit 0
fi

# 2) 缺失部署标记文件 → 首次部署或本地新环境，跳过
if [ ! -f "$DEPLOY_FILE" ]; then
  exit 0
fi

# 3) 读两个文件的 commit hash
DEPLOY_HASH=$(head -1 "$DEPLOY_FILE" 2>/dev/null | tr -d '[:space:]')
VERIFIED_HASH=$(head -1 "$VERIFIED_FILE" 2>/dev/null | tr -d '[:space:]')

# 4) 已验证 → 跳过
if [ -n "$DEPLOY_HASH" ] && [ "$DEPLOY_HASH" = "$VERIFIED_HASH" ]; then
  exit 0
fi

# 5) 部署 commit 新变更 → 后台跑 verify（不阻塞当前命令）
if [ -n "$DEPLOY_HASH" ]; then
  LOG_FILE="$LOG_DIR/deploy-verify-$(date +%s).log"
  nohup bash -c "
    echo \"[\$(date -Iseconds)] 开始验证部署 commit \$DEPLOY_HASH\"
    /deploy-verify --api-only 2>&1
    RC=\$?
    echo \"[\$(date -Iseconds)] 验证完成 exit=\$RC\"
    if [ \$RC -eq 0 ]; then
      echo \"\$DEPLOY_HASH\" > \"$VERIFIED_FILE\"
    fi
  " > "$LOG_FILE" 2>&1 &

  DISOWN_PID=$!
  disown $DISOWN_PID 2>/dev/null

  # 6) 注入 AI 会话提醒（PostToolUse 钩子 stdout → additionalContext）
  echo "[deploy-check] 检测到新部署 commit $DEPLOY_HASH（短: ${DEPLOY_HASH:0:8}），已在后台启动 /deploy-verify --api-only"
  echo "[deploy-check] 日志: $LOG_FILE"
fi

exit 0