<template>
  <div style="padding: 4px 16px 8px 48px; background: #fafafa">
    <div style="color:#888; padding:4px 0">最近台账（8 条）</div>
    <a-spin :spinning="loading">
      <a-table :dataSource="rows" :columns="cols" :pagination="false" size="small" rowKey="id">
        <template #bodyCell="{ column, record }">
          <template v-if="column.dataIndex === 'costDiff'">
            <span :style="{ color: Number(record.costDiff) !== 0 ? '#f5222d' : '#999', fontWeight: Number(record.costDiff) !== 0 ? 600 : 400 }">{{ record.costDiff ?? '-' }}</span>
          </template>
        </template>
      </a-table>
      <div v-if="!loading && !rows.length" style="color: #999; padding: 8px">暂无台账记录</div>
    </a-spin>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { defHttp } from '/@/utils/http/axios';

  const props = defineProps<{ materialId?: string; warehouseId?: string }>();

  const loading = ref(false);
  const rows = ref<any[]>([]);
  const cols = [
    { title: '业务类型', dataIndex: 'bizType', width: 100 },
    { title: '入库', dataIndex: 'inQty', width: 70 },
    { title: '出库', dataIndex: 'outQty', width: 70 },
    { title: '单位成本', dataIndex: 'unitCost', width: 90 },
    { title: '成本差异', dataIndex: 'costDiff', width: 90 },
    { title: '记录日期', dataIndex: 'recordDate', width: 100 },
    { title: '单号', dataIndex: 'bizId', width: 160 },
    { title: '备注', dataIndex: 'remark', width: 200 },
  ];

  onMounted(async () => {
    if (!props.materialId || !props.warehouseId) return;
    loading.value = true;
    try {
      const res: any = await defHttp.get({
        url: '/mes/warehouse/ledger/list',
        params: { materialId: props.materialId, warehouseId: props.warehouseId, pageNo: 1, pageSize: 8 },
      });
      rows.value = res?.records || [];
    } finally { loading.value = false; }
  });
</script>
