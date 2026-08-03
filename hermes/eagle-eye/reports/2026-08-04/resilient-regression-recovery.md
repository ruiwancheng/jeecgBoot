# MES 可恢复回归报告

- 运行 ID：`20260804-040224`
- 任务：MES regression recovery 2026-08-04
- 状态：**completed_with_failures**
- 创建时间：2026-08-04T04:02:24+08:00
- 更新时间：2026-08-04T04:35:46+08:00
- 汇总：failed=2, passed=11, timeout=1

| 切片 | 名称 | 状态 | 尝试 | 退出码 | 耗时 | 原始日志 | 说明 |
|---|---|---:|---:|---:|---:|---|---|
| 0-build | 完整构建后端并安装本地依赖 | passed | 1 | 0 | 133.406s | `harness\.regression-runs\20260804-040224\logs\0-build.attempt-1.log` | command exited with code 0 |
| 1.1 | 采购申请到订单 | passed | 1 | 0 | 3.266s | `harness\.regression-runs\20260804-040224\logs\1.1.attempt-1.log` | command exited with code 0 |
| 1.2 | 采购订单到入库 | passed | 1 | 0 | 1.641s | `harness\.regression-runs\20260804-040224\logs\1.2.attempt-1.log` | command exited with code 0 |
| 1.3 | 采购入库到付款 | passed | 1 | 0 | 2.828s | `harness\.regression-runs\20260804-040224\logs\1.3.attempt-1.log` | command exited with code 0 |
| 2.1 | 销售收发货基础链路 | passed | 1 | 0 | 0.25s | `harness\.regression-runs\20260804-040224\logs\2.1.attempt-1.log` | command exited with code 0 |
| 3.2 | 生产链路编排 | passed | 1 | 0 | 0.625s | `harness\.regression-runs\20260804-040224\logs\3.2.attempt-1.log` | command exited with code 0 |
| 4.2 | 财务链路编排 | passed | 1 | 0 | 0.64s | `harness\.regression-runs\20260804-040224\logs\4.2.attempt-1.log` | command exited with code 0 |
| 5.3 | 库存链路编排 | passed | 1 | 0 | 0.64s | `harness\.regression-runs\20260804-040224\logs\5.3.attempt-1.log` | command exited with code 0 |
| 6.2 | 批次链路编排 | passed | 1 | 0 | 0.422s | `harness\.regression-runs\20260804-040224\logs\6.2.attempt-1.log` | command exited with code 0 |
| 7.2-global-switch | 批次总开关模块 | passed | 1 | 0 | 0.641s | `harness\.regression-runs\20260804-040224\logs\7.2-global-switch.attempt-1.log` | command exited with code 0 |
| 7.2-manual | 批次手工录入模块 | passed | 1 | 0 | 0.422s | `harness\.regression-runs\20260804-040224\logs\7.2-manual.attempt-1.log` | command exited with code 0 |
| 8.1 | 核心三页面 E2E | failed | 1 | 1 | 191.156s | `harness\.regression-runs\20260804-040224\logs\8.1.attempt-1.log` | command exited with code 1 |
| 8.2 | 生产财务盘点三页面 E2E | timeout | 1 | 1 | 601.406s | `harness\.regression-runs\20260804-040224\logs\8.2.attempt-1.log` | exceeded 600 seconds |
| 8.3 | 批次六页面 E2E | failed | 1 | 1 | 238.187s | `harness\.regression-runs\20260804-040224\logs\8.3.attempt-1.log` | command exited with code 1 |

## 恢复方式

```bash
python harness/scripts/resilient_regression.py status --run-dir "D:\vibecoding\jeecgBoot\harness\.regression-runs\20260804-040224"
python harness/scripts/resilient_regression.py resume --run-dir "D:\vibecoding\jeecgBoot\harness\.regression-runs\20260804-040224"
```

> `passed` 表示命令真实退出码为 0；`blocked_environment` 表示依赖服务不可用，未当作产品失败。
