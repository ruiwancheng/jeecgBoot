# MES 可恢复回归报告

- 运行 ID：`20260806-181757`
- 任务：MES regression recovery 2026-08-04
- 状态：**completed_with_failures**
- 创建时间：2026-08-06T18:17:57+08:00
- 更新时间：2026-08-06T18:26:22+08:00
- 汇总：failed=2, passed=20, verdict=1

| 切片 | 名称 | 状态 | 尝试 | 退出码 | 耗时 | 原始日志 | 说明 |
|---|---|---:|---:|---:|---:|---|---|
| 0-build | 完整构建后端并安装本地依赖 | passed | 1 | 0 | 12.018s | `harness/.regression-runs/20260806-181757/logs/0-build.attempt-1.log` | command exited with code 0 |
| frontend-static | 前端类型检查与构建验证 | verdict | 1 | 1 | 21.61s | `harness/.regression-runs/20260806-181757/logs/frontend-static.attempt-1.log` | command exited with code 1 |
| test-quality | API 测试断言质量扫描 (R009) | passed | 1 | 0 | 0.203s | `harness/.regression-runs/20260806-181757/logs/test-quality.attempt-1.log` | command exited with code 0 |
| smoke-api | 变更感知冒烟 (核心接口) | passed | 1 | 0 | 0.607s | `harness/.regression-runs/20260806-181757/logs/smoke-api.attempt-1.log` | command exited with code 0 |
| smoke-e2e | 变更感知冒烟 (核心 E2E) | passed | 1 | 0 | 48.294s | `harness/.regression-runs/20260806-181757/logs/smoke-e2e.attempt-1.log` | command exited with code 0 |
| 1.1 | 采购申请到订单 | passed | 1 | 0 | 0.409s | `harness/.regression-runs/20260806-181757/logs/1.1.attempt-1.log` | command exited with code 0 |
| 1.2 | 采购订单到入库 | passed | 1 | 0 | 0.61s | `harness/.regression-runs/20260806-181757/logs/1.2.attempt-1.log` | command exited with code 0 |
| 1.3 | 采购入库到付款 | passed | 1 | 0 | 2.233s | `harness/.regression-runs/20260806-181757/logs/1.3.attempt-1.log` | command exited with code 0 |
| 2.1 | 销售收发货基础链路 | passed | 1 | 0 | 3.055s | `harness/.regression-runs/20260806-181757/logs/2.1.attempt-1.log` | command exited with code 0 |
| 3.2 | 生产链路编排 | passed | 1 | 0 | 0.407s | `harness/.regression-runs/20260806-181757/logs/3.2.attempt-1.log` | command exited with code 0 |
| 4.2 | 财务链路编排 | passed | 1 | 0 | 0.41s | `harness/.regression-runs/20260806-181757/logs/4.2.attempt-1.log` | command exited with code 0 |
| 5.3 | 库存链路编排 | passed | 1 | 0 | 0.408s | `harness/.regression-runs/20260806-181757/logs/5.3.attempt-1.log` | command exited with code 0 |
| 6.2 | 批次链路编排 | passed | 1 | 0 | 0.408s | `harness/.regression-runs/20260806-181757/logs/6.2.attempt-1.log` | command exited with code 0 |
| 7.2-global-switch | 批次总开关模块 | passed | 1 | 0 | 0.203s | `harness/.regression-runs/20260806-181757/logs/7.2-global-switch.attempt-1.log` | command exited with code 0 |
| 7.2-manual | 批次手工录入模块 | passed | 1 | 0 | 0.411s | `harness/.regression-runs/20260806-181757/logs/7.2-manual.attempt-1.log` | command exited with code 0 |
| 8.1 | 核心三页面 E2E | passed | 1 | 0 | 83.443s | `harness/.regression-runs/20260806-181757/logs/8.1.attempt-1.log` | command exited with code 0 |
| 8.2-manufacturing | 生产页面 E2E | passed | 1 | 0 | 97.933s | `harness/.regression-runs/20260806-181757/logs/8.2-manufacturing.attempt-1.log` | command exited with code 0 |
| 8.2-finance | 财务页面 E2E | passed | 1 | 0 | 0.411s | `harness/.regression-runs/20260806-181757/logs/8.2-finance.attempt-1.log` | command exited with code 0 |
| 8.2-stocktake | 盘点页面 E2E | failed | 1 | 1 | 17.317s | `harness/.regression-runs/20260806-181757/logs/8.2-stocktake.attempt-1.log` | command exited with code 1 |
| 8.3 | 批次六页面 E2E | failed | 1 | 1 | 210.826s | `harness/.regression-runs/20260806-181757/logs/8.3.attempt-1.log` | command exited with code 1 |
| chain.purchase-chain.1 | 链路 采购链路 · 申请→订单 | passed | 1 | 0 | 0.422s | `harness/.regression-runs/20260806-181757/logs/chain.purchase-chain.1.attempt-1.log` | command exited with code 0 |
| chain.purchase-chain.2 | 链路 采购链路 · 订单→入库 | passed | 1 | 0 | 0.619s | `harness/.regression-runs/20260806-181757/logs/chain.purchase-chain.2.attempt-1.log` | command exited with code 0 |
| chain.purchase-chain.3 | 链路 采购链路 · 采购→入库→付款 | passed | 1 | 0 | 2.281s | `harness/.regression-runs/20260806-181757/logs/chain.purchase-chain.3.attempt-1.log` | command exited with code 0 |

## 失败复核摘要

- 复核目录：`hermes/eagle-eye/reports/2026-08-06/issues`
- 当前复核结果：suspected_bug=2

## 恢复方式

```bash
python harness/scripts/resilient_regression.py status --run-dir "/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-181757"
python harness/scripts/resilient_regression.py resume --run-dir "/Users/ruisuyun/Documents/GitHub/jeecgBoot/harness/.regression-runs/20260806-181757"
```

> `passed` 表示命令真实退出码为 0；`blocked_environment` 表示依赖服务不可用，未当作产品失败。
