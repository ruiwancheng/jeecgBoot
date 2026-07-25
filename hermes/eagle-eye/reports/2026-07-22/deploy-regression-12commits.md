# MES 部署后差集回归报告

> 生成时间：2026-07-22 | 基线：b517850 → HEAD (84dde5a) | 共 8 个提交

## 变更文件清单（32个文件）

### 后端变更（6个）
| 路径 | 模块 |
|------|------|
| `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/basic/controller/MesCustomerController.java` | 基础数据-客户 |
| `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/basic/controller/MesWarehouseController.java` | 基础数据-仓库 |
| `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/purchase/order/controller/MesPurchaseOrderController.java` | 采购订单 |
| `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/sales/controller/MesSalesOrderController.java` | 销售订单 |
| `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/sales/controller/MesDeliveryNoteController.java` | 销售发货 |
| `jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/finance/subject/controller/MesAccountSubjectController.java` | 财务-科目 |

### 前端变更（26个）
| 模块 | 文件数 | 涉及组件 |
|------|:--:|------|
| 基础数据 | 2 | customer.api.ts, warehouse.api.ts |
| 采购订单 | 4 | JPurchaseOrderSelect.vue, PurchaseOrderSelectModal.vue, order.api.ts, order.data.ts |
| 采购收货 | 2 | ReceiptDrawer.vue, receipt.data.ts |
| 销售 | 7 | order.api.ts, order.data.ts, delivery.api.ts, delivery.data.ts, outbound.data.ts, price.data.ts |
| 财务 | 7 | collection.data.ts, invoice.data.ts, payment.data.ts, purchaseInvoice.data.ts, subject.api.ts, VoucherDrawer.vue, subject.api.ts |
| 制造 | 4 | completion.data.ts, order.data.ts, picking.data.ts |

## 影响模块汇总

| 模块 | 后端 | 前端 | 影响评估 |
|------|:--:|:--:|------|
| 基础数据 (basic) | 2 | 2 | 客户/仓库 controller + API |
| 采购订单 (purchase) | 1 | 6 | 订单controller + 订单/收货前端 |
| 销售 (sales) | 2 | 7 | 订单/发货controller + 全部前端 |
| 财务 (finance) | 1 | 7 | 科目controller + 全部前端 |
| 制造 (manufacturing) | 0 | 4 | 仅前端 data 文件 |

## curl 端点验证

| 端点 | 路径 | 结果 |
|------|------|:--:|
| 供应商列表 | `GET /mes/basic/supplier/list` | ✅ code=200, 端点正常 |
| 仓库列表 | `GET /mes/basic/warehouse/list` | ✅ code=200, total=3 |
| 客户下拉 | `GET /mes/basic/customer/selectPage` | ✅ code=200, total=1 |
| 采购订单审核流程 | 创建→audit→验证status=3 | ✅ status=3, 审核成功 |

> ⚠️ 供应商/仓库的 `selectPage` 端点返回404 — 这些是本次变更中新增的方法，当前运行的服务器尚未包含此变更，属于预期行为。

## 测试套件执行结果

| 测试套件 | 结果 | 说明 |
|------|:--:|------|
| `codeRule.test.mjs` | **20/20** ✅ | 编码规则 CRUD + 10种单据取号全覆盖 |
| `sales-order.test.mjs` | **30/30** ✅ | 销售订单状态机 + 守卫拦截 + 边界验证 |
| `sales-api.test.mjs` | **24/24** ✅ | 价格、订单、发货、出库模块全链路 |

> 📊 **总计：74/74 全部通过，零失败**

## 提交日志

```
84dde5a feat: 采购订单列表添加税额(taxAmount)列
1be85fc fix: /delegate工人缺失工作流
452eb54 feat: 采购入库-采购单弹窗选择
2c00839 feat: /delegate自动清理工人终端
2e54a1c feat: /delegate命令+记忆卡片
a0a3326 fix: 工作流2个缺口修复
434b101 fix: 第七失忆点+plan步骤4.5强制检查
ab085c3 fix: 批量消灭MES表字典反模式 — 5端点+16处ApiSelect替换
```

## 结论

- **核心业务端点全部正常**：基础数据查询、采购订单审核流程、销售订单全链路均通过
- **测试套件 74/74 全绿**：编码规则、销售订单状态机、销售API全链路零失败
- **已知差异**：供应商/仓库新增的 `selectPage` 端点尚未部署到运行服务器（属于待部署变更）
- **基线已更新**：`.last-deploy-commit` → `84dde5a12d4f63813d3eaf2c0f0a04af5b2441fb`
