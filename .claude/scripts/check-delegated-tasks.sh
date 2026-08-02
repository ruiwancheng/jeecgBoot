#!/bin/bash
# update-begin---author:pi---date:2026-08-03---for:【协调者任务扫描】session-start 检查未完成任务的 worker_done---
# 2026-08-03 集成: Claude Code session-start.sh 调一次
# 2026-08-03 设计: PRIMARY/SECONDARY 翻转 + 三取二判定 + baseline 自愈
#   PRIMARY: git log 匹配（不可丢失）
#   SECONDARY: inbox keyword + sequence 匹配
#   FALLBACK: output_paths 产物存在
#   判定 >= 2 -> completed；== 1 -> suspected；== 0 -> in_progress
#
# 用法: bash check-delegated-tasks.sh
# 输出: stdout 一行摘要（进 system-reminder），详细 JSON 写 .remember/state/delegated-scan-*.json

set -e

PYTHON=$(command -v python3 || command -v python || echo python)
$PYTHON --version >/dev/null 2>&1 || PYTHON=$(command -v python || echo python)
# 2026-08-03 修复: WindowsApps 的 python3 可能是商店占位 stub（session-start.sh 已有同坑修复）
# 必须实测可用性，不能只看 command -v
if ! $PYTHON --version >/dev/null 2>&1; then
  PYTHON=$(command -v python || echo python)
  $PYTHON --version >/dev/null 2>&1 || { echo "[ERR] no usable python"; exit 1; }
fi
export PYTHONIOENCODING=utf-8

STATE_FILE=".remember/state/delegated-tasks.json"
INBOX_LIMIT=${INBOX_LIMIT:-100}
REPORT_FILE=".remember/state/delegated-scan-$(date +%Y%m%d-%H%M%S).json"

# 1. 状态文件不存在 -> 直接退出
if [ ! -f "$STATE_FILE" ]; then
  echo "[OK] delegated tasks: 0 to scan"
  exit 0
fi

# 2. 拉 inbox（允许失败）写临时文件避免参数过长
INBOX_FILE=".remember/state/.inbox-snapshot.json"
INBOX_JSON='{"result":{"messages":[]}}'
if command -v orca >/dev/null 2>&1; then
  RAW=$(orca orchestration inbox --limit $INBOX_LIMIT --json 2>/dev/null || echo '')
  if [ -n "$RAW" ] && echo "$RAW" | $PYTHON -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
    INBOX_JSON="$RAW"
  fi
fi
mkdir -p "$(dirname "$INBOX_FILE")"
printf '%s' "$INBOX_JSON" > "$INBOX_FILE"

# 3. 跑 Python 评估
$PYTHON - "$INBOX_FILE" "$REPORT_FILE" <<'PYEOF'
import json
import os
import subprocess
import sys
from datetime import datetime, timezone

inbox_path = sys.argv[1]
report_file = sys.argv[2]

state_path = ".remember/state/delegated-tasks.json"
state = json.load(open(state_path, encoding="utf-8"))

try:
    inbox = json.load(open(inbox_path, encoding="utf-8"))
except (json.JSONDecodeError, OSError):
    inbox = {"result": {"messages": []}}

# inbox baseline
seqs = [m.get("sequence", 0) for m in inbox.get("result", {}).get("messages", []) if isinstance(m, dict)]
inbox_min_seq = min(seqs) if seqs else 0

results = []
for task in state["tasks"]:
    if task.get("status") != "dispatched":
        continue

    task_id = task["id"]
    rules = task.get("match_rules", {})
    subject_prefix = rules.get("subject_prefix", "")
    body_keywords = rules.get("body_keywords", [])

    # PRIMARY: git log 匹配
    git_signal = False
    git_evidence = []
    for f in task.get("expected_files", []):
        try:
            log = subprocess.check_output(
                ["git", "log", "--oneline", "-10", "--", f],
                text=True, stderr=subprocess.DEVNULL,
                encoding="utf-8", errors="replace"
            )
            commits = [line.split()[0] for line in log.splitlines() if line.strip()]
            if commits:
                git_signal = True
                git_evidence.append({"file": f, "commits": commits[:3]})
        except subprocess.CalledProcessError:
            pass

    # SECONDARY: inbox 匹配
    inbox_signal = False
    inbox_evidence = []
    for m in inbox.get("result", {}).get("messages", []):
        if not isinstance(m, dict) or m.get("type") != "worker_done":
            continue
        subject = m.get("subject", "")
        body = m.get("body", "")
        matched = False
        if subject_prefix and subject.startswith(subject_prefix):
            matched = True
        if any(kw in subject + body for kw in body_keywords):
            matched = True
        if matched:
            inbox_signal = True
            inbox_evidence.append({
                "sequence": m.get("sequence"),
                "subject": subject[:60],
                "created_at": m.get("created_at"),
                "from_handle": m.get("from_handle", "")[:30],
                "to_handle": m.get("to_handle", "")[:30],
            })

    # FALLBACK: output_paths 产物存在
    output_signal = False
    output_evidence = []
    for p in task.get("output_paths", []):
        if os.path.exists(p):
            output_signal = True
            output_evidence.append(p)

    # 三取二判定
    score = sum([git_signal, inbox_signal, output_signal])
    if score >= 2:
        verdict = "completed"
    elif score == 1:
        verdict = "suspected"
    else:
        verdict = "in_progress"

    # baseline 自愈
    baseline_lost = task["last_seq"] > 0 and task["last_seq"] < inbox_min_seq

    results.append({
        "task_id": task_id,
        "task_title": task["task_title"],
        "score": score,
        "verdict": verdict,
        "baseline_lost": baseline_lost,
        "signals": {
            "git_log": {"match": git_signal, "evidence": git_evidence},
            "inbox": {"match": inbox_signal, "evidence": inbox_evidence},
            "output_files": {"match": output_signal, "evidence": output_evidence},
        },
    })

# 写详细报告
report = {
    "scanned_at": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
    "inbox_min_seq": inbox_min_seq,
    "results": results,
}
with open(report_file, "w", encoding="utf-8") as f:
    json.dump(report, f, ensure_ascii=False, indent=2)

# stdout 一行摘要（进 system-reminder）
if not results:
    print("[OK] delegated tasks: 0 to scan")
    sys.exit(0)

completed = [r for r in results if r["verdict"] == "completed"]
suspected = [r for r in results if r["verdict"] == "suspected"]
in_progress = [r for r in results if r["verdict"] == "in_progress"]

parts = []
parts.append(f"[INFO] delegated scan: {len(completed)} done / {len(suspected)} suspect / {len(in_progress)} in-progress")

if completed:
    items = ", ".join([
        f"{r['task_id']}(git={'+' if r['signals']['git_log']['match'] else '-'} inbox={'+' if r['signals']['inbox']['match'] else '-'} out={'+' if r['signals']['output_files']['match'] else '-'})"
        for r in completed
    ])
    parts.append(f"completed: {items}")

if suspected:
    items = ", ".join([
        f"{r['task_id']}(only-{[k for k,v in r['signals'].items() if v['match']][0]})"
        for r in suspected
    ])
    parts.append(f"suspected: {items}")

if in_progress:
    items = ", ".join([r["task_id"] for r in in_progress])
    parts.append(f"in-progress: {items}")

parts.append(f"details: {report_file}")
print(" | ".join(parts))
PYEOF
# update-end---author:pi---date:2026-08-03---for:【协调者任务扫描】session-start 检查未完成任务的 worker_done---
