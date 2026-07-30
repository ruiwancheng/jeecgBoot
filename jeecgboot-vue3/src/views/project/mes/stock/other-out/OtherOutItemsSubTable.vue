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
      <div v-if="!loading && !items.length" style="color: #999; padding: 8px">该单据暂无明细</div>
    </a-spin>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { queryOtherOutById } from './otherOut.api';
  import { queryMaterialById } from '../../basic/material/material.api';

  const props = defineProps<{ docId: string }>();

  const loading = ref(false);
  const items = ref<any[]>([]);
  const materialMap = ref<Record<string, any>>({});

  const cols = [
    { title: '物料', dataIndex: 'material', width: 220 },
    { title: '规格型号', dataIndex: 'spec', width: 120 },
    { title: '数量', dataIndex: 'qty', width: 100 },
    { title: '成本单价', dataIndex: 'unitCost', width: 100 },
    { title: '金额', dataIndex: 'amount', width: 100 },
  ];

  function materialText(record: any) {
    const m = materialMap.value[record.materialId];
    if (m) return m.code;
    return record.materialId_dictText || record.materialId || '-';
  }

  onMounted(async () => {
    loading.value = true;
    try {
      const doc = await queryOtherOutById({ id: props.docId });
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
