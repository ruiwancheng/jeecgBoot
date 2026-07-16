<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增入库</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <CompletionReceiptDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './completion.data';
  import { queryCompletionList, deleteCompletion, getExportUrl } from './completion.api';
  import CompletionReceiptDrawer from './CompletionReceiptDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesCompletionReceipt' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-manufacturing-completion',
    tableProps: {
      title: '完工入库',
      api: queryCompletionList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '完工入库', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    return [
      { label: '编辑', onClick: () => handleEdit(record) },
      { label: '删除', popConfirm: { title: '确认删除该入库单吗？', confirm: () => handleDelete(record) } },
    ];
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleDelete(record: Recordable) { await deleteCompletion({ id: record.id }); message.success('删除成功'); reload(); }
</script>
