<!-- update-begin---author:pi---date:2026-08-04---for:【REGRESSION-COMMANDS】新增主动回归测试命令入口 -->
---
description: 自有命令 — 主动启动可恢复 MES 回归测试、看板和问题复核报告
---

# /test-regression [--resume] [--status] [--stop] [--dashboard]

主动调用当前 harness 回归测试体系。测试在后台独立进程执行，不依赖当前 Orca/Pi 会话持续在线。

## 常用用法

```text
/test-regression                  # 检查环境后启动新回归 + 看板
/test-regression --resume         # 恢复最近一次中断或失败的回归
/test-regression --status         # 查看最近一次回归状态
/test-regression --stop           # 停止 runner，不默认停止业务服务
/test-regression --stop --services --dashboard  # 同时停止 runner、看板和本次启动的服务
```

## 必须加载

执行前加载：

1. `.claude/skills/test-all/SKILL.md`
2. `.claude/skills/test-environment/SKILL.md`
3. `harness/scripts/resilient_regression.py` 的 CLI 用法

## 执行流程

### 1. 环境闸门

先执行 `/test-environment --check`。环境未 READY 时：

- 不启动回归测试；
- 输出具体缺项、可执行修复命令和当前客户端系统；
- 远程客户端不启动本地 Java/MySQL/Redis。

### 2. 防重复启动

先执行：

```bash
python harness/scripts/resilient_regression.py status
```

如果最近任务状态为 `running`，不再新建任务，只返回当前运行目录和看板地址。

如果当前客户端没有 `python`，依次探测 `python3`，不得假定固定解释器路径。

### 3. 主动启动

在仓库根目录执行：

```bash
python harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json \
  --dashboard \
  --port 8765
```

Windows、Ubuntu、macOS 均使用 Python runner；不得在命令文件中拼接 `taskkill`、`nohup`、`netstat`、`mvn.cmd` 等平台专属流程。

### 4. 输出启动凭证

必须输出：

```text
回归任务：已启动
运行目录：harness/.regression-runs/<run-id>
看板地址：http://127.0.0.1:8765
状态命令：python harness/scripts/resilient_regression.py status --run-dir <run-dir>
报告目录：hermes/eagle-eye/reports/YYYY-MM-DD/
```

### 5. 断点恢复

`--resume` 时：

```bash
python harness/scripts/resilient_regression.py resume \
  --run-dir <run-dir> \
  --retry-failed \
  --dashboard \
  --port 8765
```

恢复规则：

- `passed`：跳过；
- `running`：先判为 `interrupted`，再恢复；
- `failed/timeout`：只有用户指定 `--resume` 时重试；
- `blocked_environment`：环境恢复后重试；
- 不覆盖历史日志和问题证据。

## 结果判定

命令输出必须区分：

```text
测试通过
测试失败，待复核
疑似产品问题
误判
测试脚本问题
测试数据前置问题
环境问题
测试设计问题
```

测试命令退出码非零不等于已经确认产品 Bug。最终问题以以下目录的复核证据为准：

```text
hermes/eagle-eye/reports/YYYY-MM-DD/issues/
```

## 禁止事项

- 不直接在当前会话前台串行跑整批 Playwright；
- 不使用 `|| true` 掩盖失败；
- 不把环境失败写成产品 Bug；
- 不因为单个 E2E 失败自动修改业务代码；
- 不重复启动已有 running runner；
- 不默认停止用户已有的后端、前端、MySQL、Redis。
<!-- update-end---author:pi---date:2026-08-04---for:【REGRESSION-COMMANDS】新增主动回归测试命令入口 -->
