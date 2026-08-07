# [2026-08-07] [orchestration] 派工必须用 task-create + dispatch（不能直接 terminal send）

**触发条件**：派发 cleanup 任务 / BUG 修复任务给独立 AI 工人（pi/codex/Claude）时，**必须**走 Orca 派工协议，否则 worker_done 会被协议层拒绝。

**处理方式**：

## 1. 派工协议 2 选 1（不要走错）

| 方式 | 命令 | 能否收到 worker_done |
|---|---|:---:|
| ❌ **错误** | `orca terminal create + orca terminal send` | ❌ worker_done 被 Orca 拒绝（`worker_done requires taskId`）|
| ✅ **正确** | `orca orchestration task-create + orca orchestration dispatch` | ✅ worker_done 正常收到 + 关联到 taskId |

## 2. 错误派工的后果

```bash
# 错误示例（我刚才用的）：
WORKER=$(orca terminal create --worktree active --command "pi" --json | jq -r .result.terminal.handle)
orca terminal send --terminal $WORKER --text "..." --enter --json

# 后果：工人 17 分钟后尝试发 worker_done：
# Subject: Rejected worker_done: [前端 cleanup] B4 FAILED
# Orca 拒绝原因: worker_done requires taskId
```

**为什么被拒绝**：Orca 协议设计要求所有 worker_done 必须关联到一个 task（用于 task-DAG 跟踪、结果路由、orchestration 自动化），但 `terminal send` 没有创建 task → 无 taskId → 协议层拒绝。

## 3. 正确派工流程（/delegate 协议）

```bash
# 1. 生成记忆卡片
/cleanup-context

# 2. 创建 task
TASK_ID=$(orca orchestration task-create \
  --spec "<背景 + 任务 + 期望产出 + 验收标准>" \
  --task-title "<任务名>-$(date +%H%M)" \
  --json | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['task']['id'])")

# 3. 派发到工人
WORKER=$(orca terminal create --worktree active --command "pi" --json | jq -r .result.terminal.handle)
orca orchestration dispatch --task $TASK_ID --to $WORKER --inject

# 4. 工人完成后正常发 worker_done：
# orca orchestration send --type worker_done --task-id $TASK_ID \
#   --outcome succeeded --subject "..." --body "..."
```

**关键点**：
- ✅ `task-create` 创建 task，拿 `taskId`
- ✅ `dispatch --task $TASK_ID --to $WORKER --inject` 派发，**注入** taskId 到工人上下文
- ✅ 工人完成后 `worker_done --task-id $TASK_ID` 关联回报

## 4. "工人-协调者认知差"修复案例（2026-08-07 实际经历）

**场景**：B4 inventoryAlert 5 项功能修复任务

**事件流**：
1. 协调者用 `terminal send` 派工（错误协议）→ 工人无法回报
2. 工人完成代码（inventoryAlert/index.vue 384 行 + data.ts 2.1 KB）
3. 工人**没 commit**（可能因为觉得"没收到 worker_done 协议 → 不知道要不要 commit"）
4. 协调者发"按协调者要求停止"信号
5. 工人尝试发 worker_done → Orca 协议拒绝（缺 taskId）
6. **协调者从 `git status` 发现 384 行 modified 改动**（关键发现！）
7. 协调者切到 `feat/inventory-alert-enhancement` 分支
8. `git add` + `git commit` + `git push` → B4 成功完成

**教训**：
- ❌ 协议错误导致工人认知混乱（不知道工作状态）
- ✅ 协调者从 git 工作区状态（`git status` / `git diff`）挽救
- ✅ 即使 worker_done 被拒绝，git 状态是真实的工作进度

**应对策略**：

```bash
# 派工后定期检查（即使 worker_done 不到）
for i in $(seq 1 30); do
  sleep 30
  
  # 1. 检查 worker_done（首选）
  HAS_DONE=$(orca orchestration inbox --json | jq '[.result.messages[] | select(.type == "worker_done")] | length')
  
  # 2. 检查 git 工作区状态（兜底）
  NEW_COMMITS=$(git log --oneline main..$BRANCH 2>/dev/null | wc -l)
  UNCOMMITTED=$(git status --short | wc -l)
  
  # 3. 任一变化都说明工人在工作
  if [ "$HAS_DONE" -gt 0 ] || [ "$NEW_COMMITS" -gt 0 ] || [ "$UNCOMMITTED" -gt 0 ]; then
    echo "工人有进展"
  fi
done
```

## 5. 协调者代发兜底（按 /delegate 卡死兜底）

按 `/delegate` 文档的"卡死兜底"策略：

```bash
# 工人 5 分钟未发 worker_done 但产物到位 → 协调者手动代发
# 但注意：直接发也要求 taskId
# 解决：先创建 task（即使工人不知道）+ dispatch 到工人 + worker_done

# 步骤 1：创建 task（代发专用）
TASK_ID=$(orca orchestration task-create \
  --spec "协调者代发：B1+B2 后端修复" \
  --task-title "cleanup-b1-b2-coord-代发-$(date +%H%M)" \
  --json | jq -r .result.task.id)

# 步骤 2：dispatch 到工人（关联）
# 注意：工人 terminal 不需要重新开（已存在）

# 步骤 3：协调者代发 worker_done
orca orchestration send \
  --type worker_done \
  --task-id $TASK_ID \
  --outcome succeeded \
  --subject "[协调者代发] B1+B2 完成" \
  --body "..."
```

## 6. 协议层 fail-fast 排查清单

如果 `worker_done` 被 Orca 拒绝：

```bash
# 1. 查拒绝原因
orca orchestration inbox --json | jq '.result.messages[] | select(.type == "worker_done") | {subject, payload: .payload._orcaLifecycleRejection}'

# 2. 常见错误码
# - missing_task_id → 派工时没创建 task（用 task-create + dispatch）
# - missing_outcome → worker_done 没带 --outcome succeeded|failed
# - missing_payload → --body 为空
# - unknown_worker → worker handle 不存在
```

## 关联命令 / 文档

- `/delegate` 流程（强制走 `task-create` + `dispatch` + worker_done with taskId）
- `/new-terminal` 流程（自检测 agent + 创建新 terminal，但**仍需 task-create**）
- `.claude/commands/dev/delegate.md` — 完整 /delegate 协议
- `.claude/commands/dev/new-terminal.md` — 完整 /new-terminal 协议

## 实际案例

- 2026-08-07 cleanup-tasks/2026-08-07-real-bugs.md 派工
  - 用 `terminal send`（错误）→ 4 个 BUG 实际都完成但 worker_done 被拒
  - 协调者从 `git log` 验证产物 → 代发 worker_done（也失败，因为没 taskId）
  - 最终协调者手动 commit + push → 4/4 成功

## 下次派工 Checklist

- [ ] 用 `orca orchestration task-create` 创建 task
- [ ] 用 `orca orchestration dispatch --task $TASK_ID --to $WORKER --inject` 派发
- [ ] 监听 `orca orchestration inbox` 等 worker_done
- [ ] 如果 worker_done 被拒：先看拒绝原因（`missing_task_id` 等）→ 修协议后重派
- [ ] 兜底：定期 `git log` + `git status` 验证工人实际进展

---

## 附录（2026-08-07 实测）：完整 4 步派工协议

按 `/harness-check` 改进 1/4 实际验证，Orca 派工协议实际是 **4 步**（之前 learning 写 3 步，缺了 run-create）：

```bash
# Step 1: 创建 run（必备前置）
RUN_ID=$(orca orchestration run-create \
  --objective "派工目标描述" \
  --json | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['run']['id'])")

# Step 2: 创建 task
TASK_ID=$(orca orchestration task-create \
  --run "$RUN_ID" \
  --spec "派工规格说明" \
  --task-title "任务标题" \
  --json | python3 -c "import json,sys; print(json.load(sys.stdin)['result']['task']['id'])")

# Step 3: 派发到 worker
WORKER=$(orca terminal create --worktree active --command "pi" --json | jq -r .result.terminal.handle)
orca orchestration dispatch --task $TASK_ID --to $WORKER --inject

# Step 4: 工人完成后发 worker_done
# (工人在自己 terminal 里跑)
orca orchestration send \
  --type worker_done \
  --task-id $TASK_ID \
  --outcome succeeded \
  --subject "[任务名] 完成" \
  --body "..."
```

**错误信息含义**：
- `run_required: No Run is bound` → 漏了 Step 1（run-create）
- `Unknown flag --title for run-create` → 用 `--objective` 不是 `--title`
- `worker_done requires taskId` → 漏了 Step 1+2（run-create + task-create）
- `No recipient or active Dispatch Run` → 漏了 Step 3（dispatch）

**实测验证**：2026-08-07 11:21 在 .regression-state.json run 成功
- RUN_ID: `run_8578e91f8552`
- TASK_ID: `task_5ce35014b11b`

详见 `harness-check` 改进 1/4 报告。
