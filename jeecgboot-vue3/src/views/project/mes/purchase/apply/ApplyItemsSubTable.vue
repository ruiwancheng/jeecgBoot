<template>
  <div style="padding: 4px 16px 8px 48px; background: #fafafa">
    <a-spin :spinning="loading">
      <a-table :dataSource="items" :columns="cols" :pagination="false" size="small" rowKey="id">
        <template #bodyCell="{ column, record }">
          <template v-if="column.dataIndex === 'material'">
            <span>{{ materialText(record) }}</span>
          </template>
        </template>
      </a-table>
      <div v-if="!loading && !items.length" style="color: #999; padding: 8px">该申请暂无物料明细</div>
    </a-spin>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { queryApplyById } from './apply.api';
  import { queryMaterialById } from '../../basic/material/material.api';

  const props = defineProps<{ applyId: string }>();

  const loading = ref(false);
  const items = ref<any[]>([]);
  const materialMap = ref<Record<string, any>>({});

  const cols = [
    { title: '物料', dataIndex: 'material', width: 220 },
    { title: '规格型号', dataIndex: 'spec', width: 120 },
    { title: '单位', dataIndex: 'unitText', width: 70 },
    { title: '申请数量', dataIndex: 'quantity', width: 100 },
    { title: '用途说明', dataIndex: 'purpose', width: 200 },
  ];

  function materialText(record: any) {
    const m = materialMap.value[record.materialId];
    if (m) return m.code;
    return record.materialId_dictText || record.materialId || '-';
  }

  onMounted(async () => {
    loading.value = true;
    try {
      const apply = await queryApplyById({ id: props.applyId });
      items.value = apply?.items || [];
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
