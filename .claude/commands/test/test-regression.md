<!-- update-begin---author:pi---date:2026-08-04---for:【REGRESSION-COMMANDS】新增主动回归测试命令入口 -->
---
description: 自有命令 — 主动启动可恢复 MES 回归测试、看板和问题复核报告
---

# /test-regression [--scope full|change] [--base <commit>] [--resume] [--status] [--stop] [--dashboard]

主动调用当前 harness 回归测试体系。测试在后台独立进程执行，不依赖当前 Orca/Pi 会话持续在线。

## 常用用法

```text
/test-regression --scope full                              # 全量回归：跑 21 个切片
/test-regression --scope change --base <commit>            # 变更感知：只跑冒烟 + 命中链路的 segment
/test-regression --scope change --base HEAD~5 --dashboard  # 跳 5 次提交后，刷新当前变更对应的回归 + 看板
/test-regression --resume                                  # 续跑上次的回归
/test-regression --status                                  # 查看最近一次回归状态
/test-regression --stop --dashboard                        # 停止 runner + 看板
```

## 范围参数（必读）

新增 `--scope`，由用户每次主动选：

- `full`（默认）：跑 manifest 中所有切片，包括 `0-build`、`frontend-static`、`test-quality`、所有 `chain.*`、所有 `1.1~8.3`。
- `change` + `--base <commit>`：基于 `git diff <base>..HEAD` 匹配 `hermes/business-chains.json` 的 `chains.<name>.modules`：
  - 总是跑 `0-build`、`frontend-static`、`test-quality`、所有 `smoke-api` / `smoke-e2e` 切片作为冒烟；
  - 只跑匹配到的链路 segment；
  - `1.1 ~ 8.3` 等硬编码切片不跑（避免做不相关的回归）。

人工选范围的优点：
- 提交 PR 后只验证本次改动，不必每次都跑全量；
- 重要版本发布前可手动选 full 防止漏过；
- runner 不会因自动选择而把无关切片失败也归类成产品 Bug。

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
范围：full / change
差异文件：<N> 个（仅 --scope change 时显示）
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
