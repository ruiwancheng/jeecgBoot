<!-- update-begin---author:pi---date:2026-08-06---for:【EAGLE-EYE-REPORT】新增报告生成命令（0804 Sprint Review 风格模板）-->
---
description: 自有命令 — 基于最新（或指定）回归 run 生成详细分析报告（0804 Sprint Review 风格）
---

# /eagle-eye-report [run-id]

## 用法

```bash
/eagle-eye-report                       # 默认最新一次 run
/eagle-eye-report 20260806-181757       # 指定 run-id
```

## 输入
- `harness/.regression-runs/<run-id>/state.json` —— 切片状态机
- `harness/.regression-runs/<run-id>/summary.md` —— 机器表格
- `harness/.regression-runs/<run-id>/logs/<slice>.log` —— 各切片原始日志
- `hermes/eagle-eye/reports/<date>/issues/` —— Playwright E2E 失败复核

## 输出
- `harness/.regression-runs/<run-id>/regression-report.md` —— 详细分析报告
- `hermes/eagle-eye/reports/<date>/resilient-regression-recovery.md` —— 每日归档

## 报告结构（0804 Sprint Review 风格）

1. 通过率总览（passed/failed/verdict/pending/总耗时）
2. 本次会话关键改动（git log 自动收集）
3. 各切片结果表
4. 失败切片逐条分析（症状/根因/判定/修复建议）
5. E2E 失败复核证据（issues/ 目录摘要）
6. 技术债务与遗留风险
7. 用户待办（手工核实）
8. 后续选项

## 模板
`harness/templates/regression-report.md`

## 生成器
`harness/scripts/regression-report.js`

```bash
node harness/scripts/regression-report.js --run-dir <run-id>
```

## 关联
- `/test-regression` —— 启动回归（runner 自动生成 summary.md + 归档到 report_path）
- `harness/scripts/resilient_regression.py report --run-dir <run-id>` —— runner 内置的简化归档（仅 summary 表格）
- 本命令 —— **详细分析报告**（本次会话改动 + 失败分析 + 用户待办）
<!-- update-end---author:pi---date:2026-08-06---for:【EAGLE-EYE-REPORT】新增报告生成命令（0804 Sprint Review 风格模板）-->
