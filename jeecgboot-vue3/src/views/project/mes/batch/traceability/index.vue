<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <a-alert type="info" show-icon style="margin-bottom:12px" message="点击「查看追溯」按钮，可查看该批次的所有流水记录（采购入库/生产完工/领料/销售出库）。" />
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('batch', record.status)">{{ record.status_dictText || '在用' }}</a-tag>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <TraceabilityDrawer @register="registerDrawer" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, _useTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './traceability.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryBatchList, getExportUrl } from './traceability.api';
  import TraceabilityDrawer from './TraceabilityDrawer.vue';

  defineOptions({ name: 'MesBatchTraceability' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-batch-traceability',
    tableProps: {
      title: '批次追溯',
      api: queryBatchList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '批次追溯', url: getExportUrl },
  });

  const [registerTable] = tableContext;

  function getActions(record: Recordable) {
    return [
      { label: '查看追溯', onClick: () => openDrawer(true, { batchId: record.id }) },
    ];
  }
</script>