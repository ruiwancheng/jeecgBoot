<template>
  <div style="padding: 4px 16px 8px 48px; background: #fafafa">
    <a-spin :spinning="loading">
      <a-table :dataSource="items" :columns="cols" :pagination="false" size="small" rowKey="id">
        <template #bodyCell="{ column, record }">
          <template v-if="column.dataIndex === 'material'">
            <span>{{ materialText(record) }}</span>
          </template>
          <template v-else-if="column.dataIndex === 'taxRate'">
            <span>{{ record.taxRate != null ? (record.taxRate * 100).toFixed(0) + '%' : '-' }}</span>
          </template>
        </template>
      </a-table>
      <div v-if="!loading && !items.length" style="color: #999; padding: 8px">该订单暂无物料明细</div>
    </a-spin>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { queryOrderById } from './order.api';
  import { queryMaterialById } from '../../basic/material/material.api';

  const props = defineProps<{ orderId: string }>();

  const loading = ref(false);
  const items = ref<any[]>([]);
  const materialMap = ref<Record<string, any>>({});

  const cols = [
    { title: '物料', dataIndex: 'material', width: 220 },
    { title: '规格型号', dataIndex: 'spec', width: 120 },
    { title: '单位', dataIndex: 'unitText', width: 70 },
    { title: '数量', dataIndex: 'quantity', width: 90 },
    { title: '单价', dataIndex: 'unitPrice', width: 100 },
    { title: '税率', dataIndex: 'taxRate', width: 70 },
    { title: '金额', dataIndex: 'amount', width: 110 },
    { title: '累计入库量', dataIndex: 'receivedQty', width: 100 },
  ];

  function materialText(record: any) {
    const m = materialMap.value[record.materialId];
    if (m) return `${m.code} — ${m.name}`;
    return record.materialId_dictText || record.materialId || '-';
  }

  onMounted(async () => {
    loading.value = true;
    try {
      const order = await queryOrderById({ id: props.orderId });
      items.value = order?.items || [];
      const ids = [...new Set(items.value.map((i) => i.materialId).filter(Boolean))] as string[];
      const materials = await Promise.all(ids.map((id) => queryMaterialById({ id }).catch(() => null)));
      const map: Record<string, any> = {};
      materials.forEach((m) => { if (m?.id) map[m.id] = m; });
      materialMap.value = map;
      items.value = items.value.map((i) => ({
        ...i,
        spec: map[i.materialId]?.spec || '-',
        unitText: map[i.materialId]?.unit_dictText || '-',
      }));
    } catch (e) {
      items.value = [];
    } finally {
      loading.value = false;
    }
  });
</script>
