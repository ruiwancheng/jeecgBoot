<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <!--update-begin---author:pi---date:2026-08-07---for:修复批次追溯抽屉异步内容渲染时序--->
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="'批次追溯：' + (batchNo || '')" width="900px" :destroyOnClose="false">
    <!--update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-口径提示Alert----------->
    <a-alert type="info" show-icon style="margin-bottom: 12px" message="按批次号反查所有相关流水：采购入库/生产完工/领料/销售出库。" />
    <!--update-end---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-口径提示Alert----------->
    <div class="traceability-drawer-content">
      <a-spin :spinning="loading">
        <!--update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-批次主档Descriptions----------->
        <a-descriptions v-if="batch" :column="2" bordered size="small" style="margin-bottom: 16px">
          <a-descriptions-item label="批次号">{{ batch.batchNo }}</a-descriptions-item>
          <a-descriptions-item label="物料">{{ batch.materialId_dictText || batch.materialId }}</a-descriptions-item>
          <a-descriptions-item label="初始数量">{{ batch.qty }}</a-descriptions-item>
          <a-descriptions-item label="批次成本">¥ {{ formatMoney(batch.unitCost) }}</a-descriptions-item>
          <a-descriptions-item label="生产日期">{{ batch.productionDate }}</a-descriptions-item>
          <a-descriptions-item label="有效期">{{ batch.expiryDate }}</a-descriptions-item>
          <a-descriptions-item label="来源类型">
            <a-tag :color="getStatusColor('origin', batch.originType)">{{ batch.originType_dictText }}</a-tag>
          </a-descriptions-item>
          <a-descriptions-item label="来源单据">{{ batch.originBillNo }}</a-descriptions-item>
        </a-descriptions>
        <!-- 保留一个稳定的 slot 子节点，避免 loading 阶段 descriptions 尚未注入时 Spin 裁掉内容高度。 -->
        <div v-else style="min-height: 1px"></div>
        <!--update-end---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-批次主档Descriptions----------->
      </a-spin>

      <!-- 批次流水标题和表格不依赖任一接口响应，抽屉打开即渲染，避免 loading 时序导致主流程锚点缺失。 -->
      <a-divider class="traceability-ledger-divider" data-testid="traceability-ledger-title">批次流水</a-divider>
      <!--update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-流水Table----------->
      <a-table :dataSource="ledgerItems" :columns="ledgerColumns" :pagination="false" size="small" rowKey="id">
        <template #bodyCell="{ column, record }">
          <template v-if="column.dataIndex === 'inQty'">
            <span style="color: green">{{ record.inQty > 0 ? record.inQty : '' }}</span>
          </template>
          <template v-else-if="column.dataIndex === 'outQty'">
            <span style="color: red">{{ record.outQty > 0 ? record.outQty : '' }}</span>
          </template>
          <template v-else-if="column.dataIndex === 'unitCost'">
            <span>¥ {{ formatMoney(record.unitCost) }}</span>
          </template>
        </template>
      </a-table>
      <div v-if="!loading && !ledgerItems.length" style="color: #999; padding: 16px; text-align: center">该批次暂无流水</div>
      <!--update-end---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-流水Table----------->
    </div>
  </BasicDrawer>
  <!--update-end---author:pi---date:2026-08-07---for:修复批次追溯抽屉异步内容渲染时序--->
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  //update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-接口调用-----------
  import { listLedgerByBatchId, queryBatchList } from './traceability.api';
  import { getStatusColor } from '../shared/statusColor';
  //update-end---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-接口调用-----------

  defineEmits(['register']);
  const loading = ref(false);
  const batch = ref<any>(null);
  const ledgerItems = ref<any>([]);
  const batchNo = computed(() => batch.value?.batchNo);
  let loadSequence = 0;

  //update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-流水列定义-----------
  const ledgerColumns = [
    { title: '时间', dataIndex: 'occurTime', width: 150 },
    { title: '业务类型', dataIndex: 'bizType', width: 100 },
    { title: '业务单据', dataIndex: 'bizNo', width: 140 },
    { title: '入库', dataIndex: 'inQty', width: 100 },
    { title: '出库', dataIndex: 'outQty', width: 100 },
    { title: '批次成本', dataIndex: 'unitCost', width: 100 },
    { title: '备注', dataIndex: 'remark' },
  ];
  //update-end---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-流水列定义-----------

  //update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-金额格式化-----------
  /**
   * 金额格式化：null/undefined 返回 '-'，否则保留 4 位小数（与批次单据精度对齐）。
   */
  function formatMoney(v: any): string {
    if (v == null || v === '') return '-';
    const n = Number(v);
    if (isNaN(n)) return String(v);
    return n.toFixed(4).replace(/\.?0+$/, '') || '0';
  }
  //update-end---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-金额格式化-----------

  //update-begin---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-主档+流水加载逻辑-----------
  //update-begin---author:pi---date:2026-08-07---for:修复批次追溯抽屉异步内容渲染时序---
  function getRecords(response: any): any[] {
    const result = response?.result;
    if (Array.isArray(result)) return result;
    if (Array.isArray(result?.records)) return result.records;
    return [];
  }

  const [registerDrawer] = useDrawerInner(async (data) => {
    const sequence = ++loadSequence;
    batch.value = null;
    ledgerItems.value = [];
    loading.value = false;
    if (!data?.batchId) return;

    loading.value = true;
    try {
      const [batchResp, ledgerResp] = await Promise.all([
        queryBatchList({ id: data.batchId, pageSize: 1 }),
        listLedgerByBatchId({ batchId: data.batchId }),
      ]);
      if (sequence !== loadSequence) return;

      const batchRecords = getRecords(batchResp);
      batch.value = batchRecords[0] || null;
      ledgerItems.value = getRecords(ledgerResp);
    } catch {
      // 接口失败时保留抽屉结构，让用户仍能看到流水表头和明确的空状态。
      if (sequence === loadSequence) {
        batch.value = null;
        ledgerItems.value = [];
      }
    } finally {
      if (sequence === loadSequence) loading.value = false;
    }
  });
  //update-end---author:pi---date:2026-08-07---for:修复批次追溯抽屉异步内容渲染时序---
  //update-end---author:ruiwancheng---date:20260803---for: V10.0.2 trace-2-detail 批次追溯Drawer详情接入-主档+流水加载逻辑-----------
</script>
