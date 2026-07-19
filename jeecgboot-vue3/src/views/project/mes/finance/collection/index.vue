<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增收款</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './collection.data';
  import { queryCollectionList, getExportUrl } from './collection.api';
  import { useRouter } from 'vue-router';

  defineOptions({ name: 'MesCollection' });
  const router = useRouter();
  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-collection',
    tableProps: { title: '收款单', api: queryCollectionList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '收款单', url: getExportUrl },
  });
  const [registerTable] = tableContext;
  function handleAdd() { router.push('/project/mes/finance/collection/add'); }
</script>
