# Slice 3.2 — manufacturing-chain 跑测报告

- **报告路径**：`hermes/eagle-eye/reports/2026-08-04/slice-3.2-manufacturing-chain.md`
- **生成时间**：2026-08-04（Asia/Shanghai）
- **测试文件**：`harness/tests/chains/manufacturing-chain.test.js`
- **分支**：`fix/regression-2026-08-04`
- **结论**：❌ 测试脚本文件不存在（链路状态为 `planned`），Node.js 直接 `MODULE_NOT_FOUND` 退出；无需清理残留测试数据

---

## 切片信息

| 字段 | 值 |
|---|---|
| id | 3.2 |
| name | manufacturing-chain |
| type | chain-api（链路编排） |
| 测试范围 | BOM → 生产订单 → 领料 → 完工入库（按 `hermes/business-chains.json` 链路定义） |
| 计划业务断言 | 文件不存在，无可执行断言统计；底层模块 `manufacturing.test.js` 现有 ~24 项断言作为参考基线 |
| 链路注册状态 | `chains.生产链路.health.status = planned` |
| 注册 openGap | `manufacturing-chain.test.js 待新建` |

## 跑测结果

执行命令（原样）：

```bash
cd harness && timeout 180 node tests/chains/manufacturing-chain.test.js 2>&1 | tail -50 || true
```

原始输出（`tail -50`）：

```text
node:internal/modules/cjs/loader:1459
  throw err;
  ^

Error: Cannot find module 'D:\vibecoding\jeecgBoot\harness\tests\chains\manufacturing-chain.test.js'
    at Module._resolveFilename (node:internal/modules/cjs/loader:1456:15)
    at defaultResolveImpl (node:internal/modules/cjs/loader:1066:19)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1071:22)
    at Module._load (node:internal/modules/cjs/loader:1242:25)
    at wrapModuleLoad (node:internal/modules/cjs/loader:255:19)
    at Module.executeUserEntryPoint (node:internal/modules/run_main:154:5)
    at node:internal/main/run_main_module:33:47 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v24.14.0
```

| 指标 | 结果 |
|---|---:|
| 套件通过数 | 0 |
| 套件失败数 | 1（脚本文件不存在，非业务断言失败） |
| 套件通过率 | 0%（N/A，文件不存在） |
| 实际耗时 | <1s（墙钟取整为 0s） |
| 业务断言执行数 | 0 / ~24（基线参考） |
| 进程退出码 | 1（Node.js `MODULE_NOT_FOUND`） |

> 说明：本次失败发生在 Node.js 模块解析阶段，**先于** `login()` 与任何业务请求。因此“0 / 0%”是套件级结果，并不代表生产制造业务功能存在缺陷。

## 失败明细

| # | 阶段 | 预期 | 实际 | 影响 |
|---|---|---|---|---|
| 1 | Node.js 模块解析 | 加载 `harness/tests/chains/manufacturing-chain.test.js` | `Error: Cannot find module ...`，`code: 'MODULE_NOT_FOUND'` | BOM→订单→领料→完工入库整条链路的贯通断言未执行 |

### 只读核验证据

1. `harness/tests/chains/` 目录实际只有 5 个文件，均**不是** manufacturing 相关链路：
   ```
   purchase-apply-order.chain.test.js
   purchase-chain.test.js
   purchase-order-receipt.chain.test.js
   purchase-payment-flow.test.js
   sales-receipt-flow.test.js
   ```
2. `harness/tests/modules/` 目录存在 `manufacturing.test.js`（模块级测试，非链路编排），但不是本切片要求的链文件。
3. `hermes/business-chains.json` 中“生产链路”显式标记：
   - `chainTests.enabled = false`
   - `chainTests.planned = true`
   - `chainTests.nextStep = "跑 /chain-test 生产链路 验证 BOM→订单→领料→完工"`
   - `health.openGaps = ["manufacturing-chain.test.js 待新建"]`
4. 当前后端环境实际状态：
   - `curl -sS -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"123456"}' http://localhost:8080/jeecg-boot/sys/login` 返回 `code:200`、JWT token（长度 155）。
   - `netstat` 显示 `0.0.0.0:8080 LISTENING`（PID 32400，Java 进程内存 ~854MB，活跃）。
   - 因此后端已恢复（与 Slice 3.1 报告的 “localhost:8080 不可达” 不同），但本次切片因脚本不存在仍无法推进业务验证。
5. 测试在文件加载阶段即终止，没有产生任何业务请求 → **无需清理残留测试数据**。

## 新发现 Bug

无（本切片在加载前即终止，未触及业务接口；不触发新的代码缺陷假设）。

唯一的“缺口”已**预先**记录在 `hermes/business-chains.json`：

- **P1（已登记）** `GAP-MANUFACTURING-CHAIN-TEST-NEW`：生产链路缺链路编排文件 `manufacturing-chain.test.js`，无法对 BOM→订单→领料→完工入库做贯通断言；变更触发 `chainAudit` 时该链只能给出健康状态 `planned` 而非 `healthy`。

> 注：这是 Slice 3.1 报告中的 `BUG-MANUFACTURING-HARNESS-BASE-MISMATCH`（`manufacturing.test.js` 默认 BASE 硬编码远端地址）的**姊妹问题**：模块级测试曾因环境/地址不当被阻断；即便地址修正，链路级贯通验证仍因文件缺失而空缺。两个问题都需在下一轮修复。

## 下一步建议

1. **P1 新建 `harness/tests/chains/manufacturing-chain.test.js`**：
   - 建议采用与 `purchase-chain.test.js` 同模式的纯编排器：`require` 数个 `manufacturing-*.chain.test.js` 段文件，并打印 4 段标题（定义BOM / 下生产单 / 领料 / 完工入库）。
   - 建议拆分：
     - `manufacturing-bom-order.chain.test.js`（BOM→订单）
     - `manufacturing-order-pick.chain.test.js`（订单→领料）
     - `manufacturing-pick-complete.chain.test.js`（领料→完工入库）
     - 或直接复用一个增强版 `manufacturing.test.js`，补跨段 ID 传递与状态流转断言。
2. **同时复核 Slice 3.1 的 `BUG-MANUFACTURING-HARNESS-BASE-MISMATCH`**：建议将 `manufacturing.test.js` 的 `BASE` 默认值统一为 `http://localhost:8080/jeecg-boot`，与其他模块测试保持一致，避免后续 Slices 再次因地址硬编码触发 `fetch failed`。
3. **重跑 Slice 3.2**：新建文件后重跑同一命令；当且仅当 4 段全部贯通后再将 `chains.生产链路.health.status` 从 `planned` 切到 `healthy`、清空 `openGaps`。
4. **CI 触发面**：若生产链路命中 `chainAudit` 触发阈值 ≥2 模块，建议把 `manufacturing-chain.test.js` 加入 `.github/workflows/functional-regression.yml` 的 api-test job 中，与采购链路平行纳入 CI。

---

**reportPath**：`hermes/eagle-eye/reports/2026-08-04/slice-3.2-manufacturing-chain.md`
**filesModified**：`hermes/eagle-eye/reports/2026-08-04/slice-3.2-manufacturing-chain.md`（仅验证报告；未修改业务代码、未新建任何代码文件）
**risk**：P1（生产链路贯通测试缺失，回归覆盖断点持续存在）
**phase**：completed（按任务指令完成跑测+报告；新建链文件超出本次切片范围，作为下一步 P1）
