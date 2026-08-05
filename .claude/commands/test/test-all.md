<!-- update-begin---author:pi---date:2026-08-04---for:【REGRESSION-COMMANDS】将test-all接入主动可恢复回归流程 -->
---
description: 自有命令 — 全量回归入口：环境闸门 + 后台 runner + 看板 + 复核报告
---

# /test-all <项目名> [功能名] [--resume]

`/test-all` 是完整回归入口。对于当前 MES harness，必须主动调用可恢复 runner，不再由当前会话前台串行执行整批测试。

## 当前 MES 标准调用

执行以下顺序：

```text
/test-environment --check
        ↓ READY
/test-regression --dashboard
```

实际 runner 命令：

```bash
python harness/scripts/resilient_regression.py start \
  --manifest harness/regression/recovery-plan.json \
  --dashboard \
  --port 8765
```

如果检测到已有运行任务：

```bash
python harness/scripts/resilient_regression.py status
```

禁止重复启动，直接返回已有运行目录和看板地址。

## 参数

```text
/test-all mes                 # 启动 MES 全量回归
/test-all mes --resume         # 恢复最近一次未完成/失败任务
/test-all mes --status         # 查看状态，不启动新任务
/test-all mes --stop           # 停止 runner，不默认停止业务服务
```

恢复命令：

```bash
python harness/scripts/resilient_regression.py resume \
  --run-dir <run-dir> \
  --retry-failed \
  --dashboard \
  --port 8765
```

## 失败分类

不能把命令退出码非零直接判定为产品问题。最终结论依据：

```text
hermes/eagle-eye/reports/YYYY-MM-DD/issues/
```

复核结果分：

- pending_review
- suspected_bug
- confirmed_bug
- false_positive
- test_defect
- environment_issue
- data_precondition
- test_design_issue

只有人工确认后才会升级到 confirmed_bug。
<!-- update-end---author:pi---date:2026-08-04---for:【REGRESSION-COMMANDS】将test-all接入主动可恢复回归流程 -->
