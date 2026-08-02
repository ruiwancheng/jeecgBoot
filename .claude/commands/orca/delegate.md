---
description: 自有命令 — 任务委派：在当前会话上下文膨胀时，一键生成记忆卡片 + 开新 pi 终端派发给干净上下文的工人（统一用 pi，不再按调用者自检测）
---

# /delegate <任务描述>

上下文膨胀时，委派任务给独立的 pi 工人终端。工人只携带压缩后的规则+状态，零历史负担。

> **agent 策略**：2026-08 起统一用 pi，**不再按调用者身份自检测**（Claude 调 Claude / pi 调 pi 的旧规则已废弃）。质量通过 orca-review 独立评审环节兜底，不靠选 agent。

## 流程

使用 `delegate` 技能获取：Orca CLI 命令、preamble 模板、agent 选择矩阵、强制校验清单、降级策略。

### 1. 生成记忆卡片

运行 `/cleanup-context` 生成记忆卡片。

### 2. 创建 pi 工人终端

统一使用 pi agent（不再区分任务类型）：

```bash
orca terminal create --command "pi" --json
```

### 3. 等待就绪 + 注入 preamble + 任务

调用技能中的 **preamble 模板**，传入记忆卡片和任务描述，注入工人终端。

### 4. 等待 worker_done 回报

监听工人终端的编排消息（heartbeat / decision_gate / worker_done）。

### 5. 强制校验（不可跳过）

按技能中的**强制校验清单**逐项检查（v4.0 10 步全流程）：
- 工作流阶段完整（0 切片 → 1 brainstorm → 2 plan → 3 orca-review → 4 实现 → 5 verify → 6 分级测试 → 7 收尾自检 → 8 commit+push → 9 /done → 10 worker_done）
- orca-review 由独立终端完成（非降级）
- 分级测试级别与变更影响面匹配（轻量/标准/全量）
- /quality-gate 等价自检全过（update-begin/end 对账、git diff 范围、推送前依赖）
- git commit + push 已执行（worker_done 含 commit hash）
- /done 完成检查清单已走完
- git diff 合理
- /verify 结果

任何异常立即报告用户，不默默放行。

### 6. 关闭工人终端

回报到达后自动关闭：按技能中的 Orca CLI 命令关闭终端。

### 7. 循环

下一任务重复步骤 2-6。

## 降级

按技能中的降级策略处理：Orca 不可用 → 退化为 `/cleanup-context`；无空闲槽位 → 提示用户释放终端。

## 使用示例

```
用户：/delegate 修复采购订单审核按钮报错问题
AI  ：📋 生成记忆卡片... ✅
      🚀 创建 pi 工人终端... term_xxx ✅
      📤 派发任务... dispatched ✅
      等待工人完成 → 回报 worker_done → 汇总结果
```
