<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增价格</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <j-upload-button type="primary" preIcon="ant-design:import-outlined" @click="onImportXls">导入</j-upload-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <PriceDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './price.data';
  import { queryPriceList, deletePrice, getExportUrl, getImportUrl } from './price.api';
  import PriceDrawer from './PriceDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesSalesPrice' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls, onImportXls } = useListPage({
    designScope: 'mes-price',
    tableProps: {
      title: '价格管理',
      api: queryPriceList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '价格管理', url: getExportUrl },
    importConfig: { url: getImportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    return [
      { label: '编辑', onClick: () => handleEdit(record) },
      { label: '删除', popConfirm: { title: '确认删除该价格吗？', confirm: () => handleDelete(record) } },
    ];
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleDelete(record: Recordable) { await deletePrice({ id: record.id }); message.success('删除成功'); reload(); }
</script>
