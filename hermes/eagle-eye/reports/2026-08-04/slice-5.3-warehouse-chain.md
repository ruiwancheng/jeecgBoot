# Slice 5.3 — warehouse-chain 跑测报告

- **报告路径**：`hermes/eagle-eye/reports/2026-08-04/slice-5.3-warehouse-chain.md`
- **生成日期**：2026-08-04
- **分支**：`fix/regression-2026-08-04`
- **结论**：❌ `warehouse-chain.test.js` 不存在，测试在 Node.js 模块加载阶段失败，仓储业务断言未执行。

## 切片信息

| 字段 | 值 |
|---|---|
| id | 5.3 |
| name | warehouse-chain |
| 类型 | chain-api（仓储链路） |
| 目标测试文件 | `harness/tests/chains/warehouse-chain.test.js` |
| 计划范围 | 其它入库 → 其它出库 → 库存总览/台账 → 盘点快照/差异调整 |
| 注册状态 | `hermes/business-chains.json` 中 `chains.仓储链路.health.status = planned` |
| 已登记缺口 | `warehouse-chain.test.js 待新建（合并 other-stock-in + stocktake + 加贯通断言）` |

## 跑测结果

执行命令：

```bash
cd harness && timeout 180 node tests/chains/warehouse-chain.test.js 2>&1 | tail -50 || true
```

原始输出：

```text
node:internal/modules/cjs/loader:1459
  throw err;
  ^

Error: Cannot find module 'D:\vibecoding\jeecgBoot\harness\tests\chains\warehouse-chain.test.js'
    at Module._resolveFilename (node:internal/modules/cjs/loader:1456:15)
    at defaultResolveImpl (node:internal/modules/cjs/loader:1066:19)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1071:22)
    at Module._load (node:internal/modules/cjs/loader:1242:25)
    at wrapModuleLoad (node:internal/modules/cjs/loader:255:19)
    at Module.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:154:5)
    at node:internal/main/run_main_module:33:47 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v24.14.0
```

| 指标 | 结果 |
|---|---:|
| 套件通过数 | 0 |
| 套件失败数 | 1（测试脚本缺失，非业务断言失败） |
| 套件通过率 | 0%（N/A，业务测试未启动） |
| 实际耗时 | 0.190s |
| 业务断言执行数 | 0 |
| Node.js 预期退出码 | 1（`MODULE_NOT_FOUND`） |
| 命令最终退出码 | 0（被 `| tail -50 || true` 掩蔽） |

> “0/1、0%”为套件级执行结果，不代表仓储业务功能失败。错误发生在模块解析阶段，未登录、未请求后端、未产生测试数据。

## 失败明细

| # | 阶段 | 预期 | 实际 | 影响 |
|---|---|---|---|---|
| 1 | Node.js 模块加载 | 加载 `harness/tests/chains/warehouse-chain.test.js` 并执行仓储贯通断言 | 文件不存在，抛出 `MODULE_NOT_FOUND` | 其它出入库、库存/台账、移动平均成本、盘点差异调整均未做链路级验证 |

### 核验证据

- `harness/tests/chains/` 当前共有 6 个测试文件：`manufacturing-chain.test.js`、3 个采购段文件、`purchase-chain.test.js`、`sales-receipt-flow.test.js`；无 `warehouse-chain.test.js`。
- `hermes/business-chains.json` 已将仓储链路标记为 `planned`，并明确登记上述测试文件缺口。
- 独立探测 `http://localhost:8080/jeecg-boot/` 返回 HTTP `000`、连接失败；与任务声明“后端运行中”不一致。但本次测试在模块加载阶段已终止，尚未触发后端请求。

## 新发现 Bug

- **无新增业务 Bug**：仓储接口和数据链路均未执行，无法据此判定业务代码缺陷。
- **既有 P1 测试覆盖缺口**：`warehouse-chain.test.js` 缺失已在 `hermes/business-chains.json` 的 `health.openGaps` 登记，不属于本轮新发现。
- **环境风险 P1**：本轮探测时本地后端 8080 不可达；恢复链文件后若环境仍未恢复，测试会在登录阶段继续被阻断。

## 下一步建议

1. 新建 `harness/tests/chains/warehouse-chain.test.js`，按注册表要求编排 `other-stock-in.test.js` 与 `stocktake.test.js`，并补充跨模块 ID、库存数量、移动平均成本、台账和盘点调整单贯通断言。
2. 测试前先恢复并健康检查 `http://localhost:8080/jeecg-boot`，确认登录接口可访问。
3. 环境与链文件就绪后重跑同一命令；业务断言全部通过后，再将仓储链路 `health.status` 从 `planned` 更新为 `healthy` 并清空对应 `openGaps`。
4. 后续跑测建议开启 `set -o pipefail` 或单独保存 Node.js 退出码，避免 `tail` 和 `|| true` 将真实失败码掩蔽。

---

**reportPath**：`hermes/eagle-eye/reports/2026-08-04/slice-5.3-warehouse-chain.md`  
**filesModified**：`hermes/eagle-eye/reports/2026-08-04/slice-5.3-warehouse-chain.md`  
**phase**：completed  
**risk**：P1（仓储链路测试文件缺失；后端 8080 当前不可达）
