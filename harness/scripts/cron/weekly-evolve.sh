#!/bin/bash
# weekly-evolve.sh — 每周日 23:00 自动跑 /evolve
# 用法: bash harness/scripts/cron/weekly-evolve.sh
# 配置: crontab -e → 0 23 * * 0 bash /path/to/harness/scripts/cron/weekly-evolve.sh >> /var/log/evolve.log 2>&1

set -e

# 0. 路径配置
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_ROOT"

LOG_FILE="$REPO_ROOT/.claude/cron/evolve-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "=== weekly-evolve 开始: $(date) ===" | tee -a "$LOG_FILE"
echo "仓库: $REPO_ROOT" | tee -a "$LOG_FILE"

# 1. 跑 /learn（提取本次会话经验）
echo "" | tee -a "$LOG_FILE"
echo "--- Step 1: /learn ---" | tee -a "$LOG_FILE"
# AI 跑 /learn（CLI 模式 — 通过 agent 调用）
# 注：实际跑需 agent 介入，这里只跑 read-only 报告
if command -v code-review-graph >/dev/null 2>&1; then
  echo "  code-review-graph 可用，可跑完整 /learn 流程" | tee -a "$LOG_FILE"
else
  echo "  ⚠️ code-review-graph 不可用，跳过 /learn（手动跑）" | tee -a "$LOG_FILE"
fi

# 2. 跑 /auto-learn（read-only 报告）
echo "" | tee -a "$LOG_FILE"
echo "--- Step 2: /auto-learn ---" | tee -a "$LOG_FILE"
echo "  learnings 数量: $(ls -1 .claude/memory/learnings/*.md 2>/dev/null | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "  rules/ 行数: $(cat .claude/rules/*.md 2>/dev/null | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"
echo "  rules/ 章节数: $(grep -h '^## ' .claude/rules/*.md 2>/dev/null | wc -l | tr -d ' ')" | tee -a "$LOG_FILE"

# 3. 检测哪些 learnings 未规则化（输出报告）
echo "" | tee -a "$LOG_FILE"
echo "--- Step 3: 待规则化 learnings ---" | tee -a "$LOG_FILE"
UNRULED=0
for L in .claude/memory/learnings/*.md; do
  NAME=$(basename "$L" .md)
  # 检查 rules/ 是否提到此 learning
  if ! grep -q "$NAME" .claude/rules/*.md 2>/dev/null; then
    TITLE=$(head -1 "$L" | sed 's/^# \[.*\] \[[^]]*\] //' | cut -c1-50)
    echo "  ⚠️ $NAME: $TITLE..." | tee -a "$LOG_FILE"
    UNRULED=$((UNRULED + 1))
  fi
done
echo "  待规则化数: $UNRULED" | tee -a "$LOG_FILE"

# 4. 写健康度报告
echo "" | tee -a "$LOG_FILE"
echo "--- Step 4: 健康度报告 ---" | tee -a "$LOG_FILE"
echo "  待规则化 learnings: $UNRULED" | tee -a "$LOG_FILE"
if [ "$UNRULED" -gt 0 ]; then
  echo "  ⚠️ 建议手动跑 /evolve" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "=== weekly-evolve 完成: $(date) ===" | tee -a "$LOG_FILE"
