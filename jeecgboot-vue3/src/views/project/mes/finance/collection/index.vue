<!--update-begin---author:pi---date:2026-08-04---for:【TKT-001】财务收款页改用 useDrawer（修复 #9 路由 404）----------->
<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增收款</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
    </BasicTable>
    <CollectionDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './collection.data';
  import { queryCollectionList, getExportUrl } from './collection.api';
  import CollectionDrawer from './CollectionDrawer.vue';

  defineOptions({ name: 'MesCollection' });
  const [registerDrawer, { openDrawer }] = useDrawer();
  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-collection',
    tableProps: { title: '收款单', api: queryCollectionList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '收款单', url: getExportUrl },
  });
  const [registerTable, { reload }] = tableContext;
  function handleAdd() { openDrawer(true, { isUpdate: false }); }
</script>
<!--update-end---author:pi---date:2026-08-04---for:【TKT-001】财务收款页改用 useDrawer（修复 #9 路由 404）----------->
