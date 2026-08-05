# hermes/plan/coverage-improvement.md 架构评审报告

评审日期：2026-08-06  ｜  评审视角：架构 + 质量门控  ｜  评审结论：**❌ 计划严重过期，需重写而非微调**

---

## 一、关键事实核验（基于仓库现状）

| 维度 | 计划声称 | 仓库实测 | 差异 |
|---|---|---|---|
| Controller 总数 | 41 | 41 | ✅ 一致 |
| API test.js 文件数 | 19 | **22** (含 2 个 .mjs) | ❌ 少算 3 个 |
| E2E spec 文件数 | 35 | 35 | ✅ 一致 |
| 端点总数 | ~303 | **~344** (grep `@*Mapping` 注解) | ❌ 少算 41 |
| 22 个"零覆盖"Controller | 全部零覆盖 | **21/22 已有 CRUD 覆盖** | ❌ 全错 |

## 二、✅ 对齐点（与现状吻合的部分）

1. **目标方向正确**：覆盖率提升至 80%+、4 阶段分批、按链路分组，策略宏观合理。
2. **验收标准合理**：要求"状态机路径覆盖（草稿→审核→已审核→反审核）"命中真实痛点。
3. **测试模板引用准确**：`stocktake.test.js` 确实是已补 Controller 中状态机覆盖最完整的样本（覆盖 audit/batchAudit 完整链路）。

## 三、⚠️ 重大遗漏与错误

### 3.1 计划"零覆盖"判定严重失真

实测表明，22 个目标 Controller 中**只有 `Location`（基础数据）真正零覆盖**。其余 21 个已有 CRUD 测试：

| Controller | 计划判定 | 实际覆盖文件 | 行数 |
|---|---|---|---|
| PurchaseApply/Order/Receipt | 零覆盖 | `purchase.test.js` | 252 |
| SalesOrder | 零覆盖 | `sales-order.test.mjs` | 140 |
| SalesInvoice | 零覆盖 | `sales-api.test.mjs` | 361 |
| Bom/ProductionOrder/Picking/CompletionReceipt | 零覆盖 | `manufacturing.test.js` | 298 |
| AccountSubject | 零覆盖 | `basic-accountSubject.test.js` | 217 |
| Collection/Payment/Voucher/PurchaseInvoice | 零覆盖 | `finance.test.js` | 243 |
| CustomerAddress/Contact/FollowUp/Price | 零覆盖 | `basic-customer*.test.js` | 191×4 |
| OtherStockIn/Out | 零覆盖 | `other-stock-in.test.js` / `basic-otherStockOut.test.js` | 141/234 |
| Stocktake | 零覆盖 | `stocktake.test.js` | 187 |
| **Location** | 零覆盖 | **❌ 真的无测试** | — |

> **结论**：阶段 1 中 4/5 个 Controller、阶段 2/3/4 全部 Controller 已经在仓库中有了"以另一命名"或"聚合到模块测试"的实现。计划若按现状执行，会重复创建文件并造成覆盖数据双计。

### 3.2 真实覆盖缺口被掩盖

虽然 CRUD 已覆盖，但**状态机端点几乎全空**：

| 端点 | 现有测试调用次数 | 涉及 Controller | 缺口程度 |
|---|---|---|---|
| `/audit` | 20 次（仅 4 个 Controller） | 应在 9 个 Controller 存在 | 🔴 缺 5 个 |
| `/unaudit` | 7 次 | 应在 7 个 Controller 存在 | 🔴 缺 4 个 |
| `/reject` | **0 次** | MesPurchaseApply | 🔴 完全缺失 |
| `/cancel` | 3 次 | 仅 sales | 🟡 仅销售有 |
| `/batchAudit` | 2 次 | MesStocktake | 🟢 OK |

`purchase.test.js` 自身已显式标注："⚠ 3.3 状态机缺失：订单无确认/审核接口，已确认订单的入库场景无法验证"。`finance.test.js` 自我约束为"add/edit/delete/audit **只测鉴权，不实际写入**"。

**真实缺口是 17 个状态机端点 + 1 个零覆盖 Controller（Location）= 18 项**，不是 22 个 Controller。

### 3.3 端点统计偏差

- 计划说"~303 端点" → 实测 344 个 `@*Mapping` 注解
- 偏差 41 个（13.5%），多在 `/queryAll`、`/exportXls`、`/importExcel`、`/generate`、分页 `/selectPage` 等辅助端点上
- 影响：覆盖率分母算错，验收标准中的"80%+"实际可能只有 ~70%

### 3.4 阶段切分不优

- 阶段 1 命名"基础数据"但把 CustomerAddress/Contact/FollowUp/Price 列为"先补依赖层"，**而这些已存在**；真正的依赖层（Location）被混入但孤立，且无依赖前置意义
- 阶段 2 采购 + 销售并列，但销售测试（`sales-order.test.mjs`）已具备完整状态机、采购测试（`purchase.test.js`）却缺状态机——**能力基线不对齐**，合并阶段无法复用模式
- 阶段 3 把 7 个 Controller 一锅烩，但生产链（Bom→Order→Picking→Completion）有强业务依赖，应按"成品出库即闭环"链路串联验证，不能按文件分
- 阶段 4 财务 5 个聚合在 `finance.test.js` 单文件，但 finance.test.js 的"鉴权 only"约束与验收标准"状态机路径覆盖"直接冲突——**计划验收标准与现有实现哲学矛盾**

### 3.5 高风险步骤

- **R1 阶段 1 的 CustomerAddress/Contact/FollowUp/Price**：若按计划"创建"，会与已存在文件冲突。需先 git status 检查是否有未提交修改，再决定覆盖/合并/追加。
- **R2 阶段 4 的 finance 5 个 Controller**：`finance.test.js` 注释明确"业务代码不改；测试数据不真造"——补真实状态机会直接违反文件级契约，必须先放开该约束或新写文件。
- **R3 阶段 3 的 manufacturing 4 个 Controller**：`manufacturing.test.js` 头部带"#STATUS-FLOW-MISSING #BOM-RECON-MISSING #LEDGER-MISSING" 三个遗留缺陷标记，补状态机会撞上这些未解决的业务 bug。
- **R4 依赖 dbCleanup 工具**：`harness/tests/helpers/fixtures.js` 的 `dbCleanup` 是 2026-08-05 N2 修复才稳定的跨平台版本，所有阶段都依赖它，但计划未提示"必须使用 dbCleanup 而非直接 SQL"。

## 四、💡 优化建议

### 4.1 立即行动：重写计划而非微调

建议把"补 22 个 Controller"改为"补 18 个缺口"：

```
新阶段 0（重核现状）：
  - 用 /coverage gap 重新生成缺口清单（基于代码注解 + grep 调用点）
  - 输出 controller→文件→端点→测试状态四元组表

新阶段 1（Location 唯一零覆盖）：
  - harness/tests/modules/basic-location.test.js（9 端点，含 /generate）

新阶段 2（采购状态机补齐）：
  - purchase.test.js 追加：apply/audit, apply/reject, apply/unaudit, 
    order/audit, order/unaudit, receipt/audit, receipt/unaudit

新阶段 3（生产状态机补齐）：
  - manufacturing.test.js 追加：completion/audit, picking/audit
  - 必须先解决 3 个遗留业务 bug：#STATUS-FLOW-MISSING / #BOM-RECON-MISSING / #LEDGER-MISSING

新阶段 4（财务状态机补齐）：
  - 先决策：放开 finance.test.js 的"鉴权 only"约束，还是新建 finance-state-flow.test.js？
  - 补齐 voucher/audit, collection/audit, payment/audit, purchaseInvoice/audit, salesInvoice/audit
```

### 4.2 流程性建议

- **加一道"现状扫描"前置关卡**：任何覆盖率计划开工前，必须先 `ls harness/tests/modules/` + `wc -l` + `grep endpoints`，把"声称零覆盖"翻译成"实际覆盖状态"。本计划就是因为跳过了这一步导致整体过期。
- **补覆盖率不能用"按文件补"做单位**：应该用"端点 + 状态机路径"做单位。`finance.test.js` 即使存在也不代表 5 个 Controller 都有 audit 路径。
- **聚合测试要拆 OR 拆出来的不能再合**：`finance.test.js` 把 5 个 Controller 聚合成 1 个文件，违反了"1 Controller 1 文件"的便利性原则。后续要审计或扩展某个 Controller 时被迫读全部 243 行。
- **验收标准要从行数改为"端点覆盖矩阵"**：当前"~20 行/Controller"是不可证伪的伪指标，应替换为：列出每个 Controller 的所有 `@*Mapping` 端点，每个端点对应到测试文件中的具体行号，0 行号 = 0 覆盖。

### 4.3 工具建议

- 用 `harness/tests/modules/` 现有的 `gen-tests` 模式（已记入 learnings 2026-08-05）做端点契约驱动生成，而不是手工按"估计 20 行"写文件
- 在计划中加入"必须先跑 `node harness/tests/modules/<file>` 实测 200 OK"作为开工门

## 五、评审结论

| 项目 | 评价 |
|---|---|
| 目标方向 | ✅ 正确（提升覆盖率、4 阶段） |
| 现状判定 | ❌ 严重过期（19→22 文件、303→344 端点、22 零覆盖→1 零覆盖） |
| 阶段切分 | ⚠️ 逻辑可商榷（生产链不应按文件分） |
| 验收标准 | ⚠️ "20 行估计"不可证伪，应改为端点矩阵 |
| 风险识别 | ❌ 漏掉了 finance 的"鉴权 only"契约冲突、manufacturing 的 3 个遗留 bug |
| 策略优化 | 💡 应重写为"补 18 个缺口"而非"补 22 个文件" |

**建议处置**：标记为 `needs-rewrite` 而非 `execute-as-is`。重写后规模可压缩 70%（22 → 5-7 个文件 + 1 个 Location 新建），更聚焦真实风险。
