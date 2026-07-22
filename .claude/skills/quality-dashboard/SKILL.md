---
name: quality-dashboard
description: 质量仪表盘 — 聚合所有质量数据源，输出统一的质量视图和发布就绪判断
version: 1.0.0
---

# 质量仪表盘

基于 agency-agents 的 Test Results Analyzer，聚合门控报告、测试结果、巡检数据，生成统一质量视图。

## 数据来源

| 数据源 | 路径 | 内容 |
|--------|------|------|
| 门控报告 | `hermes/eagle-eye/reports/YYYY-MM-DD/quality-gate-*.md` | 每次提交的质量门控判定 |
| 测试报告 | `hermes/eagle-eye/reports/YYYY-MM-DD/` | test-all/test-api 结果 |
| 巡检报告 | `hermes/eagle-eye/reports/YYYY-MM-DD/deep-inspect-*.md` | 深度巡检结果 |
| 实验注册 | `hermes/eagle-eye/experiments.json` | 活跃实验和特性开关 |
| 审计报告 | `hermes/tiequan/YYYY-MM-DD/<module>/` | 铁拳团审计发现 |
| 项目状态 | `.claude/memory/progress.md` | 当前工作流阶段 |

## 指标计算

### 测试通过率
```
API 通过率 = 通过的 API 测试 / 总 API 测试 × 100%
E2E 通过率 = 通过的 E2E 测试 / 总 E2E 测试 × 100%
```

### 缺陷密度
```
缺陷密度 = (P0×10 + P1×5 + P2×2 + P3×1) / 模块数
```

### 质量趋势
```
趋势方向 = 本周缺陷密度 vs 上周缺陷密度
↑ 改善（密度下降） → 保持（变化 < 10%） ↓ 恶化（密度上升）
```

### 发布就绪度
```
发布就绪 = (
  API 通过率 ≥ 95% (10分) +
  E2E 通过率 ≥ 90% (10分) +
  0 个 P0 缺陷 (30分) +
  ≤ 1 个 P1 缺陷 (20分) +
  深度巡检 ≤ 7 天 (15分) +
  安全扫描 0 个 CRITICAL (15分)
) / 100
≥ 85 分 → GO
70-84 分 → CONDITIONAL GO
< 70 分 → NO-GO
```

## 告警阈值

| 指标 | 阈值 | 等级 |
|------|:--:|:--:|
| API 通过率 < 90% | P2 |
| API 通过率 < 80% | P1 |
| E2E 通过率 < 80% | P1 |
| E2E 通过率 < 60% | P0 |
| 前端构建失败 | P0 |
| 连续 2 周趋势下降 | P0 |
| 深度巡检逾期 > 14 天 | P1 |
| 安全扫描有 CRITICAL | P0 |

## 仪表盘模板

```markdown
=== 质量仪表盘：<项目名> ===
生成时间：YYYY-MM-DD HH:MM | 范围：最近 7 天

📊 总览
  综合质量分：87/100 (↑ +3)
  发布就绪：CONDITIONAL GO（1 个 P1 待处理）

🧪 测试
  API：45/50 通过 (90%) [████████░]
  E2E：  8/10 通过 (80%) [████░░░░░]
  前端：构建 ✅ | TypeScript ✅

📈 趋势（近 4 周）
  W27: ████████ 85%
  W28: ████████ 88%
  W29: ████████ 84%  ← 下跌（E2E 不稳定测试）
  W30: █████████ 87%

🔍 深度巡检
  上次：2026-07-15（7 天前）
  性能：✅ 达标 | 视觉：⚠️ 1 个回归 | 无障碍：72/100

🧪 活跃实验
  [运行中] new-sales-form-redesign (第 5/14 天, p=0.03, B 组领先)

🐛 开放缺陷
  P0: 0 | P1: 1 | P2: 3 | P3: 5

🚨 升级建议
  [P1] E2E 不稳定测试：smoke-login 超时（最近 5 次中 3 次失败）
        建议：运行 /deep-inspect --focus=e2e-flakiness

📋 下一步
  1. 修复 P1 不稳定测试后再部署
  2. 深度巡检即将过期（剩余 0 天）— /deep-inspect
```

## 对接 agency-agents 代理

- `~/.claude/agents/testing-test-results-analyzer.md` — 统计分析、失败模式识别、发布就绪度评分

## 相关技能

- `test-all` — 趋势对比阈值（已对齐）
- `quality-gate` — 门控报告格式
- `deep-inspect` — 巡检报告格式
- `harness-check` — Harness 健康评分
