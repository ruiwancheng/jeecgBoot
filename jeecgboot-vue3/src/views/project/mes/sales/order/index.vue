<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增订单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <!--update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
        <template v-if="selectedRowKeys.length > 0">
          <a-divider type="vertical" />
          <span style="color:#999;margin-right:8px">已选{{ selectedRowKeys.length }}项</span>
          <a-button v-if="allStatus == '1'" type="primary" @click="batchAudit">审核</a-button>
          <a-button v-if="allStatus == '1'" @click="batchClose">关闭</a-button>
          <a-button v-if="allStatus == '1'" danger @click="batchCancel">取消</a-button>
          <a-button v-if="allStatus == '2'" type="primary" @click="batchRelease">下达</a-button>
        </template>
        <!--update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转----------->
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <OrderDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { computed } from 'vue';
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
      rowSelection: { type: 'checkbox' },
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '销售订单', url: getExportUrl },
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
  async function handleDelete(record: Recordable) { await deleteOrder({ id: record.id }); message.success('删除成功'); reload(); }
  async function batchAudit() { for (const r of selectedRows.value as Recordable[]) { await auditOrder({ id: r.id }); } message.success(`已审核${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  async function batchRelease() { for (const r of selectedRows.value as Recordable[]) { await releaseOrder({ id: r.id }); } message.success(`已下达${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  async function batchClose() { for (const r of selectedRows.value as Recordable[]) { await closeOrder({ id: r.id }); } message.success(`已关闭${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  async function batchCancel() { for (const r of selectedRows.value as Recordable[]) { await cancelOrder({ id: r.id }); } message.success(`已取消${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
</script>
