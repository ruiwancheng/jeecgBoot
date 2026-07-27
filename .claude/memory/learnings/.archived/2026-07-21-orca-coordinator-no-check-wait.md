# [2026-07-21] [协同] pi 协调者禁止 check --wait——终端界面会截胡编排邮件

## 触发条件
pi 作为 Orca 编排协调者，用 `orca orchestration check --wait` 阻塞等待 worker_done。

## 现象
工人实际已完成并回报，但 `check --wait` 显示"无消息/超时"，表现为"卡住"。用户却能在 pi 终端界面看到回报消息。

## 根因
pi 终端界面（TUI）会**自动把编排邮件投递进会话并标记已读**。CLI 的 `check --wait` 查询的是"未读消息"，邮件已被界面消费 → 必然查空。

## 正确等待策略（pi 协调者）
1. **主通道：界面自动投递** — 派发后正常等待，worker_done 会作为会话消息自动出现
2. **兜底确认：轮询工单状态** — `orca orchestration dispatch-show --task <id>` 查 `status=completed`，或检查产出文件是否落盘。这两者不消耗消息，永远可靠
3. 单工人超时（如 10 分钟无动静）→ 标记失败继续，不阻塞整体

## 其他编排实战要点（同日验证）
- 派发必须用完整终端 handle，缩写会失败
- 新工人终端 1 次启动失败即换 Agent，不要反复重试
- Hermes Agent 作为工人链路不稳定（子代理卡跑），暂用 pi/Claude Code
- 同目录多工人仅限只读任务；改代码必须隔离工作树

**关联：** hermes/tiequan/2026-07-21/sales-order-items（首个真并行审计）
## 关联
- ✅ 已覆盖: delegate.md orca-review轮询check指令
