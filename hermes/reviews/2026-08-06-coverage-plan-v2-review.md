# hermes/plan/coverage-improvement.md v2 复审报告

复审日期：2026-08-06  ｜  复审视角：架构 + 质量门控  ｜  复审结论：**❌ 修订方向正确但执行细节仍有多处事实错误，需小幅修正**

---

## 一、上次评审指出的问题是否已修正

| 上次指出的问题 | v2 状态 | 复审判定 |
|---|---|---|
| 文件清单 19→实际 22 | ✅ 已修正 | 通过 |
| 端点 ~303→实际 ~344 | ✅ 已修正 | 通过 |
| 22 个零覆盖 Controller→实际 1 个 | ⚠️ 改为 1 个（Location），**但实际是 0 个** | **未完全修正** |
| 阶段切分按文件而非按链路 | ⚠️ 仍按链路分（采购/财务/生产），但**链路顺序有误** | 部分修正 |
| 验收标准"~20 行估计"不可证伪 | ✅ 改为端点覆盖矩阵 | 通过 |
| 风险清单缺 finance 鉴权 only 冲突 | ✅ 已加入阶段 0.2 | 通过 |
| 风险清单缺 manufacturing 3 bug | ✅ 已加入阶段 0.1 | 通过 |
| 风险清单缺 dbCleanup 依赖 | ✅ 已加入风险表 | 通过 |

**结论：v2 修正了上次评审 8 项中 5 项，3 项未完全到位**（详见下文）。

## 二、关键事实核验：v2 仍有事实错误

### 2.1 "Location 唯一零覆盖"——错

`harness/tests/modules/basic.test.js` 实际已覆盖 Location 4 个端点：

```
// basic.test.js 中的真实调用
r7  = GET  /mes/basic/location/list
r8  = POST /mes/basic/location/add
r9  = POST /mes/basic/location/add（重复编码负样本）
r10 = POST /mes/basic/location/generate
r11 = GET  /mes/basic/location/list?warehouseId=
r12 = PUT  /mes/basic/location/edit
```

Location 控制器共 9 个端点，basic.test.js 覆盖 4 个，**未覆盖 5 个**（/delete, /deleteBatch, /exportXls, /importExcel, /selectPage）。v2 的"~12 端点"也错（实测 9 个，差 3 个）。

### 2.2 "17 个状态机端点"——8 个是 phantom

| v2 声称 | 代码实查 | 判定 |
|---|---|---|
| PurchaseApply /audit | ✅ 存在 | 真实缺口 |
| PurchaseApply /reject | ✅ 存在 | 真实缺口 |
| PurchaseApply /unaudit | ✅ 存在 | 真实缺口 |
| PurchaseOrder /audit | ✅ 存在 | 真实缺口 |
| PurchaseReceipt /audit | ✅ 存在 | 真实缺口 |
| PurchaseReceipt /unaudit | ✅ 存在 | 真实缺口 |
| CompletionReceipt /audit | ✅ 存在 | 真实缺口 |
| ProductionPicking /audit | ✅ 存在 | 真实缺口 |
| **Bom /audit** | ❌ **代码中不存在** | **phantom** |
| **ProductionOrder /audit** | ❌ **代码中不存在** | **phantom** |
| **AccountSubject /audit** | ❌ **代码中不存在** | **phantom** |
| **Collection /audit** | ❌ **代码中不存在** | **phantom** |
| **Payment /audit** | ❌ **代码中不存在** | **phantom** |
| **PurchaseInvoice /audit** | ❌ **代码中不存在** | **phantom** |
| **SalesInvoice /audit** | ❌ **代码中不存在** | **phantom** |
| **SalesInvoice /cancel** | ❌ **代码中不存在** | **phantom** |
| **Voucher /audit** | ✅ 存在 | 真实缺口（v2 列入财务链路 OK） |

**实测真实状态机端点：10 个；v2 声称 17 个；多出 8 个 phantom（占总声称 47%）**。

### 2.3 v2 漏掉的真实缺口

| 真实缺口 | 端点 | v2 列表 | 实际覆盖 |
|---|---|---|---|
| **SalesOutbound /audit** | PUT | ❌ 未列 | chains/sales-receipt-flow.test.js 已覆盖 |
| **SalesOutbound /cancel** | PUT | ❌ 未列 | chains/sales-receipt-flow.test.js 已覆盖 |
| **PurchaseOrder /unaudit** | PUT | ❌ 未列 | chains/purchase-payment-flow.test.js + purchase-apply-order.chain.test.js 已覆盖 |

v2 只看了 `harness/tests/modules/` 单文件目录，**漏掉了 `harness/tests/chains/` 9 个链路测试文件**（purchase-chain, purchase-order-receipt, purchase-payment-flow, sales-receipt-flow, finance-chain, manufacturing-chain, batch-chain, warehouse-chain, purchase-apply-order.chain）。链测里很多状态机已被覆盖。

## 三、阶段 0（前置条件）评估

### ✅ 合理部分
- 识别 manufacturing.test.js 的 3 个遗留 bug 标记
- 识别 finance.test.js 的"鉴权 only"约束冲突

### ⚠️ 不够具体
- **阶段 0.1**："解决 manufacturing 3 个遗留 bug 或确认可继续补测"——给的是二选一但没推荐项。"确认可继续补测"实际上等于绕开 bug（用 stub 数据），但代码层面的 #STATUS-FLOW-MISSING 仍然未修，状态机测试只是包装。
- **阶段 0.2**："放开约束 OR 新建文件"——给的是二选一但没推荐项。**推荐项应是"新建 finance-state-flow.test.js"**，因为 finance.test.js 是 gen-tests 自动生成版，覆盖 8 个 Controller 的统一鉴权矩阵，改它会破坏生成基线。
- **阶段 0.3**："跑通现有测试"——没说基线（`/regression` 20260805-041046 的 87% 应当作为下限），没说"全绿"的具体定义。

### 💡 缺失的前置项
- **审计 chains/ 目录**：阶段 0 应加一步"审计 9 个 chain 测试文件覆盖了哪些状态机端点"，避免重复造测试
- **审计 basic.test.js**：basic.test.js 是聚合文件，混合了 Customer/Material/Inventory/Location 多个 Controller 测试，Location 状态机（如果存在）可能藏在这里——阶段 0 应该决定"basic.test.js 是否要拆"

## 四、执行顺序评估

### v2 顺序：Location → 采购 → 财务 → 生产

**问题：财务放在生产前是错的。**

| 链路 | 依赖 | 正确位置 |
|---|---|---|
| Location（基础数据） | 无 | 阶段 1 ✓ |
| 采购（应付来源） | 物料、供应商 | 阶段 2 ✓ |
| 生产（产成品入库） | 物料、BOM、客户 | 阶段 3 |
| 财务（凭证/收付） | 采购入库单 + 销售出库单 + 完工入库单 | 阶段 4（最晚） |

**理由**：
- Voucher 凭证生成依赖业务单据已审核（采购入库/销售出库/完工入库）
- Collection 收款依赖销售出库
- Payment 付款依赖采购入库
- 把财务放在生产前，会出现"先审核凭证→后才有产成品入库"的反向依赖

**建议顺序**：
```
阶段 1：Location
阶段 2：采购（入库单已审）
阶段 3：生产（完工入库已审）
阶段 4：财务（依赖阶段 2、3 的入库单）
```

如果生产链的 3 个遗留 bug 不能解，财务可以独立（Voucher 自身 audit 不强依赖业务单据），但 Voucher 的"来源单据"测试需要先有业务单据。

## 五、验收标准可证伪性

### ✅ 已改善
"端点覆盖矩阵"格式确实可证伪（每个端点对应 file:line）：

```
Controller: Xxx
├── /audit → ✅ test.js:201
├── /unaudit → ❌ 未覆盖
```

### ⚠️ 仍可加强
- **没指定生成工具**：matrix 用 `grep` 写？人工写？建议绑定 `harness/scripts/` 中的 regression_dashboard.py 自动生成
- **没指定与覆盖率报表的对应关系**：matrix 是单元测试覆盖，与 jacoco/it 覆盖率不是一回事，应明确"matrix 是 API 调用覆盖，jacoco 是代码行覆盖"
- **"全绿"定义不清**：200 OK 不等于业务正确，应加"业务正确性断言"（如状态字段值、金额合计、关联单据存在性）

## 六、风险清单完整性

| 风险 | v2 状态 | 复审建议 |
|---|---|---|
| manufacturing 3 bug | ✅ 已列 | 补"谁来解决"的 owner |
| finance 鉴权 only | ✅ 已列 | 补"推荐项：新建文件" |
| dbCleanup 跨平台 | ✅ 已列 | OK |
| **chain 测已覆盖的状态机被重复造** | ❌ **漏列** | 应加"chains 目录审计"风险 |
| **Location 部分覆盖被误判为零覆盖** | ❌ **漏列** | 应加"聚合文件 basic.test.js 二次审计"风险 |
| **phantom 端点（8 个不存在）写空测试** | ❌ **漏列** | 应加"代码扫描前置"风险 |
| **Voucher 凭证来源依赖业务单据** | ❌ **漏列** | 阶段 4 编排风险 |
| **manufacturing 遗留 bug 解开后会改 Service 代码** | ❌ **漏列** | 阶段 0.1 风险（业务代码改 vs 测不改的二选一） |
| **plan 改动后端代码再改导致 matrix 失效** | ❌ **漏列** | 应在阶段 0 末加"代码 freeze 期"约束 |

## 七、工作量估算复核

| v2 估 | 复审估 | 差异 |
|---|---|---|
| 阶段 1：Location 80 行 | **50 行**（5 端点 × ~10 行） | -38% |
| 阶段 2：采购 120 行（6 端点） | **75 行**（6 端点 × ~12 行，状态机断言稍多） | -38% |
| 阶段 3：财务 140 行（7 端点） | **20 行**（1 端点 × ~20 行；v2 多估 6 个 phantom） | -86% |
| 阶段 4：生产 80 行（4 端点） | **60 行**（3 端点 × ~20 行，phantom 已剔除） | -25% |
| **合计 420 行** | **205 行** | **-51%** |

**复审估**基于 11 个真实状态机缺口 + 5 个 Location 端点（含阶段 0 决策成本）。

## 八、复审结论

| 项目 | v2 评分 | 复审评分 |
|---|---|---|
| 评审响应 | ✅ 完全接受 | ✅ 完全接受 |
| 数据校正 | ⚠️ 4 项中 2 项仍错 | ❌ 仍有 3 处事实错（Location/phantom/chain 漏审） |
| 阶段 0 设计 | ⚠️ 给了决策但没推荐项 | ⚠️ 同上 |
| 执行顺序 | ❌ 财务在生产前反向 | 需调整 |
| 验收标准 | ✅ 端点矩阵 | ✅ 仍 OK，可再加工具绑定 |
| 风险清单 | ⚠️ 4 条 | 需加 5 条 |
| 工作量估算 | ⚠️ 多估 51% | 需复核 |

**建议处置**：v2 整体方向正确（修正了上次 8 项中 5 项），但执行层有 3 处事实错误需修正：
1. 移除 8 个 phantom 状态机端点（Bom/ProductionOrder/AccountSubject/Collection/Payment/PurchaseInvoice/SalesInvoice 的 /audit + SalesInvoice /cancel）
2. 补 Location 真实覆盖状态（已覆盖 4/9，未覆盖 5/9）
3. 调整阶段顺序：财务移到生产之后
4. 补 5 条风险到风险清单
5. 阶段 0 给推荐项而非二选一

**预期修订后**：从 v2 的 4 阶段 ~420 行 → 4 阶段 ~205 行（-51%），风险 4 条 → 9 条。
