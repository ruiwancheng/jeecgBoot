# MES 分销/供销 MVP 设计方案

| 项目 | 信息 |
|------|------|
| 项目 | MES |
| 模块 | 采购链路（采购申请 + 采购订单 + 采购入库 + 库存台账） |
| 阶段 | 第一阶段（MVP 核心跑通） |
| 日期 | 2026-07-16 |
| PRD 来源 | `01PRD/modules/distribution/` |

---

## 一、设计决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 审批流 | **简化为状态机**（草稿→已提交→已审批），不做多级Flowable | 第一阶段不做复杂流程 |
| 预算控制 | **跳过** | 业财管控模块未建 |
| 采购入库质检 | **跳过**，直接入库 | 质量管理属第三阶段 |
| 入库生成应付 | **跳过** | 财务模块未建 |
| 库存预警自动转采购 | **跳过**，只做手工录入 | MRP/预警属第二阶段 |
| 申请→订单关系 | **多对多** | 多张申请可合并到一张订单，一张申请可拆到多张订单 |
| 库存台账粒度 | **仓库+库位+物料**，不做批次/序列号 | 批次第三阶段，序列号第四阶段 |
| 菜单归属 | **新建一级菜单"采购管理"** | 与销售管理平级，sort=25 |

---

## 二、菜单布局

```
MES系统
├── 基础设置 (sort=10)
│   ├── 客户管理
│   └── 供应商管理
├── 商品 (sort=20)
│   └── 物料管理
├── 🆕 采购管理 (sort=25)
│   ├── 采购申请       (新增, V6.0.0)
│   ├── 采购订单       (新增, V7.0.0)
│   └── 采购入库       (新增, V8.0.0)
├── 仓储管理 (sort=30)
│   ├── 仓库管理
│   ├── 库位管理
│   ├── 库存台账       (新增, V9.0.0)
│   └── 销售出库
└── 销售管理 (sort=40)
    ├── 价格管理
    ├── 销售订单
    └── 发货单
```

---

## 三、数据库设计

### 3.1 采购申请 — c_mes_purchase_request + c_mes_purchase_request_item

**主表 c_mes_purchase_request**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) PK | 主键 |
| request_no | VARCHAR(50) UNIQUE | 申请单号，自动生成 |
| dept_id | VARCHAR(36) | 申请部门（sys_depart.id） |
| applicant_id | VARCHAR(36) | 申请人（sys_user.id） |
| request_date | DATE | 申请日期 |
| required_date | DATE | 需求日期 |
| status | VARCHAR(20) | 状态：draft/submitted/approved/rejected |
| remark | VARCHAR(500) | 备注 |
| create_by/update_by/create_time/update_time | — | 公共字段 |
| del_flag | INT | 逻辑删除 |

**明细表 c_mes_purchase_request_item**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) PK | 主键 |
| request_id | VARCHAR(36) FK | 申请单ID |
| material_id | VARCHAR(36) | 物料ID（mes_material.id） |
| quantity | DECIMAL(18,4) | 申请数量 |
| unit | VARCHAR(20) | 单位 |
| ordered_qty | DECIMAL(18,4) | 已转订单数量 |
| purpose | VARCHAR(200) | 用途说明 |
| sort_no | INT | 行号 |

### 3.2 采购订单 — c_mes_purchase_order + c_mes_purchase_order_item

**主表 c_mes_purchase_order**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) PK | 主键 |
| order_no | VARCHAR(50) UNIQUE | 订单编号，自动生成 |
| supplier_id | VARCHAR(36) | 供应商ID（mes_supplier.id） |
| order_date | DATE | 订单日期 |
| delivery_date | DATE | 交货日期 |
| payment_terms | VARCHAR(50) | 付款条款 |
| status | VARCHAR(20) | 状态：draft/confirmed/partial_arrived/arrived/closed |
| remark | VARCHAR(500) | 备注 |
| create_by/update_by/create_time/update_time | — | 公共字段 |
| del_flag | INT | 逻辑删除 |

**明细表 c_mes_purchase_order_item**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) PK | 主键 |
| order_id | VARCHAR(36) FK | 订单ID |
| material_id | VARCHAR(36) | 物料ID |
| quantity | DECIMAL(18,4) | 订单数量 |
| unit | VARCHAR(20) | 单位 |
| unit_price | DECIMAL(18,2) | 单价 |
| tax_rate | DECIMAL(5,2) | 税率（%） |
| amount | DECIMAL(18,2) | 不含税金额 |
| tax_amount | DECIMAL(18,2) | 税额 |
| total_amount | DECIMAL(18,2) | 含税总额 |
| source_item_id | VARCHAR(36) | 来源申请明细ID（可空） |
| arrived_qty | DECIMAL(18,4) | 已入库数量 |
| sort_no | INT | 行号 |

### 3.3 采购入库 — c_mes_purchase_inbound + c_mes_purchase_inbound_item

**主表 c_mes_purchase_inbound**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) PK | 主键 |
| inbound_no | VARCHAR(50) UNIQUE | 入库单号，自动生成 |
| order_id | VARCHAR(36) | 采购订单ID |
| supplier_id | VARCHAR(36) | 供应商ID（冗余，便于汇总） |
| warehouse_id | VARCHAR(36) | 仓库ID |
| inbound_date | DATE | 入库日期 |
| status | VARCHAR(20) | 状态：draft/confirmed |
| remark | VARCHAR(500) | 备注 |
| create_by/update_by/create_time/update_time | — | 公共字段 |
| del_flag | INT | 逻辑删除 |

**明细表 c_mes_purchase_inbound_item**

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) PK | 主键 |
| inbound_id | VARCHAR(36) FK | 入库单ID |
| order_item_id | VARCHAR(36) | 订单明细ID |
| material_id | VARCHAR(36) | 物料ID |
| location_id | VARCHAR(36) | 库位ID |
| quantity | DECIMAL(18,4) | 入库数量 |
| unit | VARCHAR(20) | 单位 |
| sort_no | INT | 行号 |

### 3.4 库存台账 — c_mes_inventory

| 字段 | 类型 | 说明 |
|------|------|------|
| id | VARCHAR(36) PK | 主键 |
| warehouse_id | VARCHAR(36) | 仓库ID |
| location_id | VARCHAR(36) | 库位ID |
| material_id | VARCHAR(36) | 物料ID |
| quantity | DECIMAL(18,4) | 当前库存数量 |
| last_inbound_time | DATETIME | 最后入库时间 |
| last_outbound_time | DATETIME | 最后出库时间 |
| create_by/update_by/create_time/update_time | — | 公共字段 |
| del_flag | INT | 逻辑删除 |

> **唯一约束：** (warehouse_id, location_id, material_id)
> **更新策略：** 入库 `+ quantity`，出库 `- quantity`

---

## 四、状态机

### 采购申请

```
草稿(draft) → 已提交(submitted) → 已审批(approved)
                    ↓
               已驳回(rejected) → 可重新编辑提交
```

### 采购订单

```
草稿(draft) → 已确认(confirmed) → 部分到货(partial_arrived) → 已到货(arrived) → 已关闭(closed)
```

- 已确认的订单可生成入库单
- 所有明细行 `arrived_qty >= quantity` 时自动变更为"已到货"

### 采购入库

```
草稿(draft) → 已审核(confirmed)
```

- 审核后触发库存台账更新

---

## 五、关键业务规则

| 规则 | 说明 |
|------|------|
| 申请→订单引用 | 采购订单可引用多张已审批申请的明细行，带入物料和数量 |
| 数量控制 | 累计转入订单的申请数量不可超过申请本身数量（`ordered_qty ≤ quantity`） |
| 入库数量控制 | 入库数量 ≤ 订单未入库数量（订单 quantity - arrived_qty） |
| 库存自动更新 | 入库审核后增加库存，销售出库审核后扣减库存 |
| 销售出库改造 | 已有销售出库（V5.0.0）需新增：审核后扣减库存台账 |
| 编码自动生成 | 申请单号/订单号/入库单号均后端自动生成，支持软删除后的"借尸还魂"模式 |

---

## 六、前端页面结构

每个模块遵循 JeecgBoot 标准 CRUD 模式：

| 模块 | 文件 |
|------|------|
| 采购申请 | `index.vue` + `RequestDrawer.vue` + `purchaseRequest.api.ts` + `purchaseRequest.data.ts` |
| 采购订单 | `index.vue` + `OrderDrawer.vue` + `purchaseOrder.api.ts` + `purchaseOrder.data.ts` |
| 采购入库 | `index.vue` + `InboundDrawer.vue` + `purchaseInbound.api.ts` + `purchaseInbound.data.ts` |
| 库存台账 | `index.vue` + `inventory.api.ts` + `inventory.data.ts`（只读查询） |

**采购订单弹出选择申请：** 使用 `BasicModal` 弹出已审批的申请明细列表，勾选后带入订单明细行。

**采购入库弹出选择订单：** 使用 `BasicModal` 弹出已确认的订单明细列表（含未入库数量），勾选后带入入库明细行。

---

## 七、后端模块结构

```
jeecg-boot/jeecg-boot-module/project-mes/src/main/java/org/jeecg/modules/mes/
├── basic/
│   └── ...                                (已有)
├── purchase/                              (新增)
│   ├── controller/
│   │   ├── MesPurchaseRequestController.java
│   │   ├── MesPurchaseOrderController.java
│   │   └── MesPurchaseInboundController.java
│   ├── entity/
│   │   ├── MesPurchaseRequest.java
│   │   ├── MesPurchaseRequestItem.java
│   │   ├── MesPurchaseOrder.java
│   │   ├── MesPurchaseOrderItem.java
│   │   ├── MesPurchaseInbound.java
│   │   └── MesPurchaseInboundItem.java
│   ├── mapper/
│   │   ├── MesPurchaseRequestMapper.java
│   │   ├── MesPurchaseRequestItemMapper.java
│   │   ├── MesPurchaseOrderMapper.java
│   │   ├── MesPurchaseOrderItemMapper.java
│   │   ├── MesPurchaseInboundMapper.java
│   │   └── MesPurchaseInboundItemMapper.java
│   └── service/
│       ├── IMesPurchaseRequestService.java
│       ├── IMesPurchaseOrderService.java
│       ├── IMesPurchaseInboundService.java
│       └── impl/
│           ├── MesPurchaseRequestServiceImpl.java
│           ├── MesPurchaseOrderServiceImpl.java
│           └── MesPurchaseInboundServiceImpl.java
├── warehouse/
│   ├── entity/MesInventory.java           (新增)
│   ├── mapper/MesInventoryMapper.java     (新增)
│   ├── service/IMesInventoryService.java  (新增)
│   └── service/impl/MesInventoryServiceImpl.java (新增)
└── sales/
    └── service/impl/MesSalesOutboundServiceImpl.java (改造：审核后扣减库存)
```

---

## 八、数据库迁移文件

| 版本 | 文件 | 说明 |
|------|------|------|
| V6.0.0 | `V6.0.0__mes_purchase_request_init.sql` | 创建采购申请表 + 字典 + 菜单权限 |
| V7.0.0 | `V7.0.0__mes_purchase_order_init.sql` | 创建采购订单表 + 字典 + 菜单权限 |
| V8.0.0 | `V8.0.0__mes_purchase_inbound_init.sql` | 创建采购入库表 + 字典 + 菜单权限 |
| V9.0.0 | `V9.0.0__mes_inventory_init.sql` | 创建库存台账表 + 菜单权限 |

---

## 九、与现有模块的关联

| 关联方向 | 说明 |
|----------|------|
| 采购订单 → 供应商（已有） | 下拉选择供应商，使用 `JSearchSelect` 组件 |
| 采购申请/订单/入库 → 物料（已有） | 下拉选择物料 |
| 采购入库 → 仓库/库位（已有） | 下拉选择仓库、库位 |
| 采购入库 → 库存台账（新增） | 审核后 + quantity |
| 销售出库 → 库存台账（改造） | 审核后 - quantity |

---

*设计文档版本：V1.0.0*
*日期：2026-07-16*
