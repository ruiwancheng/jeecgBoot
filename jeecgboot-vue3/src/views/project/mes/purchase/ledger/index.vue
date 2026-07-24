<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #materialId="{ record }">
        <span>{{ getMaterialCode(record.materialId) || record.materialId || '-' }}</span>
      </template>
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { BasicTable, useTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './ledger.data';
  import { queryLedgerList, getExportUrl } from './ledger.api';
  import { queryAllMaterial } from '../../basic/material/material.api';

  defineOptions({ name: 'MesInventoryLedger' });

  const materialMap = ref<Record<string, any>>({});

  function getMaterialCode(materialId: string): string {
    return materialMap.value[materialId]?.code || '';
  }

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-inventory-ledger',
    tableProps: {
      title: '库存台账',
      api: queryLedgerList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '库存台账', url: getExportUrl },
  });

  const [registerTable] = tableContext;

  onMounted(async () => {
    try {
      const materials: any[] = await queryAllMaterial() || [];
      const map: Record<string, any> = {};
      materials.forEach((m: any) => { if (m?.id) map[m.id] = m; });
      materialMap.value = map;
    } catch (e) { /* ignore */ }
  });
</script>
