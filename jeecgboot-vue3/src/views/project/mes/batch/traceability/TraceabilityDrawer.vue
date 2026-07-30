<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="'批次追溯：' + (batchNo || '')" width="900px" destroyOnClose>
    <a-alert type="info" show-icon style="margin-bottom: 12px" message="按批次号反查所有相关流水：采购入库/生产完工/领料/销售出库。" />
    <a-spin :spinning="loading">
      <a-descriptions v-if="batch" :column="2" bordered size="small" style="margin-bottom: 16px">
        <a-descriptions-item label="批次号">{{ batch.batchNo }}</a-descriptions-item>
        <a-descriptions-item label="物料">{{ batch.materialId_dictText || batch.materialId }}</a-descriptions-item>
        <a-descriptions-item label="初始数量">{{ batch.qty }}</a-descriptions-item>
        <a-descriptions-item label="批次成本">{{ batch.unitCost }}</a-descriptions-item>
        <a-descriptions-item label="生产日期">{{ batch.productionDate }}</a-descriptions-item>
        <a-descriptions-item label="有效期">{{ batch.expiryDate }}</a-descriptions-item>
        <a-descriptions-item label="来源类型">
          <a-tag :color="getStatusColor('origin', batch.originType)">{{ batch.originType_dictText }}</a-tag>
        </a-descriptions-item>
        <a-descriptions-item label="来源单据">{{ batch.originBillNo }}</a-descriptions-item>
      </a-descriptions>
      <a-divider>批次流水</a-divider>
      <a-table :dataSource="ledgerItems" :columns="ledgerColumns" :pagination="false" size="small" rowKey="id">
        <template #bodyCell="{ column, record }">
          <template v-if="column.dataIndex === 'inQty'">
            <span style="color: green">{{ record.inQty > 0 ? record.inQty : '' }}</span>
          </template>
          <template v-else-if="column.dataIndex === 'outQty'">
            <span style="color: red">{{ record.outQty > 0 ? record.outQty : '' }}</span>
          </template>
        </template>
      </a-table>
      <div v-if="!loading && !ledgerItems.length" style="color: #999; padding: 16px; text-align: center">该批次暂无流水</div>
    </a-spin>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed } from 'vue';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { listLedgerByBatchId, queryBatchList } from './traceability.api';
  import { getStatusColor } from '../shared/statusColor';

  const emit = defineEmits(['register']);
  const loading = ref(false);
  const batch = ref<any>(null);
  const ledgerItems = ref<any[]>([]);
  const batchNo = computed(() => batch.value?.batchNo);

  const ledgerColumns = [
    { title: '时间', dataIndex: 'occurTime', width: 150 },
    { title: '业务类型', dataIndex: 'bizType', width: 100 },
    { title: '业务单据', dataIndex: 'bizNo', width: 140 },
    { title: '入库', dataIndex: 'inQty', width: 100 },
    { title: '出库', dataIndex: 'outQty', width: 100 },
    { title: '批次成本', dataIndex: 'unitCost', width: 100 },
    { title: '备注', dataIndex: 'remark' },
  ];

  const [registerDrawer] = useDrawerInner(async (data) => {
    if (!data?.batchId) return;
    loading.value = true;
    try {
      // 1. 查批次主档
      const batchResp = await queryBatchList({ id: data.batchId, pageSize: 1 });
      if (batchResp?.result?.records?.length) {
        batch.value = batchResp.result.records[0];
      }
      // 2. 查批次流水
      const ledgerResp = await listLedgerByBatchId({ batchId: data.batchId });
      ledgerItems.value = ledgerResp?.result || [];
    } finally {
      loading.value = false;
    }
  });
</script>
