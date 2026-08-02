# 实施计划：生产批次号手工录入模式

**日期**：2026-08-01
**前置需求**：`/brainstorm` 澄清结果（v1.0 定稿）
**前置依赖**：切片 A/B/C/D 全部完成（总开关+物料开关降级链已就位）

## 目标

把"系统自动生成批次号"改为"操作员手工录入批次号"，匹配供应商/生产线的实际业务场景。同步修正批次号唯一性约束（应按物料隔离）。

## 切片设计（3 片串行，每片可独立验证）

| 切片 | 内容 | 风险 | 依赖 |
|------|------|------|------|
| **E1：数据库 + 实体** | SQL 迁移（删/建唯一索引、删历史数据）+ 2 个 Item 实体加 2 字段 | 中 | A |
| **E2：后端 Service 集成** | 拆 `createBatchWithManualNo` 方法 + 4 个 Service 改调 | 中 | E1 |
| **E3：前端表单接入** | 2 个 Drawer 加 2 字段（条件显示）+ 校验 + E2E | 中 | E2 |

---

## 切片 E1：数据库 + 实体

### 文件清单

| 操作 | 路径 | 改动 |
|------|------|------|
| 新建 | `jeecg-boot/jeecg-boot-module/project-mes/db/V8.0.3__mes_batch_manual_no.sql` | 迁移 SQL |
| 修改 | `jeecg-boot/.../purchase/receipt/entity/MesPurchaseReceiptItem.java` | 加 2 字段 |
| 修改 | `jeecg-boot/.../manufacturing/completion/entity/MesCompletionReceiptItem.java` | 加 2 字段 |

### SQL 迁移内容（V8.0.3）

```sql
-- ============================================================
-- V8.0.3 生产批次号手工录入 + 唯一索引隔离
-- ============================================================

-- 1) 先清历史数据（用户要求"历史数据直接删除"）
DELETE FROM c_mes_batch_ledger;
DELETE FROM c_mes_batch_inventory;
DELETE FROM c_mes_batch;

-- 2) 删旧的全表唯一索引
ALTER TABLE c_mes_batch DROP INDEX uk_batch_no_del;

-- 3) 加新的组合唯一索引（按物料隔离）
ALTER TABLE c_mes_batch
  ADD UNIQUE INDEX uk_batch_material_no_del (material_id, batch_no, del_flag);

-- 4) 采购入库行加批次号 + 生产日期（MySQL 5.7 兼容：先查列是否存在）
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'batch_no');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN batch_no VARCHAR(50) DEFAULT NULL COMMENT ''生产批次号(手工录入)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_purchase_receipt_item' AND column_name = 'production_date');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_purchase_receipt_item ADD COLUMN production_date DATE DEFAULT NULL COMMENT ''生产日期''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 5) 完工入库行加同样 2 字段
SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_completion_receipt_item' AND column_name = 'batch_no');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_completion_receipt_item ADD COLUMN batch_no VARCHAR(50) DEFAULT NULL COMMENT ''生产批次号(手工录入)''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @col_exists = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'c_mes_completion_receipt_item' AND column_name = 'production_date');
SET @sql = IF(@col_exists = 0,
  'ALTER TABLE c_mes_completion_receipt_item ADD COLUMN production_date DATE DEFAULT NULL COMMENT ''生产日期''',
  'SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 6) 更新表注释（c_mes_batch.batch_no 含义从"系统生成"改为"手工录入"）
ALTER TABLE c_mes_batch
  MODIFY COLUMN batch_no VARCHAR(50) NOT NULL COMMENT '批次号(手工录入，不同物料可重号)';
```

### 实体改动（2 文件，模式相同）

`MesPurchaseReceiptItem.java`：
```java
// 现有字段后追加
@Schema(description = "生产批次号(手工录入)")
private String batchNo;
@JsonFormat(timezone = "GMT+8", pattern = "yyyy-MM-dd")
@DateTimeFormat(pattern = "yyyy-MM-dd")
@Schema(description = "生产日期")
private Date productionDate;
```

`MesCompletionReceiptItem.java`：同样追加 2 字段。

### 验证

- [ ] `mvn compile` 编译通过
- [ ] SQL 迁移在本地 MySQL 5.7 + 干净环境/已有数据环境都过
- [ ] `SHOW INDEX FROM c_mes_batch` 确认新索引 `uk_batch_material_no_del` 存在，旧索引 `uk_batch_no_del` 已删
- [ ] 2 个 Item 表的 `batch_no` + `production_date` 字段存在
- [ ] 历史 7 条 `c_mes_batch` 数据已删（`SELECT COUNT(*)` = 0）

---

## 切片 E2：后端 Service 集成

### 文件清单

| 操作 | 路径 | 改动 |
|------|------|------|
| 修改 | `jeecg-boot/.../batch/master/service/IMesBatchService.java` | 接口拆方法 |
| 修改 | `jeecg-boot/.../batch/master/service/impl/MesBatchServiceImpl.java` | 实现新方法 + 标老方法 Deprecated |
| 修改 | `jeecg-boot/.../purchase/receipt/service/impl/MesPurchaseReceiptServiceImpl.java` | 改调 `createBatchWithManualNo` |
| 修改 | `jeecg-boot/.../manufacturing/completion/service/impl/CompletionReceiptServiceImpl.java` | 同上 |
| **修改（评审补）** | `jeecg-boot/.../batch/master/controller/MesBatchController.java` | `.add()` 改调新方法（当 batchNo 非空时用，为空时自动生成兑底） |

### IMesBatchService 接口设计

```java
public interface IMesBatchService extends IService<MesBatch> {
    /**
     * 【已废弃】老接口：自动生成批次号。仅用于外部系统兼容
     * @deprecated use {@link #createBatchWithManualNo} instead
     */
    @Deprecated
    String createBatch(String materialId, String originType, String originBillId, String originBillNo,
                       BigDecimal qty, BigDecimal unitCost, Date productionDate, Date expiryDate);

    /**
     * 创建批次（手工录入批次号）
     * @param batchNo 手工录入的批次号（必填，≤50 字符）
     * @throws JeecgBootException 当 (materialId, batchNo) 已存在时
     */
    String createBatchWithManualNo(String materialId, String batchNo, String originType,
                                    String originBillId, String originBillNo,
                                    BigDecimal qty, BigDecimal unitCost,
                                    Date productionDate, Date expiryDate);

    void freeze(String id, String operator);
    void unfreeze(String id, String operator);
}
```

### `createBatchWithManualNo` 实现关键逻辑

```java
@Override
@Transactional(rollbackFor = Exception.class)
public String createBatchWithManualNo(String materialId, String batchNo, ...) {
    // 1) 参数校验
    if (!StringUtils.hasText(materialId)) throw new JeecgBootException("物料不能为空");
    if (!StringUtils.hasText(batchNo)) throw new JeecgBootException("生产批次号不能为空");
    if (batchNo.length() > 50) throw new JeecgBootException("生产批次号长度不能超过50个字符");
    if (qty == null || qty.compareTo(BigDecimal.ZERO) <= 0) throw new JeecgBootException("批次数量必须大于0");

    // 2) 物料主档行锁（与老 createBatch 一致）
    MesMaterial mat = materialMapper.selectByIdForUpdate(materialId);
    if (mat == null) throw new JeecgBootException("物料不存在");

    // 3) 业务层查重（数据库 uk_batch_material_no_del 也会兜底）
    QueryWrapper<MesBatch> dupCheck = new QueryWrapper<>();
    dupCheck.eq("material_id", materialId)
            .eq("batch_no", batchNo)
            .eq("del_flag", 0);
    if (this.count(dupCheck) > 0) {
        throw new JeecgBootException("批次号 " + batchNo + " 在物料 " + mat.getCode() + " 下已存在");
    }

    // 4) 写主档（用传入的 batchNo，不再自动生成）
    MesBatch batch = new MesBatch();
    batch.setBatchNo(batchNo)
         .setMaterialId(materialId)
         .setOriginType(originType)
         .setOriginBillId(originBillId)
         .setOriginBillNo(originBillNo)
         .setQty(qty)
         .setUnitCost(unitCost)
         .setProductionDate(productionDate)
         .setExpiryDate(expiryDate)
         .setStatus("1");
    this.save(batch);

    // 5) 写流水（与老 createBatch 一致）
    ledgerService.writeLedger(batch.getId(), batchNo, materialId, "",
        originType, originBillId, originBillNo, qty, BigDecimal.ZERO, unitCost, "批次创建");

    return batch.getId();
}
```

老 `createBatch` 标 `@Deprecated`，内部委托给 `createBatchWithManualNo(materialId, 自动生成, ...)`——保留兼容，3-6 个月后删除。

### Service 调用点改动（2 文件）

`MesPurchaseReceiptServiceImpl.audit` 第 188-194 行：

```java
// 旧
String batchId = batchService.createBatch(
    item.getMaterialId(), "1",
    e.getId(), e.getCode(),
    item.getReceiptQuantity(), unitCost,
    null, null);

// 新
String batchId = batchService.createBatchWithManualNo(
    item.getMaterialId(),
    item.getBatchNo(),     // 从明细行取
    "1",
    e.getId(), e.getCode(),
    item.getReceiptQuantity(), unitCost,
    item.getProductionDate(),  // 从明细行取
    null);
```

`CompletionReceiptServiceImpl.audit` 第 145 行类似改。

### 验证

- [ ] `mvn compile` 通过
- [ ] `mvn install` 重新打包
- [ ] 单元级：直接调 `createBatchWithManualNo`，传 null/空 batchNo 应报错
- [ ] 单元级：同物料+同 batchNo 重复调第二次应报错
- [ ] 单元级：不同物料+同 batchNo 两次都成功

---

## 切片 E3：前端表单接入

### 文件清单

| 操作 | 路径 | 改动 |
|------|------|------|
| 修改 | `jeecgboot-vue3/src/views/project/mes/purchase/receipt/ReceiptDrawer.vue` | 加 2 字段（条件显示）+ 校验 |
| 修改 | `jeecgboot-vue3/src/views/project/mes/manufacturing/completion/CompletionReceiptDrawer.vue` | 同上 |

### 关键实现

**条件显示逻辑**：

```ts
// 引入 store
import { useMesGlobalSwitchStore } from '/@/store/modules/mesGlobalSwitch';
import { useMessage } from '/@/hooks/web/useMessage';

const mesGlobalSwitchStore = useMesGlobalSwitchStore();
const { createMessage } = useMessage();

// 总开关是否开启
const isBatchOn = computed(() => mesGlobalSwitchStore.isBatchEnabled);

// 打开抽屉时加载 store
await mesGlobalSwitchStore.load();
```

**itemColumns 动态化**（按总开关+每行物料 batchEnabled 决定列显示）：

```ts
// baseColumns 不变
const baseColumns = [
  { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 180 },
  // ... 其他列
];

// itemColumns 改成 computed
const itemColumns = computed(() => {
  const cols = [...baseColumns];
  if (unref(isBatchOn)) {
    // 插入"生产批次号"+"生产日期"两列（在"本次入库数量"前）
    cols.splice(cols.length - 3, 0,
      { title: '生产批次号', dataIndex: 'batchNo', width: 160,
        slots: { customRender: 'batchNo' } },
      { title: '生产日期', dataIndex: 'productionDate', width: 120,
        slots: { customRender: 'productionDate' } },
    );
  }
  return cols;
});
```

**template 加渲染槽位**（仅在 `isBatchOn` 时显示）：

```html
<template v-if="isBatchOn" #batchNo="{ record, index }">
  <a-input
    :value="record.batchNo"
    placeholder="如：20240101-A 或厂家标签号"
    :maxlength="50"
    style="width: 100%"
    @change="(e: any) => updateItem(index, 'batchNo', e.target.value)"
  />
</template>
<template v-if="isBatchOn" #productionDate="{ record, index }">
  <a-date-picker
    :value="record.productionDate"
    valueFormat="YYYY-MM-DD"
    style="width: 100%"
    @change="(v: any) => updateItem(index, 'productionDate', v)"
  />
</template>
```

**提交时校验**（`handleSubmit`）：

```ts
async function handleSubmit() {
  const values = await validate();
  // 总开关开启时，校验每个 item 的 batchNo
  if (unref(isBatchOn)) {
    for (let i = 0; i < submitItems.length; i++) {
      const item = submitItems[i];
      // 这里"物料是否启用批次"由后端再次校验（双重保险）
      // 前端先做非空校验
      if (!item.batchNo || !item.batchNo.trim()) {
        createMessage.error(`第 ${i + 1} 行：生产批次号不能为空（物料已启用批次管理）`);
        setDrawerProps({ confirmLoading: false });
        return;
      }
      if (item.batchNo.length > 50) {
        createMessage.error(`第 ${i + 1} 行：生产批次号长度超过50个字符`);
        setDrawerProps({ confirmLoading: false });
        return;
      }
    }
  }
  // 提交...
}
```

### 物料级 batchEnabled 联动（可选增强）

由于"是否启用批次"在物料档案里，新建物料选 JMaterialSelect 时已经把物料对象带回来（`v.record.batchEnabled`）：

```ts
// 物料切换时，如果总开关关，自动跳过；如果总开关开，但物料 batchEnabled=0，提示但不强制
function onMaterialChange(i: number, v: any) {
  updateItem(i, 'materialId', v?.value ?? v);
  if (v?.record) {
    updateItem(i, 'materialCode', v.record.code || '');
    updateItem(i, 'materialName', v.record.name || '');
    // 检查物料是否启用批次
    if (unref(isBatchOn) && v.record.batchEnabled !== 1) {
      createMessage.warning(`物料 ${v.record.code} 未启用批次管理，无需填写批次号`);
    }
  }
}
```

### E2E 测试（E3 自带）

- `harness/e2e/mes/purchaseReceiptBatch.spec.ts`：
  1. 总开关开启 → 新增采购入库 → 填批次号 → 审核 → 验证 `c_mes_batch` 写入正确 batchNo
  2. 总开关关闭 → 同一流程 → 验证字段不出现 + 仍能正常入库（不写批次）
  3. 同物料重复 batchNo → 验证后端报错"批次号 X 在物料 Y 下已存在"
  4. 不同物料同 batchNo → 验证两个都成功

### 验证

- [ ] ESLint 全绿
- [ ] 总开关关闭 → 抽屉里**不显示**"生产批次号"+"生产日期"列
- [ ] 总开关开启 → 抽屉**显示**两列，必填校验生效
- [ ] 同物料重复 batchNo → 友好错误提示
- [ ] 不同物料同 batchNo → 都能保存
- [ ] E2E 4 个场景通过

---

## 总验证（3 切片都完成后）

| 项 | 验证方式 |
|----|----------|
| 后端编译 | `mvn compile -pl project-mes -am` |
| 后端打包 | `mvn install -pl project-mes -am` |
| SQL 迁移 | 干净环境 + 已有数据环境都跑一次 |
| API 测试 | 4 场景（关/开 × 同/异物料） |
| E2E 测试 | 4 场景（Playwright） |
| ESLint | `npx eslint` 全绿 |
| 现有功能回归 | 切片 A/B/C/D 的所有断言仍通过 |

## 风险与回滚（已含评审修正）

| 风险 | 缓解 |
|------|------|
| SQL DELETE 7 条数据不可逆 | **用户已明确接受**（"历史数据直接删除"）|
| 老 `createBatch` 标 Deprecated 后有外部调用 | 保留 3-6 个月观察期，JVM warning 提示；Controller 走兑底逻辑 |
| 前端条件渲染逻辑复杂 | E2E 覆盖 4 场景，含总开关切换的边界 |
| 数据库唯一索引变更影响并发 | 业务层查重（事务内）+ 行锁，串行化保护 |
| SQL 不幂等（重跑报错）| **已用 PREPARE 模式包装**（评审 P1-1 修正） |
| Controller 漏改导致用户输入被覆盖 | **评审 P0 已补 MesBatchController** |
