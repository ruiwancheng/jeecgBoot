# /delegate 派工 SOP（v5.0 强制流程）

> 背景：2026-08-07 9 个切片全部因 worker_done 缺 taskId 被 Orca 拒。  
> 根因：`terminal create + terminal send` 不走 orchestration 协议，工人无 taskId。  
> 本文档是**唯一正确的派工序列**，所有 /delegate 必须按此执行。

## ⚠️ 反模式（禁止）

```bash
# ❌ 错误：直接 create + send
orca terminal create --command "pi" --json
orca terminal send --terminal $HANDLE --text "<preamble>" --enter
# 工人完成时发 worker_done → Orca 拒（缺 taskId）
```

## ✅ 正确流程（v5.0）

```bash
# Step 1: 建 Run（如果还没有）
RUN_ID=$(orca orchestration run-create --objective "<任务描述>" --json | jq -r .result.run.id)

# Step 2: 建 Task（拿到 taskId）
TASK_ID=$(orca orchestration task-create \
  --spec "$(cat /tmp/memcard.txt)" \
  --task-title "<任务名>" \
  --run $RUN_ID \
  --json | jq -r .result.task.id)

# Step 3: 用 dispatch --inject（不是 terminal create + send）
orca orchestration dispatch \
  --task $TASK_ID \
  --to $WORKER_HANDLE \
  --inject
# 工人收到 taskId + dispatchId + Run 上下文，worker_done 可正确引用
```

## 工人端 worker_done（必须带 taskId）

```bash
orca orchestration send \
  --type worker_done \
  --task-id $TASK_ID \
  --dispatch-id $DISPATCH_ID \
  --to $COORDINATOR_HANDLE \
  --subject "[任务名] 完成" \
  --body "commit: <hash>
filesModified: <path1, path2>
verify: <mvn compile OK / curl 200 / test N/N pass>
risks: <P0/P1 列表，如无写 'none'>
phase: completed"
```

## 检测方法

```bash
# 验证派工走对流程
grep -rn "terminal send" harness/orchestration/ 2>/dev/null  # 应为空
grep -rn "dispatch --inject" harness/orchestration/ 2>/dev/null  # 应有
```

## 兜底：协调者代发 worker_done

如工人超时未发但产物到位：

```bash
# 协调者手动代发（不是脚本，是人工/Claude 代为补发）
orca orchestration send \
  --to <协调者 handle> \
  --type worker_done \
  --subject "[任务名] 协调者代发·产物到位" \
  --body "工人未发 worker_done，但产物已确认存在：<path>
关键结果：<从产物提取>"
```

## 关联

- learnings: `2026-08-07-orchestration-worker-done-taskid.md`
- learnings: `2026-08-07-orchestration-taskid-required.md`
- delegate SKILL.md: `.claude/skills/delegate/SKILL.md` v5.0
- 复盘: `2026-08-07-regression-report-messy-retro.md` R3
