<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #materialId="{ record }">
        <span>{{ getMaterialCode(record.materialId) || record.materialId || '-' }}</span>
      </template>
      <!-- A+ 成本差异高亮：手工价与移动平均不一致时飘红 -->
      <template #costDiff="{ record }">
        <span v-if="record.costDiff && Number(record.costDiff) !== 0" style="color: #f5222d; font-weight: 600">{{ record.costDiff }}</span>
        <span v-else style="color: #999">0.00</span>
      </template>
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { BasicTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './ledger.data';
  import { queryLedgerList, getExportUrl } from './ledger.api';
  import { selectMaterialPage } from '../../basic/material/material.api';

  defineOptions({ name: 'MesInventoryLedger' });

  const materialMap = ref<Record<string, any>>({});

  function getMaterialCode(materialId: string): string {
    return materialMap.value[materialId]?.code || '';
  }

  const { tableContext, onExportXls } = useListPage({
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
      // 物料超1000条时 queryAll 接口会拒绝（保护上限），改用分页接口全量拉取
      const map: Record<string, any> = {};
      const PAGE_SIZE = 1000;
      for (let pageNo = 1; pageNo <= 20; pageNo++) {
        const res: any = await selectMaterialPage({ pageNo, pageSize: PAGE_SIZE });
        const records = res?.records || [];
        records.forEach((m: any) => { if (m?.id) map[m.id] = m; });
        if (records.length < PAGE_SIZE) break;
      }
      materialMap.value = map;
    } catch (e) { /* ignore */ }
  });
</script>
