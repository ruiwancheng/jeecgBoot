---
name: quality-orchestrator
description: 质量协调 — 协调三层门控的升级、反馈和自进化闭环
version: 1.0.0
---

# 质量协调器

协调三层质量门控系统之间的信息流转和自进化。

## 三层协调

```
提交门控 → 深度巡检 → 仪表盘
  BLOCKED    发现退化    趋势恶化 → 收紧阈值
  PASS       记录基线    实验到期 → 规则进化
```

## 升级规则

| 情况 | 动作 |
|------|------|
| 门控连续 3 次 NEEDS WORK | 升级为 BLOCKED |
| 巡检发现 P0 退化 | 门控新增性能断言 |
| 仪表盘趋势连续 2 周下降 | 触发铁拳团审计 |
| P1 缺陷 7 天未修复 | 升级为 P0 |

## 自进化闭环

发现模式 → 实验验证 → 统计显著 → 固化为规则 → 仪表盘监控

## 相关技能

quality-gate, deep-inspect, quality-dashboard, experiment-tracker, evolve
