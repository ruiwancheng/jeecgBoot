---
name: deep-inspect
description: 深度巡检 — 定期执行性能基准测试、视觉证据采集和无障碍审计，输出趋势对比报告
version: 1.0.0
---

# 深度巡检

基于 agency-agents 的 Performance Benchmarker、Evidence Collector、Accessibility Auditor 三个代理角色，定期执行三类深度质量检查。

## 铁律

- **先建基线再做对比**：首次运行只建基线不输出结论，第二次开始才做趋势对比
- **截图即证据**：视觉检查不看代码看截图，Playwright 自动采集，拒绝"看起来没问题"
- **降级可用**：k6/Playwright 不可用时降级为 curl 计时 + 手动截图指引，不阻塞流程

## 三步巡检

### Step 1：性能基准（Performance Benchmarker）

**目标：**
- API 响应时间 p95 < 200ms（生产）/ < 2000ms（开发环境）
- 前端 LCP < 2.5s, FID < 100ms, CLS < 0.1
- 错误率 < 0.1%

**执行方式：**

1. 如果 k6 可用：
   - 从 `harness/tests/<module>/` 中提取 API 端点列表
   - 生成 k6 脚本：`hermes/eagle-eye/benchmarks/<module>-k6.js`
   - 运行：`k6 run --summary-export=<module>-summary.json`
   - 解析结果提取 p50/p95/p99/error_rate

2. 如果 k6 不可用（降级）：
   - 用 curl `-w` 参数对每个端点取 5 次采样
   - 计算平均值和 p95
   - 输出简单计时表格

**基线管理：**
- 存储路径：`hermes/eagle-eye/benchmarks/<module>-baseline.json`
- 格式：
```json
{
  "module": "<module>",
  "date": "YYYY-MM-DD",
  "api_endpoints": {
    "GET /xxx/list": {"p50_ms": 45, "p95_ms": 120, "error_rate": 0},
    "POST /xxx/add": {"p50_ms": 80, "p95_ms": 200, "error_rate": 0}
  },
  "frontend": {
    "lcp_ms": 1800, "fid_ms": 45, "cls": 0.05
  }
}
```

**趋势对比规则：**
- p95 增加 > 50% → P1 性能退化
- p95 增加 > 100% → P0 性能退化
- 错误率 > 1% → P1
- 错误率 > 5% → P0

### Step 2：视觉证据采集（Evidence Collector）

**目标：** 对模块的关键页面做自动截图，对比检测视觉回归。

**采集范围（每个模块）：**
- 列表页（含搜索区展开）
- 新增/编辑弹窗（表单完整呈现）
- 详情页（只读模式）
- 响应式：桌面（1920px）+ 平板（768px）+ 移动端（375px）

**执行方式：**

1. 如果 Playwright 可用：
   - 启动 `pnpm dev`（前端），后端指向 localhost:8080
   - 用 Playwright 导航到模块页面
   - 截图存储：`hermes/eagle-eye/evidence/<module>/YYYY-MM-DD/<page>-<viewport>.png`
   - 与上次截图做 pixel-diff 对比（如果上次存在）

2. 如果 Playwright 不可用（降级）：
   - 输出截图检查清单，列出每个页面和视口应检查的元素
   - 提示用户手动截图并放置在对应目录

**回归检测阈值：**
- 像素差异 > 5% → P1 视觉回归
- 像素差异 > 20% → P0 重大视觉回归
- 元素消失（上次有、本次无）→ P1

### Step 3：无障碍审计（Accessibility Auditor）

**目标：** WCAG 2.2 AA 级别合规检查。

**检查项（自动化部分）：**

| 检查项 | WCAG 标准 | 检测方式 |
|--------|----------|---------|
| 图片有无 alt 属性 | 1.1.1 | Playwright 扫描 `<img>` 标签 |
| 表单有无 label 关联 | 1.3.1 | 扫描 `<input>` 是否有 `id` 匹配 `<label for>` |
| 颜色对比度 | 1.4.3 | axe-core 自动检测 |
| 键盘可达性 | 2.1.1 | 检查 `tabindex` 是否符合规范 |
| 跳过导航链接 | 2.4.1 | 检查是否有 skip-link |
| 页面标题 | 2.4.2 | 检查 `<title>` 非空且有意义 |
| 语言声明 | 3.1.1 | 检查 `<html lang>` |

**检查项（需人工部分）：**
- 屏幕阅读器朗读验证 → 标记为"需人工验证"
- 键盘 Tab 顺序合理性 → 输出预期 Tab 顺序清单
- 焦点可见性 → 截图焦点状态

**严重度分级：**
- Critical：用户完全无法使用的障碍 → P0
- Serious：严重影响使用 → P1
- Moderate：影响体验 → P2
- Minor：改进建议 → P3

## 报告模板

```markdown
# 深度巡检报告：<模块名>
**时间：** YYYY-MM-DD HH:MM
**类型：** 首次基线 / 第 N 次对比

## 1. 性能基准
| 端点 | p50 | p95 | 错误率 | vs 基线 | 判定 |
|------|:---:|:---:|:--:|:--:|:--:|

性能退化：P0=N P1=N | 新退化：N 个

## 2. 视觉证据
| 页面 | 视口 | 截图 | 像素差异 | 判定 |
|------|:--:|:--:|:--:|:--:|

视觉回归：P0=N P1=N | 新回归：N 个

## 3. 无障碍审计
| 检查项 | WCAG | 严重度 | 状态 |
|--------|------|:--:|:--:|

合规率：N/N (XX%) | Critical=N Serious=N

## 综合判定
- 性能：✅ 达标 / ⚠️ 有退化 / 🚫 严重退化
- 视觉：✅ 无回归 / ⚠️ 有回归
- 无障碍：评分 X/100

下一步建议：...
```

## 对接 agency-agents 代理

- `~/.claude/agents/testing-performance-benchmarker.md` — k6 基准测试、Core Web Vitals、SLA
- `~/.claude/agents/testing-evidence-collector.md` — Playwright 截图、视觉对比
- `~/.claude/agents/testing-accessibility-auditor.md` — WCAG 2.2 AA、axe-core

## 相关技能

- `test-e2e` — Playwright 配置和测试模式
- `test-api` — API 端点发现
- `gen-tests` — 端点列表推导

## 相关规则

- `deep-inspect-schedule.md` — 巡检调度规则（频率、模块优先级）
- `quality-escalation.md` — 缺陷升级规则（巡检发现→P 级→修复时限）
