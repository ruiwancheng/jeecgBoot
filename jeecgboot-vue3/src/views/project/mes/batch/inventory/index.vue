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
  import { BasicTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './inventory.data';
  import { queryInventoryList, getExportUrl } from './inventory.api';

  defineOptions({ name: 'MesBatchInventory' });

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-batch-inventory',
    tableProps: {
      title: '批次库存',
      api: queryInventoryList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '批次库存', url: getExportUrl },
  });
  //update-begin---author:ruiwancheng---date:20260801---for:/debug 修复 registerTable 未定义导致表格不加载数据-----------
  // useListTable 返回 [register, methods, selection] tuple，index.vue 漏解构导致 @register="registerTable" 拿到 undefined
  const [registerTable] = tableContext;
  //update-end---author:ruiwancheng---date:20260801---for:/debug 修复 registerTable 未定义导致表格不加载数据-----------
</script>
