<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增发货单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <DeliveryDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './delivery.data';
  import { queryDeliveryList, deleteDelivery, submitDelivery, signDelivery, cancelDelivery, getExportUrl } from './delivery.api';
  import DeliveryDrawer from './DeliveryDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesSalesDelivery' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-delivery',
    tableProps: {
      title: '发货单',
      api: queryDeliveryList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '发货单', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转按钮-----------
  function getActions(record: Recordable) {
    const acts: any[] = [];
    if (record.status == '1') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '提交', popConfirm: { title: '确认提交？', confirm: () => handleSubmit(record) } });
      acts.push({ label: '取消', popConfirm: { title: '确认取消？', confirm: () => handleCancel(record) } });
      acts.push({ label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(record) } });
    }
    if (record.status == '3') {
      acts.push({ label: '签收', popConfirm: { title: '确认签收？', confirm: () => handleSign(record) } });
    }
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleDelete(record: Recordable) { await deleteDelivery({ id: record.id }); message.success('删除成功'); reload(); }
  async function handleSubmit(record: Recordable) { await submitDelivery({ id: record.id }); message.success('提交成功'); reload(); }
  async function handleSign(record: Recordable) { await signDelivery({ id: record.id }); message.success('签收成功'); reload(); }
  async function handleCancel(record: Recordable) { await cancelDelivery({ id: record.id }); message.success('已取消'); reload(); }
  //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 状态流转按钮-----------
</script>
