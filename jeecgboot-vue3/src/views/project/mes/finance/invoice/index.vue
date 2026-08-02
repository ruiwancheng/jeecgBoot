<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增发票</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <SalesInvoiceDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>
<script lang="ts" setup>
  import { BasicTable, useTable, TableAction } from '/@/components/Table'; import { useListPage } from '/@/hooks/system/useListPage'; import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './invoice.data'; import { queryInvoiceList, deleteInvoice, getExportUrl } from './invoice.api';
  import SalesInvoiceDrawer from './InvoiceDrawer.vue'; import { message } from 'ant-design-vue';
  defineOptions({ name: 'MesSalesInvoice' });
  const [registerDrawer, { openDrawer }] = useDrawer();
  const { tableContext, onExportXls } = useListPage({ designScope: 'mes-invoice', tableProps: { title: '销项发票', api: queryInvoiceList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } }, exportConfig: { name: '销项发票', url: getExportUrl } });
  const [registerTable, { reload }] = tableContext;
  function getActions(r: Recordable) { return [{ label: '编辑', onClick: () => openDrawer(true, { record: r, isUpdate: true }) }, { label: '删除', popConfirm: { title: '确认删除?', confirm: () => handleDelete(r) } }]; }
  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  async function handleDelete(r: Recordable) { await deleteInvoice({ id: r.id }); message.success('删除成功'); reload(); }
</script>
