<!-- update-begin---author:pi---date:2026-08-07---for:【REGRESSION-DOUBLE-REVIEW】新增回归测试双重复核命令，委派独立 AI 复核防止误判 -->
---
description: 自有命令 — 回归测试双重复核：跑完回归后，委派独立 AI（codex/Claude）复核 failed 切片，防止单源 AI 误判
---

# /regression-review [--run-dir <run-id>]

回归测试跑完后，**强制走双重复核流程**：
1. 业务人员口头复核（不懂技术）
2. 独立 AI 复核（codex 或 Claude）— **关键**：避免单源 AI 误判

> **为什么必要**：2026-08-07 回归复盘发现，单一 AI 复核有 30%+ 误判率（traceabilityBatch 7 条误判 + purchase-ledger 7 条 URL 错位 + basic-codeRule 导出按钮用例错误 + batch-ledger 5 条页面废弃）。**双源独立复核**可把误判率压到 <5%。

## 使用方法

```bash
/regression-review                            # 自动用最近一次 run-dir
/regression-review --run-dir 20260807-032053  # 显式指定（覆盖自动检测）
/regression-review --reviewer claude          # 用 Claude 复核（默认 codex）
/regression-review --reviewer codex --checklist frontend  # 限定复核 checklist
```

## run-dir 自动检测（v2 优化 2026-08-07）

> **2026-08-07 业务人员要求**：不要每次都让用户输入 run-dir，AI 自己记忆最近一次。

**检测优先级**：
1. **命令行参数 `--run-dir`** — 显式指定（最高优先级）
2. **状态文件 `.claude/.regression-state.json`** — 记录最近一次 run-dir
3. **目录最新 mtime** — `harness/.regression-runs/` 下最新目录
4. **报错退出** — 都找不到时提示用户

**自动检测脚本**（3 个新命令复用）：

```bash
# 检测 run-dir（4 级 fallback）
RESOLVE_RUN_DIR() {
  local EXPLICIT="$1"

  # 优先级 1：显式参数
  if [ -n "$EXPLICIT" ]; then
    echo "$EXPLICIT"
    return
  fi

  # 优先级 2：状态文件
  if [ -f ".claude/.regression-state.json" ]; then
    local STORED=$(python -c "import json; d=json.load(open('.claude/.regression-state.json')); print(d.get('last_run_dir',''))" 2>/dev/null)
    if [ -n "$STORED" ] && [ -d "harness/.regression-runs/$STORED" ]; then
      echo "$STORED"
      return
    fi
  fi

  # 优先级 3：目录最新 mtime
  if [ -d "harness/.regression-runs" ]; then
    local LATEST=$(ls -t harness/.regression-runs/ 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
      echo "$LATEST"
      return
    fi
  fi

  # 优先级 4：报错
  echo "ERROR: 无法确定 run-dir，请用 --run-dir <id> 显式指定" >&2
  exit 1
}

RUN_ID=$(RESOLVE_RUN_DIR "$1")
echo "[run-dir] $RUN_ID"
```

**状态文件 `.claude/.regression-state.json`**（首次跑回归时由 `/test-regression` 自动写入）：

```json
{
  "last_run_dir": "20260807-032053",
  "last_run_at": "2026-08-07T03:20:53+08:00",
  "scope": "full",
  "slice_count": 33,
  "failed_count": 8,
  "next_step": "regression-review",
  "updated_at": "2026-08-07T05:30:00+08:00"
}
```

**状态文件自动更新时机**：
- `/test-regression` 跑完 → 写入 `last_run_dir`
- `/regression-review` 开始 → 检查 `last_run_dir` 与命令参数是否一致
- `/regression-retro` 完成后 → 更新 `next_step = "regression-decompose"`
- `/regression-decompose` 完成后 → 更新 `next_step = "completed"` 或下一个 run-dir

**强制更新脚本**（跑完任一命令后调用）：

```bash
UPDATE_STATE() {
  local RUN_ID="$1"
  local NEXT_STEP="$2"
  local FAILED_COUNT="${3:-0}"
  local SCOPE="${4:-full}"

  if [ -n "$RUN_ID" ]; then
    python -c "
import json, datetime
state_file = '.claude/.regression-state.json'
try:
    state = json.load(open(state_file, encoding='utf-8'))
except (FileNotFoundError, json.JSONDecodeError):
    state = {}

state['last_run_dir'] = '$RUN_ID'
state['last_run_at'] = '$SCOPE'  # 留作 run 时记录
state['next_step'] = '$NEXT_STEP'
state['failed_count'] = $FAILED_COUNT
state['updated_at'] = datetime.datetime.now().isoformat()

with open(state_file, 'w', encoding='utf-8') as f:
    json.dump(state, f, indent=2, ensure_ascii=False)
print(f'[state] updated: {state_file} → run_dir={state[\"last_run_dir\"]} next_step={state[\"next_step\"]}')
"
  fi
}

# 用法
UPDATE_STATE "$RUN_ID" "regression-retro" 8
```

## 必须加载

1. `.claude/skills/regression-review/SKILL.md`（如有）
2. 当前回归报告：`harness/.regression-runs/<run-id>/regression-report.md`（路径由 `RESOLVE_RUN_DIR` 解析）
3. 原始日志：`harness/.regression-runs/<run-id>/logs/<slice-id>.attempt-1.log`
4. 复核证据目录：`hermes/eagle-eye/reports/<date>/issues/`

## 工作流（5 步）

### 0. 解析 run-dir（自动）

```bash
# v2 优化：4 级 fallback 自动检测
RUN_ID=$(RESOLVE_RUN_DIR "$1")  # "$1" 是 --run-dir 参数值（可空）
echo "[run-dir] $RUN_ID"
```

### 1. 解析报告 + 抽取 failed 切片

```bash
# 解析 failed 切片（4.X 标题）
grep -E "^### 4\." harness/.regression-runs/$RUN_ID/regression-report.md

# 抽取每条 failed 切片的：测试位置 + 关键错误 + 实际结果
grep -A 10 "测试位置：" harness/.regression-runs/$RUN_ID/regression-report.md | head -50
```

输出 failed 切片清单（按 4.X 顺序）：

| 切片 | 测试位置 | 关键错误 | 失败测试数 |
|---|---|---|---|

### 2. 委派独立 AI 复核（用 orca-review 机制）

**不要自己复核** — 用 `/delegate` 委派给干净上下文的独立 AI 工人。

```bash
# 1. 生成记忆卡片（避免上下文膨胀）
/cleanup-context

# 2. 创建独立 AI 工人（codex 或 Claude）
orca terminal create --command "codex" --json  # 或 --command "claude"
WORKER=$(...)

# 3. 派发复核任务
TASK_ID=$(orca orchestration task-create \
  --spec "$(cat <<EOF
请对以下 failed 切片做独立复核（不要相信 AI 初判）：

报告路径：harness/.regression-runs/$RUN_ID/regression-report.md
原始日志：harness/.regression-runs/$RUN_ID/logs/

Failed 切片清单：
$(grep -E "^### 4\." harness/.regression-runs/$RUN_ID/regression-report.md)

每条切片需判断：
1. 是否真实 BUG（前端/后端真实问题）
2. 是否误判（报告生成器误归类 / 测试用例错误 / 业务页面废弃 / fixture 错位）
3. 严重度 P0/P1/P2/P3
4. 跟进负责人

输出结构化 JSON：
{
  "slices": [
    {
      "id": "4.1",
      "verdict": "real_bug|false_positive",
      "severity": "P0|P1|P2|P3",
      "reason": "...",
      "owner": "...",
      "evidence": "..."
    }
  ]
}
EOF
)" \
  --task-title "review-regression-$RUN_ID-$(date +%H%M)" \
  --json | python -c "import json,sys; print(json.load(sys.stdin)['result']['task']['id'])")

# 4. 派发
orca orchestration dispatch --task $TASK_ID --to $WORKER --inject

# 5. 等待 worker_done
# （轮询脚本见 /delegate 文档）
```

### 3. 合并双源复核结果

拿到独立 AI 的复核结果后：

| 来源 | 判定 | 严重度 | 原因 |
|---|---|---|---|
| AI 初判 | ... | ... | ... |
| 独立 AI 复核 | ... | ... | ... |
| 业务人员复核 | ... | ... | ... |
| **最终判定** | 一致→采用；冲突→业务人员优先 | | |

**冲突处理规则**：
- 业务人员 + 独立 AI 一致 → 直接采用
- 业务人员 + 独立 AI 不一致 → 走 `/orca-review` 二次评审
- AI 初判与独立 AI 不一致 → 取独立 AI 判定（独立 AI 上文更干净）

### 4. 用 edit 工具填入报告

按已合并的最终判定，用 edit 工具把每条 4.X 的「复核结果」section 覆盖：

```markdown
> 📋 **复核结果**：✅/⏳ **<判定>** | 严重度 <P> | <原因> | 跟进：<负责人> | 复核人 <业务人员+独立AI worker> / <时间>
```

### 5. 更新状态文件

```bash
# 复核完成 → next_step = regression-retro
UPDATE_STATE "$RUN_ID" "regression-retro" "$FAILED_COUNT"
```

## 禁止事项

- 不要跳过独立 AI 复核（即使是"小切片"）
- 不要用同一个 AI agent 委派（必须独立 agent + 干净上下文）
- 不要把 worker 委派给"我自己"（即发到当前 handle）
- 不要在委派 worker 中再次让 worker 委派（避免递归派工）
- 不要让 worker 改业务代码（只能产出复核结果）

## 验证清单（必走）

- [ ] 所有 failed 切片都有独立 AI 复核意见
- [ ] 业务人员复核意见 + 独立 AI 复核意见都被记录
- [ ] 冲突切片已二次评审
- [ ] 报告「复核结果」section 已用最终判定覆盖
- [ ] 真实 BUG 已进 issue tracker / 误判已归档

## 关联命令

- `/test-regression` — 跑回归测试（会自动写状态文件）
- `/regression-retro` — 误判复盘（避免后续踩坑，自动检测 run-dir）
- `/regression-decompose` — 真实 BUG 切片处理（自动检测 run-dir）
- `/delegate` — 委派任务给独立 AI
- `/orca-review` — 冲突时二次评审
- `/cleanup-context` — 委派前生成记忆卡片

## 参考

- 起源：2026-08-07 回归复盘，单源 AI 复核有 30%+ 误判率
- 详细误判清单：`harness/.regression-runs/20260807-032053/regression-report.md` 第四节
- 误判复盘流程：`/regression-retro`
<!-- update-end---author:pi---date:2026-08-07---for:【REGRESSION-DOUBLE-REVIEW】 -->
