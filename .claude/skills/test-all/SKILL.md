---
name: test-all
description: 主动调用可恢复 MES 回归 runner，配合环境闸门、看板、问题复核报告
version: 3.0.0
---

# 全量测试 (Test All) — 鹰眼团 v3

## 重要变化

v3 不再要求当前会话前台串行执行整批 Playwright。所有回归测试通过 `resilient_regression.py` 在后台独立进程执行，不依赖 Orca/Pi 会话存活。

## 范围

支持任意客户端：

- Windows
- Ubuntu
- macOS
- 本地服务端
- 客户端（仅前端 + Playwright）
- 远程服务（只检查连通性）

## 标准流程

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
```

## 报告归档

```text
harness/.regression-runs/<run-id>/summary.md
hermes/eagle-eye/reports/YYYY-MM-DD/resilient-regression-recovery.md
hermes/eagle-eye/reports/YYYY-MM-DD/issues/
```

## 禁止事项

- 不再写 `vitest` / `nohup mvn spring-boot:run` / `pnpm dev &` 这类命令到工作流；
- 不再在命令文档里用 `localhost:3100` 或 `100.122.125.106`；
- 不在 Orca/Pi 终端前台等待整批回归；
- 不把环境问题记入产品 Bug。
