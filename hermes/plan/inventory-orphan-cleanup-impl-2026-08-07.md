# 库存总览孤儿行清理 — 实施草案（v3）

> **配套文档**：`inventory-orphan-cleanup-2026-08-07.md`（主方案 v3）
> **用途**：阶段 1+2+4+5 的完整代码（Java / Vue / TS / SQL / Shell）
> **版本**：v3（基于 Codex v2 评审再重写，含 19 个 checker + UNION ALL + 启动自检 + 字典缓存 + 关键表行锁）

---

## § A. 阶段 1：index.vue 改造

```vue
<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #expandedRowRender="{ record }">
        <InventoryLedgerSubTable :materialId="record.material_id" :warehouseId="record.warehouse_id" />
      </template>
      <template #tableTitle>
        <span>库存总览</span>
        <span style="margin-left:16px; color:#888; font-weight:normal; font-size:13px">
          库存金额合计：<b style="color:#1677ff">{{ pageTotalAmount }}</b>
          （零库存红标，点行首 + 看最近台账）
        </span>
        <!-- 批量删除孤儿行：仅当选中含孤儿行时显示（Codex P1：扩展为 material 或 warehouse 孤儿） -->
        <a-button
          v-if="selectedOrphanKeys.length > 0"
          danger
          preIcon="ant-design:delete-outlined"
          style="margin-left:16px"
          @click="batchDeleteOrphan">
          批量删除孤儿行（{{ selectedOrphanKeys.length }}）
        </a-button>
        <!-- 导出孤儿清单：独立条件，不依赖选中行（Codex P1） -->
        <a-button
          v-if="orphanCount > 0"
          danger
          preIcon="ant-design:export-outlined"
          style="margin-left:8px"
          @click="exportOrphanXls">
          导出孤儿清单（{{ orphanCount }}）
        </a-button>
      </template>

      <!-- 现有 matText/whText/qtyTag/amountText slot 保留 -->

      <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】孤儿标识 + 仓库维度---------->
      <template #orphanTag="{ record }">
        <a-tag v-if="isOrphan(record)" color="default" :title="orphanReason(record)">孤儿行</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】孤儿标识----------->

      <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】单行删除按钮---------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
      <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】单行删除---------->
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增 imports-----------
  import { ref, computed, reactive, onMounted } from 'vue';
  import { BasicTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { message, Modal } from 'ant-design-vue';
  import { queryInventoryList, deleteOrphanInventory, batchDeleteOrphanInventory, getOrphanExportUrl, queryOrphanCount } from './inventory.api';
  import { columns, searchFormSchema } from './inventory.data';
  import InventoryLedgerSubTable from './InventoryLedgerSubTable.vue';

  defineOptions({ name: 'MesInventoryOverview' });

  const pageTotalAmount = ref('0.00');
  const orphanCount = ref(0);

  const selectedRowKeys = reactive<string[]>([]);
  const selectedRows = reactive<Recordable[]>([]);

  const rowSelection = {
    type: 'checkbox' as const,
    columnWidth: 50,
    selectedRowKeys,
    onChange(keys: string[], rows: Recordable[]) {
      selectedRowKeys.length = 0;
      selectedRowKeys.push(...keys);
      selectedRows.length = 0;
      selectedRows.push(...rows);
    },
  };

  // Codex P1：同时判 material 和 warehouse 孤儿
  function isOrphan(record: Recordable): boolean {
    return !record.material_code || !record.warehouse_name;
  }

  function orphanReason(record: Recordable): string {
    const reasons = [];
    if (!record.material_code) reasons.push('物料已删除');
    if (!record.warehouse_name) reasons.push('仓库已删除');
    return reasons.join(' / ');
  }

  const selectedOrphanKeys = computed(() =>
    selectedRows.filter(isOrphan).map((r) => r.id)
  );

  function getActions(record: Recordable) {
    if (!isOrphan(record)) return [];
    return [{
      label: '删除',
      popConfirm: {
        title: `确认删除孤儿行？\n原因：${orphanReason(record)}\nID：${record.id}`,
        confirm: () => handleDeleteOne(record),
      },
    }];
  }

  async function handleDeleteOne(record: Recordable) {
    await deleteOrphanInventory({ id: record.id });
    message.success('已删除');
    reload();
    refreshOrphanCount();
  }

  async function batchDeleteOrphan() {
    if (!selectedOrphanKeys.value.length) return;
    Modal.confirm({
      title: `确认删除 ${selectedOrphanKeys.value.length} 条孤儿行？`,
      content: '后端会写审计表，可通过 SQL rollback 命令恢复。',
      okText: '确认删除',
      okButtonProps: { danger: true },
      onOk: async () => {
        // Codex P0：POST + body 而非 query string
        await batchDeleteOrphanInventory({ ids: selectedOrphanKeys.value });
        message.success(`已删除 ${selectedOrphanKeys.value.length} 条`);
        selectedRowKeys.length = 0;
        selectedRows.length = 0;
        reload();
        refreshOrphanCount();
      },
    });
  }

  function exportOrphanXls() {
    window.open(getOrphanExportUrl());
  }

  async function refreshOrphanCount() {
    try {
      const res: any = await queryOrphanCount();
      orphanCount.value = res?.result || 0;
    } catch (e) { /* 静默 */ }
  }

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-inventory',
    tableProps: {
      title: '库存总览',
      api: queryInventoryList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
      pagination: { pageSize: 20 },
    },
  });

  const [registerTable, { reload }] = tableContext;

  onMounted(async () => {
    // 库存金额合计
    try {
      const res: any = await queryInventoryList({ pageNo: 1, pageSize: 200 });
      const total = (res?.records || []).reduce((s: number, r: any) => s + Number(r.inventory_amount || 0), 0);
      pageTotalAmount.value = total.toFixed(2);
    } catch (e) { /* 静默 */ }
    // 孤儿行总数（用于导出按钮 + 业务感知）
    refreshOrphanCount();
  });
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】index.vue 改造
</script>
```

---

## § B. 阶段 2：后端 3 端点（MesInventoryController，v3 修订 risk_type 派生）

### B.1 Controller 完整代码（v3：risk_type 从 material_del_flag 派生）

```java
//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】3 端点 + 审计 Service 注入-----------
package org.jeecg.modules.mes.basic.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.Data;
import lombok.extern.slf4j.Slf4j;
import org.apache.shiro.authz.annotation.RequiresPermissions;
import org.jeecg.common.api.vo.Result;
import org.jeecg.common.exception.JeecgBootException;
import org.jeecg.modules.mes.basic.cleanup.service.IMesInventoryCleanupAuditService;
import org.jeecg.modules.mes.basic.mapper.MesInventoryMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

@Slf4j
@Tag(name = "MES-库存总览")
@RestController
@RequestMapping("/mes/warehouse/inventory")
@Validated
public class MesInventoryController {
    @Autowired private MesInventoryMapper inventoryMapper;
    @Autowired private IMesInventoryCleanupAuditService cleanupAuditService;

    /** 单删孤儿行 */
    @DeleteMapping("/deleteOrphan")
    @RequiresPermissions("mes:inventory:deleteOrphan")
    @Transactional(rollbackFor = Exception.class)
    public Result<String> deleteOrphan(@RequestParam @NotNull String id) {
        Map<String, Object> row = inventoryMapper.selectOrphanById(id);
        if (row == null) throw new JeecgBootException("该库存行不是孤儿行，禁止删除");
        BigDecimal qty = (BigDecimal) row.get("current_qty");
        if (qty != null && qty.compareTo(BigDecimal.ZERO) > 0) {
            throw new JeecgBootException("孤儿行有库存(" + qty + ")，禁止删除");
        }
        inventoryMapper.deleteById(id);
        // v3：risk_type 从 material_del_flag 派生（不再硬编码 "B2"）
        String riskType = deriveRiskType(row);
        cleanupAuditService.log("ui-single", id,
            (String) row.get("material_id"),
            (String) row.get("warehouse_id"),
            qty, riskType, getCurrentUsername());
        return Result.ok("已删除");
    }

    @Data
    public static class BatchDeleteOrphanRequest {
        @NotEmpty(message = "ids 不能为空")
        @Size(max = 500, message = "单批最多 500 条")
        private List<@NotNull String> ids;
    }

    @PostMapping("/batchDeleteOrphan")
    @RequiresPermissions("mes:inventory:batchDeleteOrphan")
    @Transactional(rollbackFor = Exception.class)
    public Result<String> batchDeleteOrphan(@RequestBody @Valid BatchDeleteOrphanRequest req) {
        List<String> idList = req.getIds();
        List<Map<String, Object>> orphans = inventoryMapper.selectOrphansByIds(idList);
        for (Map<String, Object> row : orphans) {
            BigDecimal qty = (BigDecimal) row.get("current_qty");
            if (qty != null && qty.compareTo(BigDecimal.ZERO) > 0) {
                throw new JeecgBootException("孤儿行 " + row.get("id") + " 有库存(" + qty + ")，禁止批量删");
            }
        }
        for (Map<String, Object> row : orphans) {
            inventoryMapper.deleteById(row.get("id"));
            String riskType = deriveRiskType(row);  // v3 派生
            cleanupAuditService.log("ui-batch", (String) row.get("id"),
                (String) row.get("material_id"),
                (String) row.get("warehouse_id"),
                (BigDecimal) row.get("current_qty"), riskType, getCurrentUsername());
        }
        return Result.ok("已删除 " + orphans.size() + " 条");
    }

    @GetMapping("/exportOrphanXls")
    @RequiresPermissions("mes:inventory:export")  // v3：第 3 个 addPerms 已在 MesMenuRegistry
    public void exportOrphanXls(HttpServletResponse response) throws Exception {
        List<Map<String, Object>> orphans = inventoryMapper.selectOrphansForExport(10000);
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", "attachment; filename=orphan_inventory.xlsx");
        // EasyExcel 流式写入
    }

    @GetMapping("/orphanCount")
    @RequiresPermissions("mes:inventory:list")
    public Result<Long> orphanCount() {
        return Result.ok(inventoryMapper.countOrphans());
    }

    /** v3：risk_type 派生（A2=物料硬删 + qty=0 / B2=物料软删 + qty=0） */
    private String deriveRiskType(Map<String, Object> row) {
        Integer materialDelFlag = (Integer) row.get("material_del_flag");
        // material_id 为 null OR del_flag=1 → A2（硬删或软删都归 B2，硬删极少走 UI）
        boolean isSoftDeleted = materialDelFlag != null && materialDelFlag == 1;
        return isSoftDeleted ? "B2" : "A2";  // 实际 UI 调用基本都是软删
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】3 端点
```

### B.2 Mapper XML（P0 修复 SQL 注入）

```xml
<!-- MesInventoryMapper.xml -->
<select id="selectOrphanById" resultType="map">
    SELECT i.*,
           m.code AS material_code, m.del_flag AS material_del_flag,
           w.name AS warehouse_name, w.del_flag AS warehouse_del_flag
    FROM c_mes_inventory i
    LEFT JOIN c_mes_material m ON i.material_id = m.id
    LEFT JOIN c_mes_warehouse w ON i.warehouse_id = w.id
    WHERE i.id = #{id}
      AND (m.id IS NULL OR m.del_flag = 1 OR w.id IS NULL OR w.del_flag = 1)
</select>

<!-- Codex P0：严禁 ${ids} 字符串插值，用 foreach -->
<select id="selectOrphansByIds" resultType="map">
    SELECT i.*,
           m.code AS material_code, m.del_flag AS material_del_flag,
           w.name AS warehouse_name, w.del_flag AS warehouse_del_flag
    FROM c_mes_inventory i
    LEFT JOIN c_mes_material m ON i.material_id = m.id
    LEFT JOIN c_mes_warehouse w ON i.warehouse_id = w.id
    WHERE (m.id IS NULL OR m.del_flag = 1 OR w.id IS NULL OR w.del_flag = 1)
      AND i.id IN
      <foreach collection="ids" item="id" open="(" separator="," close=")">
          #{id}
      </foreach>
</select>

<select id="selectOrphansForExport" resultType="map">
    SELECT i.*,
           m.code AS material_code,
           w.name AS warehouse_name,
           i.create_time, i.update_time
    FROM c_mes_inventory i
    LEFT JOIN c_mes_material m ON i.material_id = m.id
    LEFT JOIN c_mes_warehouse w ON i.warehouse_id = w.id
    WHERE (m.id IS NULL OR m.del_flag = 1 OR w.id IS NULL OR w.del_flag = 1)
    ORDER BY i.update_time DESC
    LIMIT #{limit}
</select>

<select id="countOrphans" resultType="java.lang.Long">
    SELECT COUNT(*)
    FROM c_mes_inventory i
    LEFT JOIN c_mes_material m ON i.material_id = m.id
    LEFT JOIN c_mes_warehouse w ON i.warehouse_id = w.id
    WHERE (m.id IS NULL OR m.del_flag = 1 OR w.id IS NULL OR w.del_flag = 1)
</select>
```

### B.3 审计表 DDL（flyway migration）

```sql
-- flyway sql/V10.x.x__mes_cleanup_audit.sql
CREATE TABLE IF NOT EXISTS c_mes_inventory_cleanup_audit (
    id              BIGINT AUTO_INCREMENT PRIMARY KEY,
    batch_id        VARCHAR(64)     NOT NULL COMMENT '清理批次 ID',
    inventory_id    VARCHAR(32)     NOT NULL,
    material_id     VARCHAR(32),
    warehouse_id    VARCHAR(32),
    current_qty     DECIMAL(18,4),
    risk_type       VARCHAR(16),
    operator        VARCHAR(64)     NOT NULL,
    cleaned_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rolled_back     TINYINT(1)      DEFAULT 0,
    rollback_at     DATETIME,
    INDEX idx_batch (batch_id),
    INDEX idx_inventory (inventory_id),
    INDEX idx_cleaned (cleaned_at)
) ENGINE=InnoDB COMMENT='孤儿库存清理审计表';

CREATE TABLE IF NOT EXISTS c_mes_inventory_cleanup_audit_his (
    -- 同结构（Codex P1：归档表）
    ...
) ENGINE=InnoDB COMMENT='孤儿库存清理审计历史表';
```

---

## § C. 阶段 3：cleanup-orphan-inventory.sh 加固

### C.1 入口校验（Codex P0：LIMIT 注入防御）

```bash
# 替换 cmd_ensure_audit_table 之前的入口段
main() {
  # Codex P0：LIMIT/BATCH_ID 校验
  if [[ -n "${LIMIT:-}" ]] && ! [[ "${LIMIT}" =~ ^[0-9]+$ ]]; then
    die "limit 必须为正整数"
  fi
  if [[ -n "${BATCH_ID:-}" ]] && ! [[ "${BATCH_ID}" =~ ^[a-zA-Z0-9_-]{1,64}$ ]]; then
    die "batch_id 必须匹配 ^[a-zA-Z0-9_-]{1,64}\$"
  fi
  # Codex P1：备份可选强制
  if [[ "${REQUIRE_BACKUP:-0}" == "1" ]]; then
    local latest=$(ls -t backup_c_mes_inventory_*.sql 2>/dev/null | head -1)
    if [[ -z "${latest}" ]] || [[ $(find "${latest}" -mmin +60 2>/dev/null) ]]; then
      die "REQUIRE_BACKUP=1 但 1 小时内无备份，请先跑 backup 子命令"
    fi
  fi
  # ...
}
```

### C.2 DRY-RUN 与 DELETE 共用 SQL（Codex P0）

```bash
cmd_clean_zero() {
  local dry_run="${DRY_RUN:-1}"
  local batch_id="zero-$(date +%Y%m%d-%H%M%S)"

  # Codex P0：DRY-RUN 与 DELETE 共用同一段 SQL
  local delete_sql=$(cat <<SQL
DELETE FROM c_mes_inventory
WHERE (material_id NOT IN (SELECT id FROM c_mes_material WHERE del_flag = 0)
       OR warehouse_id NOT IN (SELECT id FROM c_mes_warehouse WHERE del_flag = 0))
  AND current_qty = 0;
SQL
)

  if [[ "${dry_run}" == "1" ]]; then
    say "🔸 DRY-RUN：以下 SQL 不会执行，仅展示"
    cat <<PREVIEW
START TRANSACTION;
INSERT INTO ${AUDIT_TABLE} ...;
${delete_sql}
COMMIT;
PREVIEW
    return 0
  fi

  ${MYSQL_CMD} <<SQL
START TRANSACTION;
INSERT INTO ${AUDIT_TABLE} ...;
${delete_sql}
COMMIT;
SQL
}
```

### C.3 rollback 加 FOR UPDATE（Codex P0）

```bash
cmd_rollback() {
  local batch_id="${BATCH_ID:-}"
  [[ -z "${batch_id}" ]] && die "必须指定 --batch-id"

  ${MYSQL_CMD} <<SQL
START TRANSACTION;

-- Codex P0：行锁 + 事务内判断 rolled_back
SELECT inventory_id, material_id, warehouse_id, current_qty
FROM ${AUDIT_TABLE}
WHERE batch_id = '${batch_id}' AND rolled_back = 0
FOR UPDATE;

-- 若上一步返回 0 行，直接 COMMIT 并提示
-- 若有行，恢复 + 标记审计
INSERT INTO c_mes_inventory (id, material_id, warehouse_id, current_qty, create_by, create_time, update_by, update_time)
SELECT inventory_id, material_id, warehouse_id, current_qty,
       'rollback-${USER}', NOW(), 'rollback-${USER}', NOW()
FROM ${AUDIT_TABLE}
WHERE batch_id = '${batch_id}' AND rolled_back = 0
ON DUPLICATE KEY UPDATE update_by='rollback-${USER}', update_time=NOW();

UPDATE ${AUDIT_TABLE}
SET rolled_back = 1, rollback_at = NOW()
WHERE batch_id = '${batch_id}' AND rolled_back = 0;

COMMIT;
SQL
}
```

---

## § D. 阶段 4：MaterialReferenceChecker 列表模式（v3 完整重写）

### D.1 接口

```java
package org.jeecg.modules.mes.basic.service;

/**
 * 物料引用检查器（Codex v2 P0：19 张引用表全覆盖 + UNION ALL 聚合）
 * 每张引用 material_id 的表一个 bean，主代码注入 List 调用。
 */
public interface MaterialReferenceChecker {
    String describe();
    void assertNotReferenced(String materialId);
}
```

### D.2 完整 19 个 checker 实现（Codex v2 修订）

#### D.2.1 公共基础类

```java
@Component
public class InventoryReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesInventoryMapper mapper;

    @Override public String describe() { return "c_mes_inventory"; }

    @Override
    public void assertNotReferenced(String materialId) {
        // Codex P0：完全无行才放行（不限 qty），否则软删后产生新孤儿
        Long cnt = mapper.selectCount(
            new QueryWrapper<MesInventory>().eq("material_id", materialId));
        if (cnt > 0) {
            throw new JeecgBootException(
                "物料在 " + describe() + " 仍有 " + cnt + " 行引用（包括零库存），请先用 UI 清理");
        }
    }
}
```

#### D.2.2 全部 19 个 checker 列表

| # | 类名 | describe() | 守卫 SQL |
|---|---|---|---|
| 1 | `InventoryReferenceChecker` | `c_mes_inventory` | `WHERE material_id=?` (count) |
| 2 | `InventoryLedgerReferenceChecker` | `c_mes_inventory_ledger` | 同上 |
| 3 | `BatchReferenceChecker` | `c_mes_batch` | `WHERE material_id=? AND del_flag=0` |
| 4 | `BatchInventoryReferenceChecker` | `c_mes_batch_inventory` | `WHERE material_id=?` |
| 5 | `BatchLedgerReferenceChecker` | `c_mes_batch_ledger` | 同上 |
| 6 | `BomItemReferenceChecker` | `c_mes_bom_item` | 同上 |
| 7 | `CompletionReceiptItemReferenceChecker` | `c_mes_completion_receipt_item` | JOIN `c_mes_completion_receipt` + `status!='2'` |
| 8 | `CostLogReferenceChecker` | `c_mes_cost_log` | `WHERE material_id=?` |
| 9 | `DeliveryNoteItemReferenceChecker` | `c_mes_delivery_note_item` | JOIN `c_mes_delivery_note` + `status!='3'` |
| 10 | `OtherStockInItemReferenceChecker` | `c_mes_other_stock_in_item` | JOIN `c_mes_other_stock_in` + `status!='2'` |
| 11 | `OtherStockOutItemReferenceChecker` | `c_mes_other_stock_out_item` | JOIN `c_mes_other_stock_out` + `status!='2'` |
| 12 | `PriceReferenceChecker` | `c_mes_price` | `WHERE material_id=? AND del_flag=0` |
| 13 | `PickingItemReferenceChecker` | `c_mes_production_picking_item` | JOIN `c_mes_production_picking` + `status IN (open)` |
| 14 | `PurchaseApplyItemReferenceChecker` | `c_mes_purchase_apply_item` | JOIN `c_mes_purchase_apply` + `status!='2'` |
| 15 | `PurchaseOrderItemReferenceChecker` | `c_mes_purchase_order_item` | JOIN `c_mes_purchase_order` + `status!='2'` |
| 16 | `PurchaseReceiptItemReferenceChecker` | `c_mes_purchase_receipt_item` | JOIN `c_mes_purchase_receipt` + `status!='2'` |
| 17 | `SalesOrderItemReferenceChecker` | `c_mes_sales_order_item` | JOIN `c_mes_sales_order` + `status!='2'` |
| 18 | `SalesOutboundItemReferenceChecker` | `c_mes_sales_outbound_item` | JOIN `c_mes_sales_outbound` + `status!='3'` |
| 19 | `StocktakeItemReferenceChecker` | `c_mes_stocktake_item` | JOIN `c_mes_stocktake` + `status!='2'` |

#### D.2.3 典型 checker 完整代码（v3 完整覆盖）

```java
// 1. 物料库存（完全无行）
@Component
public class InventoryReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesInventoryMapper mapper;
    @Override public String describe() { return "c_mes_inventory"; }
    @Override public void assertNotReferenced(String materialId) {
        Long cnt = mapper.selectCount(
            new QueryWrapper<MesInventory>().eq("material_id", materialId));
        if (cnt > 0) throw new JeecgBootException(
            "物料在 c_mes_inventory 仍有 " + cnt + " 行引用，请先用 UI 清理");
    }
}

// 3. 批次主档（del_flag=0）
@Component
public class BatchReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesBatchMapper mapper;
    @Override public String describe() { return "c_mes_batch"; }
    @Override public void assertNotReferenced(String materialId) {
        Long cnt = mapper.selectCount(
            new QueryWrapper<MesBatch>().eq("material_id", materialId).eq("del_flag", 0));
        if (cnt > 0) throw new JeecgBootException("物料被 " + cnt + " 个批次引用");
    }
}

// 7. 完工入库明细（v3 状态白名单从 SysDictCache 读）
@Component
public class CompletionReceiptItemReferenceChecker implements MaterialReferenceChecker {
    @Autowired private MesCompletionReceiptItemMapper itemMapper;
    @Autowired private SysDictCache dictCache;
    @Override public String describe() { return "c_mes_completion_receipt_item"; }
    @Override public void assertNotReferenced(String materialId) {
        List<String> openStatuses = dictCache.getOpenStatuses("mes_completion_receipt_status");
        if (openStatuses.isEmpty()) {
            throw new JeecgBootException("完工入库状态字典缓存为空，请检查 SysDictCache");
        }
        Long cnt = itemMapper.selectCount(
            new QueryWrapper<MesCompletionReceiptItem>()
                .eq("material_id", materialId)
                .apply("receipt_id IN (SELECT id FROM c_mes_completion_receipt WHERE status IN ('"
                    + String.join("','", openStatuses) + "'))"));
        if (cnt > 0) throw new JeecgBootException("物料被 " + cnt + " 行未完结完工入库引用");
    }
}

// 其余 16 个 checker 同模式，参考主方案 § 6.3 表格
```

### D.3 MesMaterialServiceImpl 重写（v3 两步走）

```java
@Service
public class MesMaterialServiceImpl extends ServiceImpl<MesMaterialMapper, MesMaterial>
        implements IMesMaterialService {

    // v3：注入聚合器、启动自检、行锁服务
    @Autowired private MaterialReferenceAggregator referenceAggregator;
    @Autowired private CriticalTableLockService criticalTableLockService;
    @Autowired private SysDictCache dictCache;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public boolean removeById(Serializable id) {
        String materialId = id.toString();

        // 第一步：UNION ALL 聚合查全表引用计数（轻量级，仅读）
        Map<String, Long> refCounts = referenceAggregator.aggregate(materialId);
        if (refCounts.values().stream().anyMatch(c -> c > 0)) {
            throw new JeecgBootException(formatRejectMessage(refCounts));
        }

        // 第二步：关键表（inventory / batch / production_picking）行锁 + 最终校验
        // 防守卫→删除窗口的并发漏判（Codex v2 P0）
        criticalTableLockService.lockAndRecheck(materialId, refCounts.keySet());

        return super.removeById(id);
    }

    /** v3 业务影响预检接口（UI 删除前调用） */
    public Map<String, Long> preCheckDelete(String materialId) {
        return referenceAggregator.aggregate(materialId);
    }

    private String formatRejectMessage(Map<String, Long> refCounts) {
        return refCounts.entrySet().stream()
            .filter(e -> e.getValue() > 0)
            .map(e -> e.getKey() + "=" + e.getValue() + " 行")
            .collect(Collectors.joining("; ", "物料被以下表引用：", ""));
    }
}
```

### D.4 MaterialReferenceAggregator（UNION ALL 聚合，Codex v2 P0）

```java
@Component
public class MaterialReferenceAggregator {
    @Autowired private JdbcTemplate jdbc;

    public Map<String, Long> aggregate(String materialId) {
        String sql = buildUnionSql();
        List<Map<String, Object>> rows = jdbc.queryForList(sql, materialId);
        return rows.stream().collect(Collectors.toMap(
            r -> (String) r.get("tbl"),
            r -> ((Number) r.get("cnt")).longValue()));
    }

    private String buildUnionSql() {
        // 动态生成 19 张表的 UNION ALL SQL（避免硬编码，便于新增表时维护）
        return Stream.of(
            "SELECT 'c_mes_inventory' AS tbl, COUNT(*) AS cnt FROM c_mes_inventory WHERE material_id = ?",
            "SELECT 'c_mes_inventory_ledger' AS tbl, COUNT(*) AS cnt FROM c_mes_inventory_ledger WHERE material_id = ?",
            "SELECT 'c_mes_batch' AS tbl, COUNT(*) AS cnt FROM c_mes_batch WHERE material_id = ? AND del_flag = 0",
            "SELECT 'c_mes_batch_inventory' AS tbl, COUNT(*) AS cnt FROM c_mes_batch_inventory WHERE material_id = ?",
            "SELECT 'c_mes_batch_ledger' AS tbl, COUNT(*) AS cnt FROM c_mes_batch_ledger WHERE material_id = ?",
            "SELECT 'c_mes_bom_item' AS tbl, COUNT(*) AS cnt FROM c_mes_bom_item WHERE material_id = ?",
            // 状态白名单改在 SQL 拼接时从 SysDictCache 读
            buildStatusFilteredSql("c_mes_completion_receipt_item",
                "c_mes_completion_receipt", "mes_completion_receipt_status", "'2'"),
            "SELECT 'c_mes_cost_log' AS tbl, COUNT(*) AS cnt FROM c_mes_cost_log WHERE material_id = ?",
            buildStatusFilteredSql("c_mes_delivery_note_item",
                "c_mes_delivery_note", null, "'3'"),
            buildStatusFilteredSql("c_mes_other_stock_in_item",
                "c_mes_other_stock_in", null, "'2'"),
            buildStatusFilteredSql("c_mes_other_stock_out_item",
                "c_mes_other_stock_out", null, "'2'"),
            "SELECT 'c_mes_price' AS tbl, COUNT(*) AS cnt FROM c_mes_price WHERE material_id = ? AND del_flag = 0",
            buildStatusFilteredSql("c_mes_production_picking_item",
                "c_mes_production_picking", "mes_production_picking_status", null),
            buildStatusFilteredSql("c_mes_purchase_apply_item",
                "c_mes_purchase_apply", null, "'2'"),
            buildStatusFilteredSql("c_mes_purchase_order_item",
                "c_mes_purchase_order", null, "'2'"),
            buildStatusFilteredSql("c_mes_purchase_receipt_item",
                "c_mes_purchase_receipt", null, "'2'"),
            buildStatusFilteredSql("c_mes_sales_order_item",
                "c_mes_sales_order", null, "'2'"),
            buildStatusFilteredSql("c_mes_sales_outbound_item",
                "c_mes_sales_outbound", null, "'3'"),
            buildStatusFilteredSql("c_mes_stocktake_item",
                "c_mes_stocktake", null, "'2'")
        ).collect(Collectors.joining(" UNION ALL "));
    }

    /** 状态过滤的子查询生成（item + parent + status filter） */
    private String buildStatusFilteredSql(String itemTable, String parentTable,
                                          String dictCode, String excludeStatus) {
        String statusFilter;
        if (dictCode != null) {
            // 从 SysDictCache 读（启动时拼到 SQL 中）
            List<String> openStatuses = dictCache.getOpenStatuses(dictCode);
            statusFilter = " AND p.status IN ('" + String.join("','", openStatuses) + "')";
        } else {
            statusFilter = " AND p.status != " + excludeStatus;
        }
        return String.format(
            "SELECT '%s' AS tbl, COUNT(*) AS cnt FROM %s i JOIN %s p ON i.%s_id = p.id "
                + "WHERE i.material_id = ?%s",
            itemTable, itemTable, parentTable,
            itemTable.replace("_item", "").replace("c_mes_", ""), statusFilter);
    }
}
```

### D.5 MaterialReferenceCoverageAssertor（启动自检，Codex v2 P0）

```java
@Component
public class MaterialReferenceCoverageAssertor implements ApplicationRunner {
    @Autowired private DataSource ds;
    @Autowired private List<MaterialReferenceChecker> checkers;

    @Override
    @Transactional(readOnly = true)
    public void run(ApplicationArguments args) {
        // 1. 查 schema 实际含 material_id 的表
        Set<String> actualTables = new HashSet<>();
        try (Connection conn = ds.getConnection();
             PreparedStatement ps = conn.prepareStatement(
                "SELECT table_name FROM information_schema.columns " +
                "WHERE column_name = 'material_id' AND table_schema = DATABASE()");
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) actualTables.add(rs.getString(1));
        } catch (SQLException e) { throw new RuntimeException(e); }

        // 2. 查 checker 描述的所有表
        Set<String> checkerTables = checkers.stream()
            .map(c -> c.describe().split("\\.")[0])
            .collect(Collectors.toSet());

        // 3. 差异比对（fail-fast）
        Set<String> missing = Sets.difference(actualTables, checkerTables);
        if (!missing.isEmpty()) {
            throw new IllegalStateException(
                "【守卫覆盖校验】以下表含 material_id 但未实现 checker: " + missing
                + "，请补齐 MaterialReferenceChecker 实现");
        }
        log.info("【守卫覆盖校验】通过：schema {} 张表均已覆盖", actualTables.size());
    }
}
```

### D.6 SysDictCache（@PostConstruct + @Scheduled 60s 刷新）

```java
@Component
public class SysDictCache implements ApplicationRunner {
    @Autowired private SysDictService dictService;
    private volatile Map<String, List<String>> openStatusCache = new ConcurrentHashMap<>();

    @Override public void run(ApplicationArguments args) { refresh(); }

    @Scheduled(fixedRate = 60_000)  // 每 60s 刷新
    public void refresh() {
        try {
            openStatusCache.put("mes_production_order_status",
                getOpenItems("mes_production_order_status", "已完结"));
            openStatusCache.put("mes_completion_receipt_status",
                getOpenItems("mes_completion_receipt_status", "已入库"));
            openStatusCache.put("mes_production_picking_status",
                getOpenItems("mes_production_picking_status", "已审核"));
            openStatusCache.put("mes_purchase_apply_status",
                getOpenItems("mes_purchase_apply_status", "已入库"));
            openStatusCache.put("mes_purchase_order_status",
                getOpenItems("mes_purchase_order_status", "已关闭"));
            openStatusCache.put("mes_purchase_receipt_status",
                getOpenItems("mes_purchase_receipt_status", "已入库"));
            openStatusCache.put("mes_sales_order_status",
                getOpenItems("mes_sales_order_status", "已关闭"));
            openStatusCache.put("mes_sales_outbound_status",
                getOpenItems("mes_sales_outbound_status", "已审核"));
            openStatusCache.put("mes_delivery_note_status",
                getOpenItems("mes_delivery_note_status", "已发货"));
            openStatusCache.put("mes_other_stock_in_status",
                getOpenItems("mes_other_stock_in_status", "已入库"));
            openStatusCache.put("mes_other_stock_out_status",
                getOpenItems("mes_other_stock_out_status", "已出库"));
            openStatusCache.put("mes_stocktake_status",
                getOpenItems("mes_stocktake_status", "已审核"));
        } catch (Exception e) {
            log.warn("字典缓存刷新失败，使用上次缓存", e);
        }
    }

    private List<String> getOpenItems(String dictCode, String closedText) {
        return dictService.getDictItems(dictCode)
            .stream().filter(i -> !closedText.equals(i.getText()))
            .map(SysDictItem::getValue).collect(Collectors.toList());
    }

    public List<String> getOpenStatuses(String dictCode) {
        return openStatusCache.getOrDefault(dictCode, List.of());
    }
}
```

### D.7 CriticalTableLockService（关键表 FOR UPDATE 重检）

```java
@Component
public class CriticalTableLockService {
    @Autowired private JdbcTemplate jdbc;

    /** 守卫→删除窗口的关键表行锁重检（Codex v2 P0） */
    @Transactional(rollbackFor = Exception.class)
    public void lockAndRecheck(String materialId, Set<String> tables) {
        // inventory：必须无任何行（包含零库存）
        if (tables.contains("c_mes_inventory")) {
            List<Map<String, Object>> locked = jdbc.queryForList(
                "SELECT id FROM c_mes_inventory WHERE material_id = ? FOR UPDATE",
                materialId);
            if (!locked.isEmpty()) {
                throw new JeecgBootException("并发检测：c_mes_inventory 守卫通过后又有 " + locked.size() + " 行被创建");
            }
        }
        // batch：必须无 del_flag=0 行
        if (tables.contains("c_mes_batch")) {
            List<Map<String, Object>> locked = jdbc.queryForList(
                "SELECT id FROM c_mes_batch WHERE material_id = ? AND del_flag = 0 FOR UPDATE",
                materialId);
            if (!locked.isEmpty()) {
                throw new JeecgBootException("并发检测：c_mes_batch 守卫通过后又有 " + locked.size() + " 行被创建");
            }
        }
        // production_picking_item：行锁（防并发领料）
        if (tables.contains("c_mes_production_picking_item")) {
            jdbc.queryForList(
                "SELECT id FROM c_mes_production_picking_item WHERE material_id = ? FOR UPDATE",
                materialId);
        }
    }
}
```

---

## § E. 阶段 5：测试代码草案（v3 补 fixtures cleanup + CoverageAssertorTest）

### E.1 fixtures helper

```javascript
// harness/tests/helpers/fixtures.js
const { execSQL } = require('./db');  // 假设的 DB helper

async function withOrphanRow(client, opts = {}) {
  const ts = Date.now();
  const materialId = `orphan-mat-${ts}`;
  const warehouseId = opts.hardDeleteMaterial ? null : 'wh-normal-001';
  const inventoryId = `orphan-inv-${ts}`;

  // 插入孤儿库存行（material/warehouse 已不存在或已软删）
  await execSQL(`
    INSERT INTO c_mes_inventory (id, material_id, warehouse_id, current_qty)
    VALUES (?, ?, ?, ?)
  `, [inventoryId, materialId, warehouseId, opts.qty || 0]);

  return inventoryId;
}

async function withReferencedMaterial(client, tables = ['inventory']) {
  // 创建物料 + 在指定表中插入引用行
  // 返回 materialId
  const materialId = `ref-mat-${Date.now()}`;
  await execSQL(`INSERT INTO c_mes_material (id, code, name, del_flag) VALUES (?, ?, ?, 0)`,
    [materialId, `MAT-${materialId}`, 'test']);
  for (const table of tables) {
    await execSQL(`INSERT INTO ${table} (id, material_id, ...) VALUES (?, ?, ...)`,
      [`${table}-${Date.now()}`, materialId, ...]);
  }
  return materialId;
}

module.exports = { withOrphanRow, withReferencedMaterial };
```

### E.2 inventory-orphan-edge.test.js

```javascript
const { createClient } = require('../helpers/api');
const { withOrphanRow } = require('../helpers/fixtures');

(async () => {
  const c = createClient(process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot');
  await c.login('mes_admin', '123456');
  let passed = 0, failed = 0;

  // E1: 空 ids
  const r1 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: [] });
  if (r1.code === 200) { passed++; c.check('E1 空 ids', true); }
  else { failed++; c.check('E1 空 ids', false, r1.message); }

  // E2: SQL 注入尝试
  const r2 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan',
    { ids: ["1','2',' OR 1=1 --"] });
  if (r2.code === 500) { passed++; c.check('E2 SQL 注入拦截', true); }
  else { failed++; c.check('E2 SQL 注入拦截', false, `code=${r2.code}`); }

  // E3: 超长 ids
  const longIds = Array.from({ length: 501 }, (_, i) => `id-${i}`);
  const r3 = await c.api('POST', '/mes/warehouse/inventory/batchDeleteOrphan', { ids: longIds });
  if (r3.code === 500 && r3.message?.includes('500')) { passed++; c.check('E3 超长 ids 拦截', true); }
  else { failed++; c.check('E3 超长 ids 拦截', false, r3.message); }

  // E4: 跨批次 rollback
  const orphan1 = await withOrphanRow(c);
  const orphan2 = await withOrphanRow(c);
  // 清理孤儿1 → rollback → 验证孤儿2 不受影响
  // ...

  console.log(`\n结果：${passed} passed, ${failed} failed`);
})();
```

### E.3 material-delete-guard.test.js（完整 6 场景）

```javascript
const { createClient } = require('../helpers/api');
const { withReferencedMaterial, cleanupFixtures } = require('../helpers/fixtures');

(async () => {
  const c = createClient(process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot');
  await c.login('mes_admin', '123456');
  let passed = 0, failed = 0;
  const fixtureIds = [];  // v3：跟踪所有 fixture，测试结束统一 cleanup

  try {
    // S1: 有 inventory 行
    const mat1 = await withReferencedMaterial(c, ['c_mes_inventory']);
    fixtureIds.push(mat1);
    const r1 = await c.api('DELETE', `/mes/basic/material/delete?id=${mat1}`);
    if (r1.code === 500 && r1.message.includes('c_mes_inventory')) { passed++; c.check('S1 库存引用拦截', true); }
    else { failed++; c.check('S1 库存引用拦截', false, r1.message); }

    // S2: 有 BOM 引用（v3 用 bom_item 而非 bom）
    const mat2 = await withReferencedMaterial(c, ['c_mes_bom_item']);
    fixtureIds.push(mat2);
    const r2 = await c.api('DELETE', `/mes/basic/material/delete?id=${mat2}`);
    if (r2.code === 500 && r2.message.includes('bom_item')) { passed++; c.check('S2 BOM 拦截', true); }
    else { failed++; c.check('S2 BOM 拦截', false, r2.message); }

    // S3: 有未完结领料单（v3 用 picking_item 而非 picking）
    const mat3 = await withReferencedMaterial(c, ['c_mes_production_picking_item']);
    fixtureIds.push(mat3);
    await execSQL(`UPDATE c_mes_production_picking SET status='1' WHERE id IN (SELECT picking_id FROM c_mes_production_picking_item WHERE material_id=?)`, [mat3]);
    const r3 = await c.api('DELETE', `/mes/basic/material/delete?id=${mat3}`);
    if (r3.code === 500 && r3.message.includes('领料')) { passed++; c.check('S3 未完结领料拦截', true); }
    else { failed++; c.check('S3 未完结领料拦截', false, r3.message); }

    // S4: 有活跃批次
    const mat4 = await withReferencedMaterial(c, ['c_mes_batch']);
    fixtureIds.push(mat4);
    const r4 = await c.api('DELETE', `/mes/basic/material/delete?id=${mat4}`);
    if (r4.code === 500 && r4.message.includes('批次')) { passed++; c.check('S4 批次拦截', true); }
    else { failed++; c.check('S4 批次拦截', false, r4.message); }

    // S5: qty=0 inventory 行（v3 必须拦截）
    const mat5 = await withReferencedMaterial(c, ['c_mes_inventory']);
    fixtureIds.push(mat5);
    await execSQL(`UPDATE c_mes_inventory SET current_qty=0 WHERE material_id=?`, [mat5]);
    const r5 = await c.api('DELETE', `/mes/basic/material/delete?id=${mat5}`);
    if (r5.code === 500) { passed++; c.check('S5 qty=0 inventory 拦截', true, 'v3 修复'); }
    else { failed++; c.check('S5 qty=0 inventory 拦截', false, '守卫逻辑漏洞！'); }

    // S6: 全新物料无引用 → 删除成功
    const mat6 = await withReferencedMaterial(c, []);
    fixtureIds.push(mat6);
    const r6 = await c.api('DELETE', `/mes/basic/material/delete?id=${mat6}`);
    if (r6.code === 200) { passed++; c.check('S6 无引用可删', true); }
    else { failed++; c.check('S6 无引用可删', false, r6.message); }
  } finally {
    // v3：无论断言成功失败都 cleanup fixture，避免污染测试库
    await cleanupFixtures(c, fixtureIds);
  }

  console.log(`\n结果：${passed} passed, ${failed} failed`);
})();
```

### E.4 MaterialReferenceCoverageAssertorTest（v3 新增）

```javascript
// 验证启动自检：schema 含 material_id 的表未被 checker 覆盖时，应用启动应失败
const { execSQL } = require('../helpers/db');

describe('MaterialReferenceCoverageAssertor', () => {
  test('全部 19 张表都已覆盖', async () => {
    const result = await execSQL(`
      SELECT table_name FROM information_schema.columns
      WHERE column_name = 'material_id' AND table_schema = DATABASE()
      ORDER BY table_name
    `);
    const tables = result.map(r => r.table_name);

    // 期望 19 张表全部覆盖
    const expected = [
      'c_mes_batch', 'c_mes_batch_inventory', 'c_mes_batch_ledger',
      'c_mes_bom_item', 'c_mes_completion_receipt_item', 'c_mes_cost_log',
      'c_mes_delivery_note_item', 'c_mes_inventory', 'c_mes_inventory_ledger',
      'c_mes_other_stock_in_item', 'c_mes_other_stock_out_item', 'c_mes_price',
      'c_mes_production_picking_item', 'c_mes_purchase_apply_item',
      'c_mes_purchase_order_item', 'c_mes_purchase_receipt_item',
      'c_mes_sales_order_item', 'c_mes_sales_outbound_item', 'c_mes_stocktake_item'
    ];
    expect(tables).toEqual(expect.arrayContaining(expected));
    expect(tables.length).toBe(expected.length);
  });

  test('新增引用表忘加 checker 应导致启动失败', async () => {
    // 模拟：临时创建一张测试表含 material_id 列（但无 checker）
    // 应用启动应抛 IllegalStateException
    // 注：实际测试需重启 Spring 容器，集成测试场景
    const tempTable = `c_mes_test_no_checker_${Date.now()}`;
    try {
      await execSQL(`CREATE TABLE ${tempTable} (
        id VARCHAR(32) PRIMARY KEY,
        material_id VARCHAR(32) NOT NULL
      )`);

      // 重新触发 ApplicationRunner.run()（通过 Spring context refresh）
      // 期望：抛 "以下表含 material_id 但未实现 checker"
      await expect(triggerAssertor()).rejects.toThrow(/未实现 checker.*${tempTable}/);
    } finally {
      await execSQL(`DROP TABLE IF EXISTS ${tempTable}`);
    }
  });
});
```

---

## § F. 完整 checklist 汇总（v3）

### 阶段 1（UI）
- [ ] § A 完整代码落地
- [ ] `/vue-audit` 库存页 → 全 PASS

### 阶段 2（后端）
- [ ] § B.1 Controller 3 端点（含 @Validated + risk_type 派生）
- [ ] § B.2 Mapper XML（含 foreach）
- [ ] § B.3 flyway migration（审计表）
- [ ] MesMenuRegistry 注册 **3 个权限**（含 export）

### 阶段 3（SQL 应急）
- [ ] § C.1 入口校验
- [ ] § C.2 DRY-RUN 一致性
- [ ] § C.3 rollback FOR UPDATE

### 阶段 4（守卫重写，v3 升级）
- [ ] § D.1 MaterialReferenceChecker 接口
- [ ] § D.2 **19 个** checker bean（v3 完整清单）
- [ ] § D.3 MesMaterialServiceImpl 重写（两步走：聚合 + 行锁）
- [ ] § D.4 MaterialReferenceAggregator UNION ALL 聚合
- [ ] § D.5 MaterialReferenceCoverageAssertor 启动自检（fail-fast）
- [ ] § D.6 SysDictCache @PostConstruct + @Scheduled 60s
- [ ] § D.7 CriticalTableLockService 关键表 FOR UPDATE
- [ ] UI 预检接口 preCheckDelete

### 阶段 5（测试，v3 补 1 个）
- [ ] § E.1 fixtures helper（含 cleanup）
- [ ] § E.2 inventory-orphan-edge.test.js
- [ ] § E.3 material-delete-guard.test.js（6 场景）
- [ ] inventory-orphan-export.test.js 补全
- [ ] inventory-orphan-ui-delete.test.js 补全（审计表断言）
- [ ] **MaterialReferenceCoverageAssertorTest（v3 新增）**

### 阶段 6（运维）
- [ ] 月度归档脚本 + cron
- [ ] 备份保留策略
- [ ] 回滚演练 SOP
- [ ] **故障响应 SOP（Codex v2 建议：rollback 失败/RCA 流程）**

---

*本文档为 v2 实施草案，与主方案 v2 一一对应。*
