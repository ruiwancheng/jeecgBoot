# /add-tests — 主动添加测试用例

> **业务人员命令**：为指定的项目/模块/页面补齐回归测试用例。
> **目标**：构建回归测试体系，覆盖率后期慢慢提升。

## 命令格式

### 格式 1：单页面测试

```bash
/add-tests <项目> <模块> [页面]
```

**示例**：
```bash
/add-tests basic customer                  # 客户管理
/add-tests basic customerAddress          # 客户地址子模块
/add-tests finance collection             # 收款管理
/add-tests stock otherOut                 # 其他出库
```

### 格式 2：链路测试

```bash
/add-tests <项目> 链路 <链路名>
```

**示例**：
```bash
/add-tests sales 链路 sales-receipt-flow      # 销售→出库→收款
/add-tests purchase 链路 purchase-payment-flow # 采购→收货→付款
```

## AI 执行标准流程

1. **解析参数**：识别项目（basic/batch/finance/manufacturing/purchase/sales/stock/system）、模块、页面/链路
2. **读取相关代码**：
   - 后端：`Controller.java` + `Service.java` + `Entity.java`
   - 前端：`index.vue` + `*.api.ts` + `*.data.ts`
   - 现有测试：`harness/e2e/mes/*.spec.ts` + `harness/tests/chains/*.test.js` + `harness/tests/modules/*.test.js`
3. **设计测试矩阵**：覆盖该 scope 所有端点 + 主要场景（CRUD + 校验 + 异常路径）
4. **写入新文件**：
   - 页面测试 → `harness/e2e/mes/<project>-<page>.spec.ts`
   - 链路测试 → `harness/tests/chains/<project>-<chain>.test.js`
   - 模块 API 测试 → `harness/tests/modules/<project>-<module>.test.js`
5. **跑测验证**：按 CLAUDE.md "验证必实测" 原则，本地必须跑通
6. **commit + push**：commit 信息加 `[/add-tests]` 前缀方便审计

## 输出格式（每次完成后）

```markdown
## /add-tests basic customerAddress 完成

**新增**：
- harness/e2e/mes/basic-customerAddress.spec.ts（7 tests）
- harness/tests/modules/basic-customerAddress.test.js（10 tests）

**覆盖**：7/7 endpoints = 100%

**验证**：
- ✅ spec: 7 passed
- ✅ module: 10 passed

**commit**: <hash>
```

## 项目/模块速查表

| 项目 | 子模块示例 |
|---|---|
| **basic** | customer, customerAddress, customerContact, customerFollowUp, customerPrice, supplier, material, inventory, inventoryAlert, warehouse, location, codeRule, commonSetting |
| **batch** | batch, batchInventory, batchLedger, batchTraceability |
| **finance** | collection, payment, receivable, payable, salesInvoice, purchaseInvoice, accountSubject, voucher |
| **manufacturing** | productionOrder, productionPicking, completionReceipt, bom |
| **purchase** | purchaseApply, purchaseOrder, purchaseReceipt, costLog, inventoryLedger |
| **sales** | salesOrder, salesOutbound, deliveryNote, salesPrice |
| **stock** | otherStockIn, otherStockOut, stocktake |
| **system** | globalSwitch |

## 场景维度（可选 `--scenario=`）

| 场景 | 含义 |
|---|---|
| `crud` | 增删改查（默认） |
| `error` | 错误路径：缺字段/越界/类型错误 |
| `boundary` | 边界条件：空值/最大长度/分页极限 |
| `permission` | 权限矩阵 |
| `concurrent` | 并发冲突 |
| `rollback` | 事务回滚 |
| `audit` | 审核流状态机 |
| `validate` | 数据校验 |
| `smoke` | 冒烟（轻量） |

## 相关命令

- `/coverage` — 查看当前覆盖率统计
- `/test-e2e` — 跑所有 E2E 测试
- `/test-regression` — 跑回归测试