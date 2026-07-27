---
description: 自有命令 — 自愈测试循环：测试失败 → 自动 debug → 修复 → 重跑 → 人工确认闭环
---

# /test-loop <测试文件路径>

测试失败后自动 debug 修复闭环。最多 3 轮，修复后人工确认。

## 用法

```
/test-loop harness/tests/mes/purchase.test.js   # 指定测试文件
/test-loop                                       # 自动找最近失败的测试
```

## 流程

使用 `test-loop` 技能获取领域知识，按 5 步执行：

### 1. 上下文膨胀保护

参考 `human-gate` 技能。

### 2. 提取失败信息

运行测试 → 收集：
- 失败用例名称
- 报错信息和堆栈
- 涉及的文件路径（从堆栈提取）

### 3. Orca dispatch debug agent

派发到独立 agent 做 root cause 分析 + 修复：
- 注入错误上下文（测试名称、报错信息、堆栈）
- debug agent 读源码 → 定位根因
- **只修源码，不修测试代码**
- 最多 3 轮

### 4. 重跑验证

修复后重新运行测试。

### 5. 人工门控

修复成功 → 按 `human-gate` 技能发 decision_gate：
- 展示 git diff
- 展示测试通过结果
- 等待人工确认后提交
