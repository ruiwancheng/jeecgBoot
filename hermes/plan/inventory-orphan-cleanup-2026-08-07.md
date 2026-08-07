# 库存总览孤儿行清理 — 完整方案

> **目的**：彻底解决 MES "库存总览"页面显示大量"（物料已删除）"孤儿行的问题
> **生成日期**：2026-08-07
> **关联**：`/debug` 库存总览孤儿行诊断
> **优先级**：P1（线上已暴露，影响业务人员日常使用）

---

## 一、问题回顾

| 项 | 现状 |
|---|---|
| 现象 | 库存总览页面显示大量 "（物料已删除）" 灰色行 |
| 根因 | 物料删除时**无前置校验**，导致 `c_mes_inventory` 留下指向已删物料的孤儿行 |
| 数据规模 | 需 `harness/scripts/sql/diagnose-orphan-inventory.sql` 探针确认 |
| 业务影响 | 库存总览"金额合计"虚高、盘点困难、报表失真 |

---

## 二、整合方案（4 阶段）

```
阶段 1 (本次): UI 增加删除按钮 + 黄金模板对齐 ──────── 业务人员自助删除
阶段 2 (本次): 后端增加 3 个端点（单删/批量删/导出）─── 配套支持
阶段 3 (应急): SQL 清理脚本（应急工具，不走主流程）── 预留后台能力
阶段 4 (后续): 长期修复方案 A + 回归测试 ────────── 排期
```

---

## 三、阶段 1：UI 黄金模板对齐 + 增加"删除孤儿行"按钮

### 3.1 现状评估（vue-audit 对照）

跑 `/vue-audit jeecgboot-vue3/src/views/project/mes/basic/inventory` 当前结果预估：

| 检查项 | 现状 | 期望 |
|---|---|---|
| `@generated-from` 标注 | ❌ 缺失 | 必须有 |
| 删除按钮 | ❌ 缺失 | 孤儿行可一键删 |
| 列表行操作 | ❌ 无 | 至少 1 个 action |
| 字典翻译（_dictText） | ⚠️ 部分 | 全字段对齐 |
| 状态/类型标签 | ⚠️ 部分 | 库存类型显隐 |
| ApiSelect 引用 | ✅ Pass | - |

### 3.2 index.vue 改造目标（黄金模板对齐）

**关键改动**（参见 `harness/templates/mes-doc-page/master-detail`）：

```vue
<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #tableTitle>
        <span>库存总览</span>
        <span style="margin-left:16px; color:#888; font-weight:normal; font-size:13px">
          库存金额合计：<b style="color:#1677ff">{{ pageTotalAmount }}</b>
          （零库存红标，点行首 + 看最近台账）
        </span>
        <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增批量删除按钮---------->
        <a-button
          v-if="hasOrphanSelected"
          danger
          preIcon="ant-design:delete-outlined"
          style="margin-left:16px"
          @click="batchDeleteOrphan">
          批量删除孤儿行（{{ selectedOrphanKeys.length }}）
        </a-button>
        <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删除按钮----------->

        <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】单行删除按钮（仅孤儿行可见）---------->
        <a-button
          v-if="hasOrphanSelected"
          danger
          preIcon="ant-design:export-outlined"
          @click="exportOrphanXls">
          导出孤儿清单
        </a-button>
        <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】导出孤儿清单---------->
      </template>

      <!-- 现有 matText/whText/qtyTag/amountText slot 保留 -->

      <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增孤儿行标识---------->
      <template #orphanTag="{ record }">
        <a-tag v-if="isOrphan(record)" color="default" title="该库存行引用的物料已删除">孤儿行</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】孤儿行标识---------->

      <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】单行删除按钮---------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
      <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】单行删除---------->
    </BasicTable>
    <!-- <InventoryLedgerSubTable> 保留 -->
  </div>
</template>

<script lang="ts" setup>
  // 现有 imports + 新增：
  import { ref, computed, reactive } from 'vue';
  import { message, Modal } from 'ant-design-vue';
  import { queryInventoryList, deleteOrphanInventory, batchDeleteOrphanInventory, getOrphanExportUrl } from './inventory.api';

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

  // 判定孤儿行：material_code 为空（LEFT JOIN 不匹配）
  function isOrphan(record: Recordable): boolean {
    return !record.material_code;
  }

  const selectedOrphanKeys = computed(() =>
    selectedRows.filter(isOrphan).map((r) => r.id)
  );
  const hasOrphanSelected = computed(() => selectedOrphanKeys.value.length > 0);

  function getActions(record: Recordable) {
    if (!isOrphan(record)) return [];
    return [
      {
        label: '删除',
        popConfirm: {
          title: `确认删除该孤儿行？（inventory_id=${record.id}）`,
          confirm: () => handleDeleteOne(record),
        },
      },
    ];
  }

  async function handleDeleteOne(record: Recordable) {
    await deleteOrphanInventory({ id: record.id });
    message.success('已删除');
    reload();
  }

  async function batchDeleteOrphan() {
    if (!selectedOrphanKeys.value.length) return;
    // 安全守门：仅孤儿行可批量删
    Modal.confirm({
      title: `确认删除 ${selectedOrphanKeys.value.length} 条孤儿行？`,
      content: '此操作不可逆（后端会写审计表，但 UI 无回滚入口）。建议先用"导出孤儿清单"留档。',
      okText: '确认删除',
      okButtonProps: { danger: true },
      onOk: async () => {
        await batchDeleteOrphanInventory({ ids: selectedOrphanKeys.value.join(',') });
        message.success(`已删除 ${selectedOrphanKeys.value.length} 条`);
        selectedRowKeys.length = 0;
        selectedRows.length = 0;
        reload();
      },
    });
  }

  function exportOrphanXls() {
    // 复用 queryInventoryList 拉全量孤儿，过滤后导出
    // （具体实现略，可参考其他页面的 exportXls 写法）
  }
</script>
```

### 3.3 inventory.api.ts 改造

```typescript
import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/warehouse/inventory';

// 现有：queryInventoryList
export function queryInventoryList(params: Recordable) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

// 新增：单删
//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】单删 API-----------
export function deleteOrphanInventory(params: { id: string }) {
  return defHttp.delete({ url: `${BASE}/deleteOrphan`, params }, { joinParamsToUrl: true });
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】单删 API

// 新增：批量删（仅孤儿行）
//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删 API-----------
export function batchDeleteOrphanInventory(params: { ids: string }) {
  return defHttp.delete({ url: `${BASE}/batchDeleteOrphan`, params }, { joinParamsToUrl: true });
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删 API

// 新增：导出孤儿清单 URL（用于前端 window.open）
//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】导出 URL-----------
export function getOrphanExportUrl() {
  return `${BASE}/exportOrphanXls`;
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】导出 URL
```

### 3.4 inventory.data.ts 改造（columns 加 action/orphanTag 槽位）

```typescript
export const columns: BasicColumn[] = [
  // 现有列保留
  { title: '物料编码', dataIndex: 'material_code', width: 130, slots: { customRender: 'matText' } },
  { title: '物料名称', dataIndex: 'material_name', width: 150 },
  { title: '仓库', dataIndex: 'warehouse_name', width: 120, slots: { customRender: 'whText' } },
  { title: '当前库存', dataIndex: 'current_qty', width: 100, slots: { customRender: 'qtyTag' } },
  { title: '移动平均成本', dataIndex: 'moving_avg_cost', width: 110 },
  { title: '库存金额', dataIndex: 'inventory_amount', width: 110, slots: { customRender: 'amountText' } },
  // 新增：孤儿标识 + 操作
  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增列-----------
  { title: '状态', dataIndex: 'isOrphan', width: 80, slots: { customRender: 'orphanTag' } },
  { title: '操作', dataIndex: 'action', width: 80, slots: { customRender: 'action' }, fixed: 'right' },
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增列
];
```

---

## 四、阶段 2：后端增加 3 个端点（黄金模板对齐）

### 4.1 MesInventoryController 新增端点

```java
//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增 3 个端点-----------
package org.jeecg.modules.mes.basic.controller;

// ... 现有 imports + 新增：
import org.jeecg.common.exception.JeecgBootException;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Tag(name = "MES-库存总览")
@RestController
@RequestMapping("/mes/warehouse/inventory")
public class MesInventoryController {
    @Autowired private MesInventoryMapper inventoryMapper;
    @Autowired private IMesInventoryService inventoryService;  // 新增
    @Autowired private IMesInventoryCleanupAuditService cleanupAuditService;  // 新增

    /**
     * 删除单个孤儿行（仅允许孤儿行 + qty=0）
     */
    @DeleteMapping("/deleteOrphan")
    @RequiresPermissions("mes:inventory:deleteOrphan")
    @Transactional(rollbackFor = Exception.class)
    public Result<String> deleteOrphan(@RequestParam String id) {
        Map<String, Object> row = inventoryMapper.selectOrphanById(id);
        if (row == null) throw new JeecgBootException("该库存行不是孤儿行，禁止删除");
        // 安全守门：qty > 0 必须走人工流程
        BigDecimal qty = (BigDecimal) row.get("current_qty");
        if (qty != null && qty.compareTo(BigDecimal.ZERO) > 0) {
            throw new JeecgBootException("孤儿行有库存(" + qty + ")，禁止删除；请先盘点或 resurrect 物料");
        }
        inventoryMapper.deleteById(id);
        cleanupAuditService.log("ui-single", id, row.get("material_id"), row.get("warehouse_id"), qty, "B2", getCurrentUsername());
        return Result.ok("已删除");
    }

    /**
     * 批量删除孤儿行（仅 qty=0）
     */
    @DeleteMapping("/batchDeleteOrphan")
    @RequiresPermissions("mes:inventory:batchDeleteOrphan")
    @Transactional(rollbackFor = Exception.class)
    public Result<String> batchDeleteOrphan(@RequestParam String ids) {
        List<String> idList = Arrays.asList(ids.split(","));
        List<Map<String, Object>> orphans = inventoryMapper.selectOrphansByIds(idList);
        // 守门：任一 qty > 0 → 整批拒绝
        for (Map<String, Object> row : orphans) {
            BigDecimal qty = (BigDecimal) row.get("current_qty");
            if (qty != null && qty.compareTo(BigDecimal.ZERO) > 0) {
                throw new JeecgBootException("孤儿行 " + row.get("id") + " 有库存(" + qty + ")，禁止批量删");
            }
        }
        for (Map<String, Object> row : orphans) {
            inventoryMapper.deleteById(row.get("id"));
            cleanupAuditService.log("ui-batch", row.get("id"), row.get("material_id"), row.get("warehouse_id"),
                (BigDecimal) row.get("current_qty"), "B2", getCurrentUsername());
        }
        return Result.ok("已删除 " + orphans.size() + " 条");
    }

    /**
     * 导出孤儿清单（Excel）
     */
    @GetMapping("/exportOrphanXls")
    @RequiresPermissions("mes:inventory:export")
    public ModelAndView exportOrphanXls(HttpServletRequest req) {
        // 复用 selectInventoryWithMaterial 但强制过滤孤儿
        List<Map<String, Object>> rows = inventoryMapper.selectInventoryWithMaterial(null, null, null)
            .stream().filter(r -> r.get("material_code") == null).collect(Collectors.toList());
        // 构造 Excel（参考其他模块的 exportXls 实现）
        // ...
    }
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】后端 3 端点
```

### 4.2 MesInventoryMapper 新增查询

```java
//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】Mapper 新增 2 查询-----------
@Select("SELECT i.*, m.code AS material_code, m.del_flag AS material_del_flag " +
        "FROM c_mes_inventory i " +
        "LEFT JOIN c_mes_material m ON i.material_id = m.id " +
        "WHERE i.id = #{id} AND (m.id IS NULL OR m.del_flag = 1)")
Map<String, Object> selectOrphanById(@Param("id") String id);

@Select("SELECT i.*, m.code AS material_code, m.del_flag AS material_del_flag " +
        "FROM c_mes_inventory i " +
        "LEFT JOIN c_mes_material m ON i.material_id = m.id " +
        "WHERE i.id IN (${ids}) AND (m.id IS NULL OR m.del_flag = 1)")
List<Map<String, Object>> selectOrphansByIds(@Param("ids") List<String> ids);  // 注意 SQL 注入风险，实际需用 foreach
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】Mapper
```

### 4.3 审计表 + Service

复用 `harness/scripts/sql/cleanup-orphan-inventory.sh` 已有的 `c_mes_inventory_cleanup_audit` 表结构（建议建在 jeecg-boot 库）。

---

## 五、阶段 3：SQL 清理脚本（应急工具，非主流程）

详见 `harness/scripts/sql/`：

| 文件 | 用途 |
|---|---|
| `diagnose-orphan-inventory.sql` | 应急探针（业务人员发现异常时供 DBA 排查） |
| `cleanup-orphan-inventory.sh` | 应急工具（DBA 兜底，不走主流程） |
| `README.md` | DBA 操作手册 |

**主流程**：业务人员在"库存总览"页面用"删除"按钮自助清理，**不依赖 DBA**。
**应急场景**：UI 操作异常（如后端 bug）时，DBA 用此脚本兜底。

**典型应急命令**（仅供 DBA 参考，业务人员无需关心）：
```bash
cd harness/scripts/sql
DRY_RUN=0 ./cleanup-orphan-inventory.sh clean-zero
DRY_RUN=0 ./cleanup-orphan-inventory.sh clean-nonzero --batch-id biz-2026-08-07 --limit 100
./cleanup-orphan-inventory.sh rollback --batch-id biz-2026-08-07  # 误删回滚
```

---

## 六、阶段 4：长期修复 — 方案 A（物料删除前置校验）

### 6.1 改造目标

在 `MesMaterialServiceImpl.removeById` 加 3 层守卫：

```java
//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行根因修复】物料删除 3 层守卫-----------
@Override
@Transactional(rollbackFor = Exception.class)
public boolean removeById(Serializable id) {
    String materialId = id.toString();

    // 守卫 1: 库存检查（c_mes_inventory 有 qty > 0 禁止删）
    Long stockRows = baseMapper.selectCount(
        new QueryWrapper<MesInventory>().eq("material_id", materialId).gt("current_qty", 0));
    if (stockRows > 0) {
        throw new JeecgBootException("物料存在未清库存(" + stockRows + " 行)，禁止删除；请先盘点或调拨");
    }

    // 守卫 2: 未完结业务单据
    Long openBills = baseMapper.selectCount(new QueryWrapper<MesProductionOrder>()
        .eq("material_id", materialId)
        .notIn("status", "2", "3"));  // 2=已入库, 3=已关闭
    if (openBills > 0) {
        throw new JeecgBootException("物料被 " + openBills + " 个未完结生产订单引用，禁止删除");
    }
    // 采购入库/销售出库同理

    // 守卫 3: 活跃批次
    Long activeBatches = batchMapper.selectCount(
        new QueryWrapper<MesBatch>().eq("material_id", materialId).eq("del_flag", 0));
    if (activeBatches > 0) {
        throw new JeecgBootException("物料被 " + activeBatches + " 个批次引用，禁止删除");
    }

    return super.removeById(id);
}
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行根因修复】物料删除守卫
```

### 6.2 影响评估

| 维度 | 影响 |
|---|---|
| 存量孤儿行 | 不会自动清（需阶段 2 + 3 处理） |
| 后续删除 | 必须先清干净才能删，杜绝新生孤儿 |
| 业务感知 | 物料删除可能因关联数据被拒，业务流程需调整 |
| 回归测试 | 必跑（删除用例要重写） |

---

## 七、阶段 5：回归测试补充

### 7.1 新增 3 个测试文件

| 文件 | 覆盖 |
|---|---|
| `harness/tests/modules/inventory-orphan-ui-delete.test.js` | UI 单删 + 批量删 API（含安全守门） |
| `harness/tests/modules/inventory-orphan-export.test.js` | 导出孤儿清单 Excel（含数据正确性） |
| `harness/tests/modules/material-delete-guard.test.js` | 物料删除 3 层守卫（有库存/有单据/有批次 → 拒绝） |

### 7.2 inventory-orphan-ui-delete.test.js 模板

```javascript
// 切片: 库存总览孤儿行 UI 删除测试
const { createClient } = require('../helpers/api');

const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';
const ENDPOINT = '/mes/warehouse/inventory';

(async () => {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== 库存总览孤儿行 UI 删除测试 =====\n');

  // 0. 准备：找一个孤儿行
  const list = await c.api('GET', `${ENDPOINT}/list?pageNo=1&pageSize=100`);
  const orphans = list.result.records.filter((r) => !r.material_code);
  console.log(`发现孤儿行: ${orphans.length} 条`);

  if (orphans.length === 0) {
    console.log('⚠️ 无孤儿行可测，跳过（需先在 DB 制造测试数据）');
    return;
  }

  // 1. 守门：qty > 0 的孤儿行禁止删
  const nonZero = orphans.find((r) => Number(r.current_qty) > 0);
  if (nonZero) {
    const r = await c.api('DELETE', `${ENDPOINT}/deleteOrphan?id=${nonZero.id}`);
    c.check('1.1 有库存孤儿行拒绝删除', r.code === 500 && r.message.includes('有库存'), r.message);
  } else {
    console.log('⏭️  无有库存孤儿行，跳过守门测试');
  }

  // 2. 正常删除：qty = 0 的孤儿行
  const zeroOrphan = orphans.find((r) => Number(r.current_qty) === 0);
  if (zeroOrphan) {
    const r = await c.api('DELETE', `${ENDPOINT}/deleteOrphan?id=${zeroOrphan.id}`);
    c.check('2.1 零库存孤儿行单删', r.code === 200, r.message);

    // 验证：审计表有记录
    // （需直接 SQL 查询或额外 API）
  }

  // 3. 批量删除：3 条 qty=0 孤儿行
  // （需先准备测试数据）

  // 4. 守门：非孤儿行禁止删
  // （找一条正常库存行，验证 deleteOrphan 拒绝）
})();
```

### 7.3 material-delete-guard.test.js 模板

```javascript
// 切片: 物料删除 3 层守卫测试
const { createClient } = require('../helpers/api');
const BASE = process.env.HARNESS_BASE || 'http://localhost:8080/jeecg-boot';

(async () => {
  const c = createClient(BASE);
  await c.login('mes_admin', '123456');

  console.log('\n===== 物料删除 3 层守卫测试 =====\n');

  // S1: 有库存的物料 → 删除应被拒
  // （选一个 c_mes_inventory.current_qty > 0 的物料）
  const mat1 = await c.api('GET', '/mes/basic/material/list?pageNo=1&pageSize=50');
  const withStock = mat1.result.records.find((m) => m.id);  // 简化：随机找一个
  if (withStock) {
    const r = await c.api('DELETE', `/mes/basic/material/delete?id=${withStock.id}`);
    c.check('S1 有库存物料禁止删除', r.code === 500 && r.message.includes('未清库存'), r.message);
  }

  // S2: 有未完结生产订单的物料 → 拒绝
  // S3: 有活跃批次的物料 → 拒绝
  // S4: 无任何关联的物料 → 可正常删除
})();
```

---

## 八、实施路线图

```
Day 1-2 (本周)
├── 阶段 1: UI 黄金模板对齐 + 增加删除按钮（前端 1 人日）
├── 阶段 2: 后端 3 个端点 + 审计 Service（后端 0.5 人日）
└── 部署到线上 → 业务人员用页面自助清理存量

Day 3-5 (下周)
├── 阶段 5: 3 个回归测试（QA 0.5 人日）
├── 阶段 4: 物料删除 3 层守卫（后端 0.5 人日）
└── 全量回归 + /vue-audit 库存页全绿

应急（随时）
└── DBA 跑 harness/scripts/sql/cleanup-orphan-inventory.sh（仅 UI 异常时）
```

## 九、风险与回滚

| 风险 | 缓解 |
|---|---|
| UI 误删业务行 | 后端安全守门（非孤儿行拒绝）+ qty>0 拒绝 |
| 守卫太严，业务卡壳 | 提供"强制删除"开关（仅超管权限） |
| 回归测试覆盖不足 | 强制 3 个新测试纳入主回归 |
| 守卫漏判（如其他引用） | 监控"新增孤儿行"指标，告警 |

## 十、成功标准

| 指标 | 目标 |
|---|---|
| 存量孤儿行 | 0（业务人员用页面清完） |
| 新增孤儿行 | 0/周（阶段 4 守卫生效） |
| 库存总览页"（物料已删除）"行 | 0 |
| `/vue-audit` 库存页 | 全 PASS |
| 回归测试 | 3 个新测试全部 PASS |
| DBA 介入次数 | 0/周（业务自助） |

---

*本文档由 /debug 会话自动生成。代码片段仅作示意，实施前需 review + 实际联调。*
