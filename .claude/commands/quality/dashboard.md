---
description: 自有命令 — 质量仪表盘：聚合所有质量数据，输出统一质量视图和发布就绪判断
---

# /quality-dashboard

聚合门控报告、测试结果、巡检数据，生成统一质量视图。

## 流程

### 1. 加载领域知识

使用 `quality-dashboard` 技能获取指标计算公式和告警阈值。

### 2. 收集数据

从以下来源聚合：
- `hermes/eagle-eye/reports/` — 门控和测试报告
- `hermes/tiequan/` — 审计发现
- `hermes/eagle-eye/experiments.json` — 活跃实验

### 3. 计算指标

- 测试通过率（API + E2E）
- 缺陷密度（P0-P3 加权）
- 趋势方向（vs 上周）
- 发布就绪度评分（0-100）

### 4. 渲染仪表盘

按 `quality-dashboard` 技能中的模板输出 ASCII 仪表盘。

## 参数

- `<模块名>` — 可选，默认当前活跃项目
- `--range 7d|30d` — 可选，默认 7 天
