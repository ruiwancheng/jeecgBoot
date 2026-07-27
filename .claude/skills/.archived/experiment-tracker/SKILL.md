---
name: experiment-tracker
description: 实验跟踪 — 管理质量改进实验（A/B测试、规则变更验证），衡量改进是否真正有效
version: 1.0.0
---

# 实验跟踪

基于 agency-agents 的 Experiment Tracker，验证质量改进措施是否真的降低了缺陷率。

## 实验设计模板

```json
{
  "id": "exp-<YYYYMMDD>-<slug>",
  "title": "实验标题",
  "hypothesis": "我们相信 <改动> 会带来 <预期效果>",
  "metric": "衡量指标",
  "baseline": { "value": 0, "period": "YYYY-MM-DD..YYYY-MM-DD" },
  "treatment": { "value": 0, "period": "YYYY-MM-DD..YYYY-MM-DD" },
  "confidence": 0.95,
  "status": "running|completed|inconclusive",
  "startDate": "YYYY-MM-DD",
  "endDate": "YYYY-MM-DD"
}
```

## 可实验的改进类型

| 改进类型 | 衡量指标 | 最小样本期 |
|----------|---------|:--:|
| 新增 gen-tests 规则 | 同类 Bug 复发次数 | 2 周 |
| 新增 hook 检查 | 提交被拦截次数 vs 漏过次数 | 4 周 |
| 调整质量门控阈值 | 门控 BLOCKED 率 vs 生产缺陷数 | 4 周 |
| 新增 code-style 规则 | 同类踩坑次数 | 2 周 |
| 修改工作流步骤 | 失忆点触发次数 | 1 周 |

## 统计显著性判定

- p < 0.05 → 改进有效，建议固化为规则
- 0.05 ≤ p < 0.10 → 趋势积极但不够显著，建议延长实验
- p ≥ 0.10 → 无显著差异，建议回退改动

## 实验注册表

存储在 `hermes/eagle-eye/experiments.json`

## 相关技能

- `quality-dashboard` — 仪表盘自动展示活跃实验
- `evolve` — 实验结论触发规则变更提案
