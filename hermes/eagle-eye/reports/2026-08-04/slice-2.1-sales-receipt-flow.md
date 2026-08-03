# Slice 2.1 — sales-receipt-flow.chain 跑测报告

- **报告路径**：`hermes/eagle-eye/reports/2026-08-04/slice-2.1-sales-receipt-flow.md`
- **生成时间**：2026-08-04（Asia/Shanghai）
- **测试文件**：`harness/tests/chains/sales-receipt-flow.test.js`
- **测试目标**：销售订单 → 销售出库 → 库存减少 → 应收单 → 收款单 → 应收减少（销售→出库→收款 全链路）
- **后端**：localhost:8080/jeecg-boot，✅ 存活（200 OK）
- **数据库**：MySQL ✅ Redis ✅
- **分支**：fix/regression-2026-08-04
- **运行命令**：`cd harness && timeout 180 node tests/chains/sales-receipt-flow.test.js`

---

## 切片信息

| 字段 | 值 |
|---|---|
| sliceId | 2.1 |
| name | sales-receipt-flow（销售→出库→收款 链路） |
| type | chain-integration |
| risk | P0（影响销售/出库/收款核心主链路） |
| effort | M |
| assertions | 3（2 通过 / 1 失败） |
| passRate | **66.7%** |
| duration | ~3s（被 0.3 客户创建失败阻断） |

---

## 跑测结果

| # | 用例 | 结果 | 备注 |
|---|---|---|---|
| 0.1 | 创建仓库 | ✅ PASS | id=2084351888152616962 |
| 0.2 | 创建物料 | ✅ PASS | id=2084351888244891650 |
| 0.3 | 创建客户 | ❌ FAIL | **阻断**：创建后查询失败，`Unknown column 'invoice_title' in 'field list'` |
| 0.4 | 创建并审核期初入库 | ⏸ SKIP | 因 0.3 失败而中止 |
| 0.5 | 记录期初库存 | ⏸ SKIP | 因 0.3 失败而中止 |
| 1.1 | 创建销售订单 | ⏸ SKIP | 因 0.3 失败而中止 |
| 2.1 | 审核订单 | ⏸ SKIP | 因 0.3 失败而中止 |
| 2.2 | 订单状态校验 | ⏸ SKIP | 因 0.3 失败而中止 |
| 3.1 | 创建销售出库 | ⏸ SKIP | 因 0.3 失败而中止 |
| 4.1 | 审核出库 | ⏸ SKIP | 因 0.3 失败而中止 |
| 5.1 | 库存减少正确 | ⏸ SKIP | 因 0.3 失败而中止 |
| 5.2 | 库存台账查询 | ⏸ SKIP | 因 0.3 失败而中止 |
| 5.3 | 库存台账出库=10 | ⏸ SKIP | 因 0.3 失败而中止 |
| 6.1 | 应收单生成 | ⏸ SKIP | 因 0.3 失败而中止 |
| 6.2 | 应收金额校验 | ⏸ SKIP | 因 0.3 失败而中止 |
| 7.1 | 创建收款单 | ⏸ SKIP | 因 0.3 失败而中止 |
| 8.1 | 清理测试数据 | ⏸ SKIP | 因 0.3 失败而中止 |

**汇总**：实际执行 3 用例（0.1/0.2/0.3），其中 **2 通过 / 1 失败**，通过率 **66.7%**。

---

## 失败明细

### ❌ 0.3 创建客户 — SQL 列缺失

**失败链路**：POST `/mes/basic/customer/add` 返回 200（创建成功），但随后的 `GET /mes/basic/customer/list?pageSize=200` 查询时报错。

**原始错误**：

```
java.sql.SQLSyntaxErrorException: Unknown column 'invoice_title' in 'field list'

SQL: SELECT id, code, name, type, grade, credit_limit, salesman_id,
            industry, region, scale, invoice_title, tax_no, bank_name,
            bank_account, invoice_address, invoice_phone, invoice_type,
            contact, phone, address, status, remark, create_by, create_time,
            update_by, update_time, del_flag
     FROM c_mes_customer WHERE del_flag = 0 LIMIT ?
```

**根因**：

- `MesCustomer` 实体（2026-07-10 升级）已新增 13 个财务/分类字段（grade / creditLimit / salesmanId / industry / region / scale / invoiceTitle / taxNo / bankName / bankAccount / invoiceAddress / invoicePhone / invoiceType）
- MyBatis-Plus 自动生成的 SELECT 包含全部实体字段
- 数据库表 `c_mes_customer` 仅保留了初始建表的 13 列，**`V1.0.0__mes_customer_upgrade.sql` 升级脚本（13 列 ADD COLUMN）从未执行**
- 因此 list 接口查询报错，所有客户相关查询/导出/操作都不可用

**手动复现**：

```bash
TOKEN=$(curl -s -X POST http://localhost:8080/jeecg-boot/sys/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"123456"}' | jq -r '.result.token')

curl "http://localhost:8080/jeecg-boot/mes/basic/customer/list?pageSize=5" \
  -H "X-Access-Token: $TOKEN"
# → {"success":false,"message":"...Unknown column 'invoice_title' in 'field list'..."}
```

**影响面**：

| 模块 | 影响 |
|---|---|
| `mes/basic/customer/*` | 列表/详情/导入/导出 **全部 500** |
| 销售订单（`mes/sales/order`） | 选择客户下拉 **空**（依赖 list 接口） |
| 销售出库（`mes/sales/outbound`） | 同上 |
| 应收单（`mes/finance/receivable`） | 客户字段无法填充 |
| 收款单（`mes/finance/collection`） | 同上 |
| 销售→出库→收款 全链路 | **整条链路阻断** |

**建议修复**（不在本次 scope，仅记录）：

1. 在 dev DB 上手工执行 `jeecg-boot-module/project-mes/db/V1.0.0__mes_customer_upgrade.sql`
2. 检查 supplier 表是否也存在同样问题（`MesSupplier.invoiceTitle` 也已加字段）
3. 增加 schema 漂移检测：CI 比对 entity 字段 vs DB 实际列

---

## 新发现 Bug

| ID | 严重度 | 模块 | 描述 | 状态 |
|---|---|---|---|---|
| **BUG-CUSTOMER-SCHEMA-DRIFT** | **P0** | MES 客户 | `c_mes_customer` 缺失 13 个字段（grade / credit_limit / salesman_id / industry / region / scale / invoice_title / tax_no / bank_name / bank_account / invoice_address / invoice_phone / invoice_type），导致客户模块全功能 500 | 待修复 |
| BUG-CUSTOMER-RELATED-CASCADE | P1 | 销售/应收/收款 | 因客户表不可用，依赖客户下拉的销售订单、销售出库、应收单、收款单业务全链路阻断 | 依赖 BUG-CUSTOMER-SCHEMA-DRIFT |

> **结论**：本次 slice 2.1 没有暴露销售/出库/收款主链路的业务 bug，但因底层 schema 漂移被完全阻断。一旦客户表修复，**预计整条链路可以通过**（链路结构本身与 slice 1.2 验证过的采购入库链路同构）。

---

## 下一步建议

1. **【紧急 P0】** 手动应用 `V1.0.0__mes_customer_upgrade.sql` 到 dev MySQL，并校验 supplier 表是否也有相同漂移
2. **【建议 P1】** 给所有 KA 项目模块加一个启动健康检查：自动比对 entity 字段 vs DB schema，启动时报错而非运行时 500
3. **【建议 P1】** 在 CI 中加一条 schema 漂移测试（`harness/tests/system/schema-drift.test.js`），遍历 entity @TableName 表，比对字段完整性
4. **【跟进】** Schema 修复后重跑本切片，期望从 2/3 通过提升至全量通过，再依此推进 slice 2.2/2.3
5. **【复盘】** 整套 `fix/regression-2026-08-04` 分支已多次修复代码侧 bug（slice 1.1-1.3），但基础数据 schema 漂移未在早期发现 —— 应在每个 slice 启动前做 schema baseline 检查

---

**报告完成时间**：2026-08-04  
**生成者**：claude-sonnet-4.5 (verification agent)  
**关联**：`harness/tests/chains/sales-receipt-flow.test.js` | `.claude/plans/2026-08-04-mes-regression-plan.md`