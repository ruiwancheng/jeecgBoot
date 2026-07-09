---
description: 自有命令 — 会话收尾：总结→提取经验→健康检查→建议进化
---

# /session-wrap

会话收尾，自动串联 learn / harness-check。

## 流程

### 1. 加载领域知识
使用 `session-wrap` 技能获取：信号检查阈值、progress.md 更新格式、手工操作提示格式。

### 2. 总结工作
本次做了什么。

### 3. 自动 /learn
提取经验写入 learnings/。

### 4. 自动 /harness-check
6 轴评分，和上次对比趋势。

### 5. 信号检查
按技能中的阈值检查：重复操作 → 建议新Command、重复错误 → 建议新Rule、learnings 累积 ≥3 → 建议 /evolve。

### 6. 更新 progress.md
按技能中的格式更新。

### 7. 手工操作提示
列出需要用户处理的事项。

### 8. 输出摘要
