# orca 派工代发 worker_done 在 v5.5+ 不可用（需 taskId/active Dispatch）

**触发条件：** 协调者尝试代发 `worker_done` 类型消息给非 active Dispatch 的协调者 handle 时。

**问题（v5.5+ 实测）：**

```bash
# 协调者侧尝试代发 worker_done
orca orchestration send \
  --to term_<协调者> \
  --type worker_done \
  --outcome succeeded \
  --subject "[task] 协调者代发" \
  --body "..."

# 返回错误：
# Rejected msg_<id>: worker_done requires taskId.
```

**根因：** orca v5.5+ 的 `worker_done` 是 **exact-Dispatch 信号**，必须绑定到一个 active Dispatch（来自 `orca orchestration task-create` + `dispatch`）。当前会话如果没有 active Dispatch 上下文，协调者 handle 不在 Run mailbox 里，worker_done 被直接拒绝。

**降级方案（v5.5+ 验证有效）：**

```bash
# 改用普通消息（不带 --type worker_done）
orca orchestration send \
  --to term_<协调者> \
  --subject "[task-id] 协调者代发·<原因>" \
  --body "工人未发 worker_done，但产物已确认存在：
  - T1 commit: <hash>
  - T2 commit: <hash>
  - 诊断报告: <path>
  phase: completed"
# 返回：Sent msg_<id>
```

**关键认知：**

- v4.0 及之前的 `worker_done` 模板（任意 send）已**部分失效**
- v5.5+ 要求 `worker_done` 必须有 `--task-id` 或 `--dispatch-id`（来自 active Dispatch 上下文）
- 协调者侧代发场景下，**没有 active Dispatch 绑定** → 必须用普通消息替代

**代发触发条件**（协调者侧）：
1. 工人 5+ 分钟无 worker_done + 产物到位
2. 协调者无法恢复 active Dispatch 上下文（工人用的 task/dispatch 协调者无引用）
3. 用户已决策"派工完成"（基于 git log 兜底 + 产物路径校验）

**实证：** 2026-08-07 fixup 任务 T1-T4 完成时：
- `git log --oneline -7` 显示 6 个 commit + 诊断报告落盘
- 工人 terminal preview 显示完成但未发 worker_done
- 尝试代发 worker_done → rejected (requires taskId)
- 改用普通消息 → Sent msg_f5e14baea290 ✓

**与 v4.0 沉淀的差异：**

v4.0（2026-08-02）协调者代发兑底机制已成功使用过——但当时 orca 版本允许无 taskId 发送。v5.5+ 收紧后必须用普通消息类型。

**完整派工 v5+ 检查清单：**

1. 派工时记录 `--task-id` / `--dispatch-id` 到状态文件（`.remember/state/delegated-tasks.json`）
2. 协调者代发场景：先尝试带 taskId 的 send → 失败时降级为普通消息
3. 普通消息必须明确标注"协调者代发"+ 原因（工人未发）
5. 普通消息 body 含完整 commit hash + 产物路径，便于协调者兜底判完成