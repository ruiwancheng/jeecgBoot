<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './ledger.data';
  import { queryLedgerList, getExportUrl } from './ledger.api';

  defineOptions({ name: 'MesBatchLedger' });

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-batch-ledger',
    tableProps: {
      title: '批次流水',
      api: queryLedgerList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '批次流水', url: getExportUrl },
  });
</script>
