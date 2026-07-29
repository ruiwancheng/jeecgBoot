<template>
  <div style="padding: 4px 16px 8px 48px; background: #fafafa">
    <a-spin :spinning="loading">
      <a-table :dataSource="items" :columns="cols" :pagination="false" size="small" rowKey="id">
        <template #bodyCell="{ column, record }">
          <template v-if="column.dataIndex === 'material'">
            <span>{{ materialText(record) }}</span>
          </template>
          <template v-else-if="column.dataIndex === 'diffQty'">
            <span :style="{ color: Number(record.diffQty) !== 0 ? '#f5222d' : '#999', fontWeight: Number(record.diffQty) !== 0 ? 600 : 400 }">{{ record.diffQty ?? '-' }}</span>
          </template>
        </template>
      </a-table>
      <div v-if="!loading && !items.length" style="color: #999; padding: 8px">该盘点单暂无明细</div>
    </a-spin>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { queryStocktakeById } from './stocktake.api';
  import { queryMaterialsByIds } from '../../basic/material/material.api';

  const props = defineProps<{ docId: string }>();

  const loading = ref(false);
  const items = ref<any[]>([]);
  const materialMap = ref<Record<string, any>>({});

  const cols = [
    { title: '物料', dataIndex: 'material', width: 220 },
    { title: '账面数', dataIndex: 'bookQty', width: 90 },
    { title: '实盘数', dataIndex: 'actualQty', width: 90 },
    { title: '差异', dataIndex: 'diffQty', width: 90 },
    { title: '成本单价', dataIndex: 'unitCost', width: 100 },
    { title: '差异金额', dataIndex: 'diffAmount', width: 100 },
    { title: '调整单', dataIndex: 'generated', width: 160 },
  ];

  function materialText(record: any) {
    const m = materialMap.value[record.materialId];
    if (m) return `${m.code} — ${m.name}`;
    return record.materialId_dictText || record.materialId || '-';
  }

  onMounted(async () => {
    loading.value = true;
    try {
      const doc = await queryStocktakeById({ id: props.docId });
      items.value = (doc?.items || []).map((it: any) => ({
        ...it,
        generated: it.generatedInId ? '盘盈入库单' : it.generatedOutId ? '盘亏出库单' : '',
      }));
      const ids = [...new Set(items.value.map((i) => i.materialId).filter(Boolean))] as string[];
      const materials = ids.length ? await queryMaterialsByIds(ids).catch(() => []) : [];
      const map: Record<string, any> = {};
      (materials || []).forEach((m: any) => { if (m?.id) map[m.id] = m; });
      materialMap.value = map;
    } finally { loading.value = false; }
  });
</script>
