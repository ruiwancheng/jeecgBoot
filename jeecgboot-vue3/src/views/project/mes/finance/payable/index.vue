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
  import { columns, searchFormSchema } from './payable.data';
  import { queryPayableList, getExportUrl } from './payable.api';

  defineOptions({ name: 'MesPayable' });

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-payable',
    tableProps: {
      title: '应付账款',
      api: queryPayableList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '应付账款', url: getExportUrl },
  });

  const [registerTable] = tableContext;
</script>
