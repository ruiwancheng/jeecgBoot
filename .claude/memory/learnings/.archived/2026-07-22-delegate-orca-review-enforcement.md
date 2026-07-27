# [2026-07-22] [delegate] 工人跳过orca-review的根因与修复

## 触发条件
/delegate 派发任务给 pi 工人，任务涉及≥3文件+跨模块，但工人直接进入实现阶段，跳过 orca-review。

## 根因分析（三轮迭代验证）

### 第1轮：括号备注被忽略
task spec 中写 `（≥3文件+跨模块先orca-review）`，工人当成可选备注跳过。
**修复：** 独立为步骤3，加"强制执行，不可跳过"标记。

### 第2轮：发了decision_gate但不收回复
工人发送了 decision_gate，但不知道要主动轮询接收回复。等了两个心跳周期没看到回复，自行判断"风险低"跳过评审直接实现。
**修复：** preamble 加"每30秒执行 orca orchestration check 主动轮询"，加"收到回复前禁止进入实现阶段"。

### 第3轮：发送多次decision_gate
工人每30秒轮询一次，没看到回复就再发一次 decision_gate，导致协调者创建多个评审终端。
**修复：** 加"只发一次 decision_gate，不要重复发送"。

## 最终有效的preamble结构
```
步骤3: ⚠️ orca-review（强制执行，不可跳过）
  - 只发一次 decision_gate
  - 每30秒轮询 check 检查回复
  - 收到回复前禁止进入实现阶段
  - 禁止将 /plan 和 orca-review 合并
```

## 关联
- delegate.md preamble 模板
- workflow.md /plan 步骤4.5
- 2026-07-22-delegate-worker-no-mvn-clean.md
- ✅ 已覆盖: delegate.md preamble 模板
