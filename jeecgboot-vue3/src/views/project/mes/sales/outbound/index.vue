<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增出库单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <OutboundDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './outbound.data';
  import { queryOutboundList, deleteOutbound, getExportUrl } from './outbound.api';
  import OutboundDrawer from './OutboundDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesSalesOutbound' });
  const [registerDrawer, { openDrawer }] = useDrawer();

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-outbound',
    tableProps: { title: '销售出库', api: queryOutboundList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '销售出库', url: getExportUrl },
  });
  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) { return [
    { label: '编辑', onClick: () => openDrawer(true, { record, isUpdate: true }) },
    { label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(record) } },
  ];}
  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  async function handleDelete(r: Recordable) { await deleteOutbound({ id: r.id }); message.success('删除成功'); reload(); }
</script>
