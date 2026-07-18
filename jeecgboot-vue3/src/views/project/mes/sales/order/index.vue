<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增订单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <OrderDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './order.data';
  import { queryOrderList, deleteOrder, auditOrder, releaseOrder, closeOrder, cancelOrder, getExportUrl } from './order.api';
  import OrderDrawer from './OrderDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesSalesOrder' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-order',
    tableProps: {
      title: '销售订单',
      api: queryOrderList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '销售订单', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转按钮-----------
  function getActions(record: Recordable) {
    const acts: any[] = [];
    if (record.status == '1') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '审核', popConfirm: { title: '确认审核？', confirm: () => handleAudit(record) } });
      acts.push({ label: '关闭', popConfirm: { title: '确认关闭？', confirm: () => handleClose(record) } });
      acts.push({ label: '取消', popConfirm: { title: '确认取消？', confirm: () => handleCancel(record) } });
      acts.push({ label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(record) } });
    }
    if (record.status == '2') {
      acts.push({ label: '下达', popConfirm: { title: '确认下达？', confirm: () => handleRelease(record) } });
    }
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleDelete(record: Recordable) { await deleteOrder({ id: record.id }); message.success('删除成功'); reload(); }
  async function handleAudit(record: Recordable) { await auditOrder({ id: record.id }); message.success('审核成功'); reload(); }
  async function handleRelease(record: Recordable) { await releaseOrder({ id: record.id }); message.success('下达成功'); reload(); }
  async function handleClose(record: Recordable) { await closeOrder({ id: record.id }); message.success('已关闭'); reload(); }
  async function handleCancel(record: Recordable) { await cancelOrder({ id: record.id }); message.success('已取消'); reload(); }
  //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转按钮-----------
</script>
