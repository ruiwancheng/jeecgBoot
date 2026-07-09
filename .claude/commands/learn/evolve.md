---
description: 自有命令 — 自主进化：读取 /learn 累积+ /harness-check 评分，生成改进确认后落地
---

# /evolve

Harness 自主进化。**输入：/learn 累积 + /harness-check 评分。**

## 流程

### 1. 读取输入
- `memory/learnings/` — /learn 累积的经验
- `/harness-check` 评分 — 低分项

### 2. 分析
- 经验 → 对应规则有？没有→补。冲突→更新
- 低分项 → 针对性改进

### 3. 输出清单（逐项确认）
```
1. [高] xxx → 改 xxx.md
2. [中] xxx → 删 xxx
确认: 1,2 / all / none
```

### 4. 执行
确认的落地，改完验证。
