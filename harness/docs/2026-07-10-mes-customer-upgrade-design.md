# MES 客户模块改造设计

| 项目 | 信息 |
|------|------|
| 项目 | MES |
| 模块 | 客户管理（customer） |
| 版本 | V1.0.0 |
| 日期 | 2026-07-10 |
| 状态 | 待开发 |
| PRD 参考 | `modules/sales/02_核心逻辑.md` 第二章 · 客户管理逻辑 |

## 一、改造背景

现有客户模块（`c_mes_customer`）是一个简化的通讯录，只有 8 个基础字段，缺少 PRD 要求的客户等级、信用额度、业务员归属、多联系人、多地址、财务资料、跟进记录等能力。需要改造为支持 PRD 客户全生命周期管理的基础设施。

## 二、设计决策

| 决策点 | 选择 | 理由 |
|--------|------|------|
| 改造范围 | P0-P3 一次性到位 | 避免多次改表迁移数据 |
| 查价逻辑 | 价格表优先 → 等级折扣率兜底 | 灵活可扩展 |
| 信用额度 | 只存字段，等销售模块建好再校验 | 先建基础，按需激活 |
| 业务员归属 | 单业务员关联 sys_user | 简单够用 |
| 页面布局 | Tab 页签式（联系人/地址/财务/跟进） | JeecgBoot 标准主子表模式 |
| 表变更 | 直接 ALTER TABLE | 改动集中，不用扩展表 |
| 价格表 | 客户+产品→单价，预留有效期和阶梯字段 | 先上最小版本 |

## 三、数据模型

### 3.1 修改：c_mes_customer（加 12 字段）

```sql
ALTER TABLE c_mes_customer
  -- 等级与额度
  ADD COLUMN grade        VARCHAR(32)  COMMENT '客户等级(dict:mes_customer_grade)',
  ADD COLUMN credit_limit DECIMAL(18,2) COMMENT '信用额度',
  -- 归属
  ADD COLUMN salesman_id  VARCHAR(36)  COMMENT '所属业务员(sys_user.id)',
  -- 分类
  ADD COLUMN industry     VARCHAR(32)  COMMENT '行业(dict:mes_customer_industry)',
  ADD COLUMN region       VARCHAR(32)  COMMENT '区域(dict:mes_customer_region)',
  ADD COLUMN scale        VARCHAR(32)  COMMENT '企业规模(dict:mes_customer_scale)',
  -- 财务资料
  ADD COLUMN invoice_title  VARCHAR(200) COMMENT '发票抬头',
  ADD COLUMN tax_no         VARCHAR(50)  COMMENT '税号',
  ADD COLUMN bank_name      VARCHAR(100) COMMENT '开户银行',
  ADD COLUMN bank_account   VARCHAR(50)  COMMENT '银行账号',
  ADD COLUMN invoice_address VARCHAR(300) COMMENT '开票地址',
  ADD COLUMN invoice_phone  VARCHAR(30)  COMMENT '开票电话',
  ADD COLUMN invoice_type   VARCHAR(10)  COMMENT '发票类型(dict:invoice_type)';
```

### 3.2 新建表

#### c_mes_customer_contact（联系人）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | varchar(36) PK | ASSIGN_ID |
| customer_id | varchar(36) | 客户ID |
| name | varchar(50) | 姓名 |
| title | varchar(50) | 职务 |
| phone | varchar(20) | 手机 |
| email | varchar(100) | 邮箱 |
| social | varchar(100) | QQ/微信 |
| is_default | tinyint | 是否默认联系人 |
| remark | varchar(200) | 备注 |
| create_by/time, update_by/time, del_flag | — | 标准字段 |

#### c_mes_customer_address（地址）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | varchar(36) PK | ASSIGN_ID |
| customer_id | varchar(36) | 客户ID |
| address_type | varchar(20) | 地址类型(dict:address_type) |
| contact | varchar(50) | 联系人 |
| phone | varchar(20) | 联系电话 |
| province | varchar(50) | 省 |
| city | varchar(50) | 市 |
| district | varchar(50) | 区 |
| detail | varchar(300) | 详细地址 |
| is_default | tinyint | 是否默认地址 |
| remark | varchar(200) | 备注 |
| create_by/time, update_by/time, del_flag | — | 标准字段 |

#### c_mes_customer_follow_up（跟进记录）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | varchar(36) PK | ASSIGN_ID |
| customer_id | varchar(36) | 客户ID |
| follow_type | varchar(20) | 跟进方式(dict:follow_type) |
| follow_date | datetime | 跟进日期 |
| content | text | 跟进内容 |
| follower | varchar(36) | 跟进人(sys_user.id)，默认当前用户 |
| next_date | datetime | 下次跟进日期 |
| attachment | varchar(500) | 附件路径 |
| remark | varchar(200) | 备注 |
| create_by/time, update_by/time, del_flag | — | 标准字段 |

#### c_mes_customer_price（客户价格表）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | varchar(36) PK | ASSIGN_ID |
| customer_id | varchar(36) | 客户ID |
| product_id | varchar(36) | 产品ID（先存编码，等物料模块建好再改外键） |
| price | decimal(18,2) | 协议单价 |
| begin_date | datetime | 生效日期（预留） |
| end_date | datetime | 失效日期（预留） |
| min_qty | decimal(18,2) | 起订数量（预留） |
| max_qty | decimal(18,2) | 截止数量（预留） |
| remark | varchar(200) | 备注 |
| create_by/time, update_by/time, del_flag | — | 标准字段 |

### 3.3 新建字典

| 字典编码 | 字典名称 | 字典项 |
|----------|----------|--------|
| mes_customer_grade | 客户等级 | VIP(0.8) / 高级(0.9) / 普通(1.0) / 潜在(1.0) |
| mes_customer_industry | 客户行业 | 制造业/零售业/电子商务/信息技术/建筑业/... |
| mes_customer_region | 客户区域 | 华东/华南/华北/华中/西南/西北/东北 |
| mes_customer_scale | 企业规模 | 大型/中型/小型/微型 |
| address_type | 地址类型 | 收货地址/发票地址/办公地址 |
| follow_type | 跟进方式 | 电话/拜访/邮件/其他 |
| invoice_type | 发票类型 | 增值税专用发票/增值税普通发票 |

> 现有 `mes_customer_type` 字典删除"供应商"选项，供应商归属分销模块。

## 四、后端设计

### 4.1 Entity

- 修改 `MesCustomer`：新增 12 个字段 + 对应的 `@Dict`、`@Excel` 注解
- 新建 `MesCustomerContact`、`MesCustomerAddress`、`MesCustomerFollowUp`、`MesCustomerPrice`

### 4.2 Controller

- 修改 `MesCustomerController`：无变化，标准 CRUD 由继承的 `JeecgController` 提供
- 新建 `MesCustomerContactController`：标准 CRUD + list 按 customer_id 筛选
- 新建 `MesCustomerAddressController`：标准 CRUD + list 按 customer_id 筛选
- 新建 `MesCustomerFollowUpController`：标准 CRUD + list 按 customer_id 筛选
- 新建 `MesCustomerPriceController`：标准 CRUD + list 按 customer_id 筛选

### 4.3 Service

- `MesCustomerServiceImpl`：保持现有"借尸还魂"编码唯一性校验，不做额外业务逻辑
- 四个新建 Service：标准 SimpleServiceImpl 即可，无特殊业务逻辑
- **查价方法预留**：在 `IMesCustomerService` 中预留 `getPrice(customerId, productId)` 接口，本次返回 null，等物料模块建设后实现"价格表 → 等级折扣率"逻辑

### 4.4 API 路径

| Controller | 路径 |
|------------|------|
| MesCustomerController | `/mes/basic/customer`（不变） |
| MesCustomerContactController | `/mes/basic/customer/contact` |
| MesCustomerAddressController | `/mes/basic/customer/address` |
| MesCustomerFollowUpController | `/mes/basic/customer/followUp` |
| MesCustomerPriceController | `/mes/basic/customer/price` |

## 五、前端设计

### 5.1 页面结构

沿用现有 `index.vue` + `CustomerDrawer.vue` + `.api.ts` + `.data.ts` 模式。

**列表页改动：**
- 搜索区新增：客户等级、业务员、行业、区域
- 列表列新增：等级、业务员、行业、区域

**编辑抽屉改动：**
- 主表单区域：基础信息 + 分类归属（等级/业务员/行业/区域/规模）+ 信用额度 + 财务资料
- 底部 Tabs（4个）：联系人子表 | 地址子表 | 价格表 | 跟进记录子表
- 每个 Tab 内嵌独立的 BasicTable + 新增/编辑弹出

### 5.2 文件清单

```
src/views/project/mes/basic/customer/
├── index.vue              # 列表页（改）
├── CustomerDrawer.vue     # 编辑抽屉（改，重构为Tab布局）
├── customer.api.ts        # 接口定义（改，新增子表接口）
├── customer.data.ts       # 列/表单Schema（改）
├── ContactTab.vue         # 联系人Tab（新）
├── AddressTab.vue         # 地址Tab（新）
├── FollowUpTab.vue        # 跟进记录Tab（新）
├── PriceTab.vue           # 价格表Tab（新）
├── contact.data.ts        # 联系人表单/列Schema（新）
├── address.data.ts        # 地址表单/列Schema（新）
├── followUp.data.ts       # 跟进记录表单/列Schema（新）
├── price.data.ts          # 价格表表单/列Schema（新）
```

## 六、菜单与路由

### 6.1 菜单注册

在 `MesMenuRegistry.buildMenus()` 中无需新增菜单——客户管理页面已存在，本次只改造页面内容。

### 6.2 路由

`mes.ts` 路由文件无需改动，客户管理路由已存在：`/project/mes/basic/customer`。

## 七、查价逻辑设计（预留）

等物料模块（产品）和销售订单模块建好后，再实现具体查价逻辑：

```java
// 伪代码，本次不实现
public BigDecimal getPrice(String customerId, String productId) {
    // 1. 查价格表 c_mes_customer_price
    MesCustomerPrice price = priceMapper.selectOne(customerId, productId);
    if (price != null) return price.getPrice();
    // 2. 查客户等级折扣率
    MesCustomer customer = getById(customerId);
    String gradeCode = customer.getGrade();
    BigDecimal discountRate = getGradeDiscount(gradeCode);
    // 3. 查产品标准售价
    BigDecimal standardPrice = productService.getStandardPrice(productId);
    return standardPrice.multiply(discountRate);
}
```

## 八、验收标准

| 验收项 | 标准 |
|--------|------|
| 客户主表 | 列表+搜索+新增+编辑+删除+导出+导入，新字段正常显示和工作 |
| 联系人子表 | 新增/编辑/删除联系人，按客户ID筛选 |
| 地址子表 | 新增/编辑/删除地址，支持省市区级联选择 |
| 跟进记录 | 新增/编辑/删除跟进记录，跟进人自动填当前用户 |
| 价格表 | 新增/编辑/删除价格记录，按客户ID筛选 |
| 字典 | 6 个新字典正常工作，前端下拉正确渲染 |
| 编码唯一性 | 现有"借尸还魂"逻辑不受影响 |
| 旧数据兼容 | 已有客户数据不受 ALTER TABLE 影响 |

---

*设计文档 V1.0.0*  
*编制日期：2026-07-10*  
*编制人：赤兔*
