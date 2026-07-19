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
  import { columns, searchFormSchema } from './receivable.data';
  import { queryReceivableList, getExportUrl } from './receivable.api';

  defineOptions({ name: 'MesReceivable' });

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-receivable',
    tableProps: {
      title: '应收账款',
      api: queryReceivableList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '应收账款', url: getExportUrl },
  });

  const [registerTable] = tableContext;
</script>
