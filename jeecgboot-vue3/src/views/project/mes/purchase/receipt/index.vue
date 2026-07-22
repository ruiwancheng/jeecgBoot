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
    <ReceiptDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './receipt.data';
  import { queryReceiptList, deleteReceipt, getExportUrl, auditReceipt } from './receipt.api';
  import ReceiptDrawer from './ReceiptDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesPurchaseReceipt' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-purchase-receipt',
    tableProps: {
      title: '采购入库',
      api: queryReceiptList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '采购入库', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    const acts: any[] = [];
    if (record.status == '1') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '审核', popConfirm: { title: '确认审核该入库单吗？', confirm: () => handleAudit(record) } });
      acts.push({ label: '删除', popConfirm: { title: '确认删除该入库单吗？', confirm: () => handleDelete(record) } });
    }
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleDelete(record: Recordable) { await deleteReceipt({ id: record.id }); message.success('删除成功'); reload(); }
  async function handleAudit(record: Recordable) { await auditReceipt({ id: record.id }); message.success('审核成功，库存已更新'); reload(); }
</script>
