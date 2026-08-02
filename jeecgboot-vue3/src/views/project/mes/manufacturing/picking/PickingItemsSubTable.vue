<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
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
      <div v-if="!loading && !items.length" style="color: #999; padding: 8px">该领料单暂无明细</div>
    </a-spin>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { queryPickingById } from './picking.api';
  import { queryMaterialById } from '../../basic/material/material.api';

  const props = defineProps<{ pickingId: string }>();

  const loading = ref(false);
  const items = ref<any>([]);
  const materialMap = ref<Record<string, any>>({});

  const cols = [
    { title: '物料', dataIndex: 'material', width: 220 },
    { title: '规格型号', dataIndex: 'spec', width: 120 },
    { title: '领料数量', dataIndex: 'quantity', width: 100 },
    { title: '备注', dataIndex: 'remark', width: 150 },
  ];

  function materialText(record: any) {
    const m = materialMap.value[record.materialId];
    if (m) return m.code;
    return record.materialId_dictText || record.materialId || '-';
  }

  onMounted(async () => {
    loading.value = true;
    try {
      const doc = await queryPickingById({ id: props.pickingId });
      items.value = doc?.items || [];
      const ids = [...new Set(items.value.map((i) => i.materialId).filter(Boolean))] as string[];
      const materials = await Promise.all(ids.map((id) => queryMaterialById({ id }).catch(() => null)));
      const map: Record<string, any> = {};
      materials.forEach((m) => {
        if (m?.id) map[m.id] = m;
      });
      materialMap.value = map;
      items.value = items.value.map((i) => ({ ...i, spec: map[i.materialId]?.spec || '-' }));
    } catch (e) {
      items.value = [];
    } finally {
      loading.value = false;
    }
  });
</script>
