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

  defineOptions({ name: 'MesInventoryLedger' });

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

  const [registerTable, { reload }] = tableContext;
</script>
