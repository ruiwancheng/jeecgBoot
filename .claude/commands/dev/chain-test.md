---
description: 自有命令 — 跨模块链路验证：Orca browser + curl 逐段验证业务链路是否贯通，断裂时人工门控判定
---

# /chain-test [链路名]

读 `hermes/business-chains.json`，逐段验证业务链路数据传递是否贯通。

## 用法

```
/chain-test                      # 基于 git diff 自动匹配链路的链路
/chain-test 采购链路               # 指定链路名称
/chain-test --all                # 验证所有已注册链路
```

## 流程

使用 `chain-test` 技能获取领域知识，按 5 步执行：

### 1. 上下文膨胀保护

参考 `human-gate` 技能。

### 2. 加载链路定义

读 `hermes/business-chains.json` → 匹配链路 → 加载 segments 和 criticalPaths。

### 3. 逐段验证

每段按技能中的验证步骤执行。

验证点：
- 数据 ID 匹配（上一步的输出 ID = 下一步的输入 ID）
- 数量一致（流转过程中数量不丢失）
- 状态正确流转（申请→审核→执行）

### 4. 汇总判定

每段通过/失败 → 整体链路状态：
- 🟢 全通 — 所有段数据传递正确
- 🟡 部分通 — 个别段异常
- 🔴 断裂 — 关键段数据传递失败

### 5. 人工门控（需要时）

🟡 或 🔴 时发 human-gate 等人判定：
- 代码 bug → 标记需修复
- 配置问题 → 标记配置缺失
- 链路定义不对 → 更新 business-chains.json
