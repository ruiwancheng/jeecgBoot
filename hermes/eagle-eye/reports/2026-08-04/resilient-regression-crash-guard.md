# MES 回归崩溃保底方案落地记录

## 结论

本次回归不再依赖 Orca/AI worker 会话存活。测试由 `harness/scripts/resilient_regression.py` 脱离当前终端运行，状态和日志按切片原子落盘。

## 已落地能力

- `start/status/resume/stop/report` 公共命令
- 每个切片独立状态：`pending/running/passed/failed/timeout/blocked_environment/interrupted`
- `state.json` 临时文件 + 原子替换，防止中断损坏
- runner 心跳、当前切片、子进程 PID、服务状态和 telemetry 留存
- 已通过切片恢复时自动跳过
- 进程中断后 `resume` 自动识别 `running` 切片并续跑
- 非零退出码和超时不再被 `|| true` 掩盖
- 后端/前端执行前健康检查；环境不可用时阻断，不把环境故障统计成产品缺陷
- Windows 下 runner、后端、前端以独立进程组启动
- Playwright 固定单 worker，降低资源和控制面压力

## 自测证据

命令：

```bash
python -m unittest harness.tests.runner.test_resilient_regression -v
```

结果：3/3 通过：

1. 中断后续跑，并确认已通过切片不重复执行
2. 后端健康检查失败时阻断切片且不执行测试命令
3. 真实退出码和超时状态保真

## 正式运行

运行 ID：`20260804-040224`

启动命令：

```bash
python harness/scripts/resilient_regression.py start --manifest harness/regression/recovery-plan.json
```

恢复/查看命令：

```bash
python harness/scripts/resilient_regression.py status --run-dir harness/.regression-runs/20260804-040224
python harness/scripts/resilient_regression.py resume --run-dir harness/.regression-runs/20260804-040224
```

## 首次运行现场

第一次启动发现 Git Bash 环境没有 `mvn` 命令，runner 在构建闸门处停止，没有误跑后续测试。已将 manifest 修正为当前机器可用的 Maven 路径，并于 04:02:24 重新启动正式回归。

原始日志和状态不会进入 Git：

```text
harness/.regression-runs/<run-id>/
```

明早优先查看 `state.json` 和 `summary.md`，再按失败切片读取 `logs/`。
