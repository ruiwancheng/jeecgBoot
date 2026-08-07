# /delegate worker_done 被 Orca 拒（缺 taskId）— 必须走 dispatch 流程 (2026-08-07)

## 现象

`/delegate` 派 pi 工人完成 7 个切片后，**所有 7 条 worker_done 都被 Orca 拒**：

```
Orca rejected this worker_done: worker_done requires taskId.
```

但实际工作（commit、push）都完成。导致 inbox 全是 LEGACY READ-ONLY 拒绝消息，污染协调者视图。

## 根因

派工时只用了：
```bash
orca terminal create --command "pi" --json
orca terminal send --terminal $HANDLE --text "<preamble>" --enter
```

**没有用 `orca orchestration task-create` + `dispatch --inject`** 走正式 orchestration 流程，所以工人终端没有 taskId，worker_done 无法引用。

## 正确派工流程（v5.0 对齐）

### ❌ 错误（我之前用的）
```bash
orca terminal create --command "pi" --json
orca terminal send --terminal $HANDLE --text "<preamble>" --enter
# 工人完成时发 worker_done → Orca 拒（缺 taskId）
```

### ✅ 正确
```bash
# 1. 建 Run（如果还没有）
RUN_ID=$(orca orchestration run-create --objective "..." --json | jq -r .result.run.id)

# 2. 建 Task（拿到 taskId）
TASK_ID=$(orca orchestration task-create \
  --spec "<preamble>" \
  --task-title "<task-name>" \
  --run $RUN_ID \
  --json | jq -r .result.task.id)

# 3. 用 dispatch --inject（不是 terminal create + send）
orca orchestration dispatch \
  --task $TASK_ID \
  --to $HANDLE \
  --inject
# 工人收到 taskId + dispatchId + Run 上下文，worker_done 可正确引用
```

### 工人端 worker_done（拿到 taskId 后）
```bash
orca orchestration send \
  --type worker_done \
  --task-id $TASK_ID \
  --dispatch-id $DISPATCH_ID \
  --to $COORDINATOR_HANDLE \
  --subject "[任务名] 完成" \
  --body "commit: <hash>
filesModified: ...
verify: ...
phase: completed"
```

## 触发条件

- 任何 `orca terminal create` 后 `terminal send` 的派工（缺 orchestration 上下文）
- 任何想让 worker_done 验证通过的派工

## 错误 vs 正确对照

| 步骤 | 错误 | 正确 |
|------|------|------|
| 派工 | `terminal create + terminal send` | `run-create + task-create + dispatch --inject` |
| worker_done payload | `{}` 或只含 outcome | 必须含 `taskId` + `dispatchId` |
| 协调者识别 | LEGACY READ-ONLY 拒绝消息 | 正常 worker_done 标记完成 |

## 检测方法

1. 看 inbox 中 worker_done 消息的 `_orcaLifecycleRejection.code`：
   - `missing_task_id` → 没走 dispatch
   - `unknown_task` → taskId 拼错
2. 看 worker 终端是否在 `dispatch --inject` 列表里：
   ```bash
   orca orchestration dispatch-list --json
   ```
3. 看 worker 收到 preamble 时是否带 orchestration 上下文（preamble 末尾应含 taskId + dispatchId + Run handle）

## 影响面

本次 7 切片全部受影响（slice-1/2/3/4/5/6/7）。所有 commit 都落地，但协调者无法自动识别完成状态，需手动对照 git log。

## 修复要点（下次 /delegate 必走）

1. **派工前 30 秒 checklist 加一项**：
   - [ ] 已 `run-create` + `task-create` + `dispatch --inject`（不只是 terminal create）

2. **preamble 末尾嵌入完整 worker_done 命令模板**（含 taskId/dispatchId 占位符）：
   ```bash
   orca orchestration send \
     --type worker_done \
     --task-id <自动注入> \
     --dispatch-id <自动注入> \
     --to <协调者handle> \
     --subject "..." \
     --body "..."
   ```

3. **降级兑底**（若仍被拒）：
   - 协调者代发 worker_done（v4 fallback）
   - 或对照 git log 手动验证（本次采用）

## 关联

- delegate SKILL.md v5.0：派工前 checklist
- orchestration skill：run/task/dispatch 三段式
- delegate 命令 2026-08-02 v5 优化（坑 2：orca-review 不要让 worker 发）

## 关联 commit（本次已落地但 worker_done 被拒）

| Slice | Commit | worker_done 状态 |
|---|---|---|
| slice-1 | 6c623e6 | rejected (missing_task_id) |
| slice-2 | 9d07385 | rejected (missing_task_id) |
| slice-3 | 45a5d40 | rejected (unknown_task) |
| slice-4 | 3b5f7fc | rejected (missing_task_id) |
| slice-5 | 8bf364a | rejected (missing_task_id) |
| slice-6 | a07ec59 | rejected (missing_task_id) |
| slice-7 | 0d386fc | rejected (missing_task_id) |

→ **协调者代发兑底**：本批次对照 git log 验证 + 状态文件更新，不依赖 worker_done