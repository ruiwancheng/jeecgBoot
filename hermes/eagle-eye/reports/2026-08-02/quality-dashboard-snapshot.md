# 质量仪表盘快照 — 2026-08-02 15:35

> 这是 `/quality-dashboard` 的快照存档。生成时数据已全部就位（5/5 baseline），综合质量分 68/100，发布就绪 NO-GO。

**生成时间：** 2026-08-02 15:35 | **范围：** 最近 7 天（首跑基线） | **HEAD：** `d35ceda`

---

## 📊 总览

| 指标 | 数值 | 评级 |
|------|:--:|:--:|
| 综合质量分 | 68/100 | ⚠️ CONDITIONAL GO |
| 发布就绪度 | 60/100 | ❌ NO-GO |
| 数据完整度 | 5/5 (100%) | ✅ |
| 趋势方向 | — | 首跑基线 |

---

## 🧪 测试

| 类别 | 通过/总数 | 通过率 | 状态 |
|------|:--:|:--:|------|
| API 测试 | 9/12 | 75% | ⚠️ |
| E2E 测试 | 16/21 | 76% | ⚠️ |
| 前端 TypeScript | ❌ | — | Node 24 不兼容 |
| 前端 build | ✅ | — | — |

---

## 🔍 深度巡检（2026-08-02）

| 维度 | 状态 | 详情 |
|------|:--:|------|
| 性能 p95 | ✅ | 最大 29.554ms |
| 视觉证据 | ⚠️ DEFERRED | Playwright 不可用 |
| 无障碍 | ⚠️ DEFERRED | axe-core 不可用 |
| 总体 | ✅ PASS | 降级路径 |

---

## 🐛 开放缺陷

| 等级 | 数量 |
|------|:--:|
| P0 | 0 |
| P1 | 3 |
| P2 | 5 |
| P3 | 1 |

**缺陷密度：** (0×10 + 3×5 + 5×2 + 1×1) / 5 模块 = 5.2/模块

### P1 缺陷

1. API 测试 baseURL 不统一（7 本地 + 5 生产 + 2 可切换）
2. playwright.config.ts 自动加载失效（必须 --config 显式）
3. purchase-apply 状态机/接口 500

### P2 缺陷

1. basic.test.js DB 残留数据
2. other-stock-in costDiff 字段缺失
3. commonSetting JS 运行时错误
4. materialBatch locator 失效
5. purchaseReceiptBatch 编辑按钮选择器 x2

### P3 缺陷

1. Node 24 与 vue-tsc runner 不兼容

---

## 📈 趋势（首跑基线）

```
W27: 无数据
W28: 无数据
W29: 无数据
W30: ████████████░░░░░ 76%   ← 首跑基线
```

---

## 🎯 发布就绪度详细评分

| 检查项 | 阈值 | 当前 | 得分 |
|--------|------|:--:|:--:|
| API 通过率 ≥ 95% | 10 分 | 75% | 0 |
| E2E 通过率 ≥ 90% | 10 分 | 76% | 0 |
| 0 个 P0 缺陷 | 30 分 | 0 P0 | 30 ✅ |
| ≤ 1 个 P1 缺陷 | 20 分 | 3 P1 | 0 |
| 深度巡检 ≤ 7 天 | 15 分 | 今天 | 15 ✅ |
| 安全扫描 0 CRITICAL | 15 分 | 无 | 15 ✅ |
| **总分** | 100 分 | — | **60** ❌ |

**判定：** NO-GO（< 70 分）
**升级条件：** 修复 P1 后可升至 CONDITIONAL GO（80 分）

---

## 📁 数据源

| 来源 | 文件 | 时间 |
|------|------|:--:|
| 质量门控 | quality-gate-baseline.md | 2026-08-02 03:55 |
| 深度巡检 | deep-inspect-baseline.md | 2026-08-02 03:58 |
| test-all 总基线 | mes-test-report.md | 2026-08-02 15:22 |
| test-api 明细 | mes-test-api-baseline.md | 2026-08-02 15:30 |
| test-e2e 明细 | mes-test-e2e-baseline.md | 2026-08-02 15:33 |

**5/5 数据源已就位** ✅

---

## 🚨 升级建议

- [P1] 统一 API baseURL（用 process.env.HARNESS_BASE）
- [P1] 加 `--config e2e/playwright.config.ts` 到 harness/package.json
- [P1] purchase-apply 状态机/接口 500 排查（查后端日志）
- [P2] 修复 4 个 E2E 真实失败（commonSetting / materialBatch / purchaseReceiptBatch）
- [P2] 修复 3 个 API 真实失败（basic / other-stock-in / purchase-apply）
- [P3] 修复 Node 24 typecheck runner 兼容

---

## 📋 下一步

1. 修复 P1 后重跑 `/quality-gate`
2. 修复 E2E 真实失败后重跑 `/test-e2e mes`
3. 修复 API 真实失败后重跑 `/test-api mes`
4. 6 天后跑 `/deep-inspect`（巡检即将过期）
5. 启用 experiments.json（可选）

---

> 本快照是首跑基线，后续 `/quality-dashboard` 将以此为对比基准。