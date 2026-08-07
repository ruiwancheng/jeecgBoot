# /decompose + Orca 派工的工程化闭环

**日期**：2026-08-07
**上下文**：v3 孤儿行清理方案 6 阶段 25 子切片全部派工完成
**经验**：复杂方案（>20 文件 + 多模块 + 高风险）必须切片 + 派工 + 评审三段式

## TL;DR

对于高风险 / 多模块 / 大文件数的实施方案：

```
Plan v3 → 3 轮 Codex 评审 → 写 /decompose 切片 → 派 codex 实现 → 派 codex 评审 → 派 codex 修复 → 派 codex 复评审 → Release
```

**总用时**：约 2 小时（含 5 轮评审 + 6 轮派工）
**对比传统**：开发 + review + fix 约 2-3 个工作日

## /decompose 切片原则（实战）

### 切 6 个 slice 而非 12 个

| slice | 内容 | 文件数 | 用时 |
|---|---|---|---|
| 1 | UI 改造 | 3 | ~3min |
| 2 | 后端 3 端点 | 9 | ~10min |
| 3 | 守卫 19 checker | 22 | ~10min |
| 4 | 性能优化 | 5 | ~10min |
| 5 | 回归测试 | 6 | ~10min |
| 6 | 运维 Runbook | 2 | ~5min |

**原则**：每个 slice 控制在 5-15 分钟内能完成。太大 codex context 撑不住，太小编排开销占比高。

### 每个 slice 必须独立 verify

```bash
# 派工 prompt 模板（强制项）
- commit message 格式
- mvn compile / 静态检查命令
- git push 验证
- worker_done payload 格式
- 禁止修改的文件清单
```

### 评审轮次嵌入

每个 slice 完成后**立即派独立评审**，不要等所有 slice 完成再统一评审。

```
Slice N 派工 → 评审 → 修复 → 复评审 → 标记 done → Slice N+1
```

## Orca 派工闭环（实战）

### 4 步派工协议

```bash
# Step 1: 创建 run
RUN_ID=$(orca orchestration run-create --objective "..." --json | jq -r .result.run.id)

# Step 2: 创建 task
TASK_ID=$(orca orchestration task-create --run "$RUN_ID" \
  --spec "$(cat preamble.md)" \
  --task-title "..." --json | jq -r .result.task.id)

# Step 3: 派发
orca terminal send --terminal <codex_handle> \
  --text "$(cat preamble.md)" --enter

# Step 4: 协调者轮询（30s 间隔，看 git log + preview）
while sleep 30; do
  if git log --oneline -1 | grep "slice-N"; then
    break
  fi
done
```

### worker_done 协议约束（hard）

| 约束 | 说明 |
|---|---|
| 必须有 taskId | `worker_done requires taskId` |
| 必须有 dispatchId | `worker_done requires dispatchId` |
| 必须有 outcome | `worker_done requires outcome=succeeded\|failed` |
| 派工 dispatch 失败 | 即使实现完成也无法发 worker_done（fallback：协调者手动代发） |

### Orca runtime 间歇性故障的兜底

派工后 codex 完成后**常因 Orca runtime stale_bootstrap 无法发 worker_done**：
- 不要让 codex 反复重试（浪费 context）
- 让协调者**通过 git log + 文件产物**判定完成
- 手动发 degraded message-type 报告（含完整 review 内容）

## 状态文件设计

### `.claude/.decompose-state.json`（必备）

```json
{
  "task": "<主任务>",
  "created_at": "<ISO>",
  "updated_at": "<ISO>",
  "completed_at": "<ISO>",  // 全部 done 才填
  "agent": "codex",
  "worker_handle": "<codex>",
  "review_terminal": "<独立 review>",
  "status": "completed",
  "commits": [{"hash": "...", "slice": 1, "purpose": "..."}],
  "stats": {"total_slices": 6, "actual_commits": 8},
  "review_summary": {
    "v1_review_score": 7.5,
    "v2_review_score": 8.7,
    "v3_review_score": 9.2,
    "p0_bugs_found": 4, "p0_bugs_fixed": 4
  }
}
```

**关键**：`completed_at` 字段标记总任务完成。新会话启动时 `check-delegated-tasks.sh` 扫这个文件识别遗留任务。

## 不推荐做法

- ❌ 大切片（>30 文件，codex context 爆炸）
- ❌ 单阶段大爆炸（UI + 后端 + 守卫一次性派）
- ❌ 不派独立评审（让实现者自评无意义）
- ❌ 不写 decompose-state.json（跨 session 失去状态）
- ❌ 跳过 fix 验证（修复可能引入新 bug）
- ❌ 评审 + 派工用同一终端（context 偏见）
