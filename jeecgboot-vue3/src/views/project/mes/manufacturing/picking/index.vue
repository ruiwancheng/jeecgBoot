<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增领料</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <PickingDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './picking.data';
  import { queryPickingList, deletePicking, getExportUrl } from './picking.api';
  import PickingDrawer from './PickingDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesProductionPicking' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-manufacturing-picking',
    tableProps: {
      title: '生产领料',
      api: queryPickingList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '生产领料', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    return [
      { label: '编辑', onClick: () => handleEdit(record) },
      { label: '删除', popConfirm: { title: '确认删除该领料单吗？', confirm: () => handleDelete(record) } },
    ];
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleDelete(record: Recordable) { await deletePicking({ id: record.id }); message.success('删除成功'); reload(); }
</script>
