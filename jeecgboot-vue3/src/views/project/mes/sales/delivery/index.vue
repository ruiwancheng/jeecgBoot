<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增发货单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <!--update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
        <template v-if="selectedRowKeys.length > 0">
          <a-divider type="vertical" />
          <span style="color:#999;margin-right:8px">已选{{ selectedRowKeys.length }}项</span>
          <a-button v-if="allStatus == '1'" type="primary" @click="batchSubmit">提交</a-button>
          <a-button v-if="allStatus == '1'" danger @click="batchCancel">取消</a-button>
          <a-button v-if="allStatus == '3'" type="primary" @click="batchSign">签收</a-button>
        </template>
        <!--update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转----------->
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <DeliveryDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
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
      rowSelection: { type: 'checkbox' },
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '发货单', url: getExportUrl },
  });

  //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
  const [registerTable, { reload }, { rowSelection, selectedRowKeys, selectedRows }] = tableContext;

  const allStatus = computed(() => {
    const rows = selectedRows.value as Recordable[];
    if (!rows || !rows.length) return '';
    const s = rows[0].status;
    return rows.every(r => r.status === s) ? s : '';
  });

  function getActions(record: Recordable) {
    const acts: any[] = [];
    if (record.status == '1') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(record) } });
    }
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleDelete(record: Recordable) { await deleteDelivery({ id: record.id }); message.success('删除成功'); reload(); }
  async function batchSubmit() { for (const r of selectedRows.value as Recordable[]) { await submitDelivery({ id: r.id }); } message.success(`已提交${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  async function batchSign() { for (const r of selectedRows.value as Recordable[]) { await signDelivery({ id: r.id }); } message.success(`已签收${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  async function batchCancel() { for (const r of selectedRows.value as Recordable[]) { await cancelDelivery({ id: r.id }); } message.success(`已取消${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
</script>
