---
name: test-all
description: 主动调用可恢复 MES 回归 runner，配合环境闸门、看板、问题复核报告
version: 3.1.0
---

# 全量测试 (Test All) — 鹰眼团 v3.1

## 重要变化

v3.1 在 v3 基础上，runner 完成后**必须自动调用 `/eagle-eye-report`** 生成 0804 Sprint Review 风格的分析报告（不只机器 summary 表格）。

## 范围

支持任意客户端：

- Windows
- Ubuntu
- macOS
- 本地服务端
- 客户端（仅前端 + Playwright）
- 远程服务（只检查连通性）

## 标准流程（0-5）

### 0. 环境闸门

先执行 `/test-environment --check`：

- READY：继续
- PARTIAL：仅跑明确不依赖缺项的范围
- BLOCKED：停止，记录环境问题到运行目录

### 1. 防止重复启动

```bash
python harness/scripts/resilient_regression.py status
```

正在运行 → 直接返回当前运行目录和看板地址，不重新启动。

### 2. 主动启动

```bash
python harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json \
  --dashboard \
  --port 8765
```

适用范围：Windows、Ubuntu、macOS，不写死 `mvn.cmd`、`nohup`、`netstat`。

### 3. 断点恢复

```bash
python harness/scripts/resilient_regression.py resume \
  --run-dir <run-dir> \
  --retry-failed \
  --dashboard \
  --port 8765
```

恢复规则：

- `passed` 跳过；
- `running` 转 `interrupted` 后再跑；
- `failed/timeout` 只有用户主动 `--resume --retry-failed` 才重试；
- `blocked_environment` 修复后自动重试。

### 4. 结果分级

runner 只判断执行结果。测试失败不直接等于产品问题，最终由复核报告确认：

| runner 状态 | 复核分类 |
|---|---|
| passed | passed |
| failed 1 次 | pending_review |
| failed 2 次一致 | suspected_bug |
| 重试通过 | false_positive |
| 选择器找不到 | test_defect |
| 数据缺失 | data_precondition |
| 后端 8080 不通 | environment_issue |
| 85 用例 600s 超时 | test_design_issue |

最终产品问题目录：

```text
hermes/eagle-eye/reports/YYYY-MM-DD/issues/
```

### 5. 生成详细报告（0804 Sprint Review 风格）—— **必跑**

runner 只生成机器 summary.md（表格）。runner 完成后 **必须自动调用 `/eagle-eye-report`** 生成 0804 Sprint Review 风格的分析报告（带失败根因分析、commit 链、技术债务、用户待办、后续选项）。

```bash
node harness/scripts/regression-report.js --run-dir <run-id>
# 或默认最新一次 run：
node harness/scripts/regression-report.js
# 或命令入口：
/eagle-eye-report [run-id]
```

输出位置：

```text
harness/.regression-runs/<run-id>/regression-report.md                              # 本次运行详细分析
hermes/eagle-eye/reports/YYYY-MM-DD/resilient-regression-recovery.md                # 每日归档
```

报告章节（0804 Sprint Review 风格）：

1. **通过率总览**（passed/failed/verdict/pending/总耗时）
2. **本次会话关键改动**（git log 自动收集 12 小时内的 commit）
3. **各切片结果表**（slice_id / name / status / 耗时 / 备注）
4. **失败切片逐条分析**（症状 / 根因 / 判定 / 修复建议）
5. **E2E 失败复核证据**（issues/ 目录摘要 + verdict 分类）
6. **技术债务与遗留风险**（已修复 + 剩余）
7. **用户待办**（手工核实清单）
8. **后续选项**（A/B/C/D）

**模板**：`harness/templates/regression-report.md`
**生成器**：`harness/scripts/regression-report.js`
**命令入口**：`.claude/commands/test/eagle-eye-report.md`（`/eagle-eye-report [run-id]`）

> **注意**：runner 生成的 `report_path` 仅写机器表格。本步骤生成的详细报告**覆盖**当天的归档路径（如 `hermes/eagle-eye/reports/2026-08-06/resilient-regression-recovery.md`），更全面。

### 完整流程图

```text
0. /test-environment --check
        ↓
1. python resilient_regression.py status（防重复启动）
        ↓
2. python resilient_regression.py start --dashboard --port 8765
        ↓
3. python resilient_regression.py resume --retry-failed（如需要）
        ↓
4. runner 完成 → 自动写 summary.md + report_path 归档（机器表格）
        ↓
5. node harness/scripts/regression-report.js --run-dir <run-id>   ← 自动调用 / 必跑
        ↓
生成 0804 Sprint Review 风格详细报告 + 覆盖归档
```

## 看板

runner 启动时通过 `--dashboard` 启动本地看板：

```text
http://127.0.0.1:8765
```

看板独立进程：

- Orca 崩溃不影响看板；
- runner 结束后仍可查看最终结果；
- 看板只读，不改业务数据。

## 范围判断（可选增强）

使用 code-review-graph MCP 工具：

```text
低风险 + 少量变更 → 轻量模式
高风险 / 多模块 → 全量模式
```

降级：MCP 不可用 → 全量模式。

## 与现有命令的衔接

```text
/test-environment --check
        ↓
/test-all mes
  ↓
  /test-regression（内部委托）
    ↓
  python harness/scripts/resilient_regression.py start --dashboard
    ↓
  /eagle-eye-report（自动收尾，详细报告）
```

## 报告归档（三个位置）

```text
harness/.regression-runs/<run-id>/summary.md                                  # 机器表格（runner 输出）
harness/.regression-runs/<run-id>/regression-report.md                        # 详细分析（步骤 5 输出）
hermes/eagle-eye/reports/YYYY-MM-DD/resilient-regression-recovery.md          # 每日归档（步骤 5 覆盖写入）
hermes/eagle-eye/reports/YYYY-MM-DD/issues/                                  # Playwright E2E 失败复核
```

## 禁止事项

- 不再写 `vitest` / `nohup mvn spring-boot:run` / `pnpm dev &` 这类命令到工作流；
- 不再在命令文档里用 `localhost:3100` 或 `100.122.125.106`；
- 不在 Orca/Pi 终端前台等待整批回归；
- 不把环境问题记入产品 Bug；
- **不在步骤 5 缺失**：runner 完成后必须生成详细报告，不允许只交付 summary.md。
