<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #expandedRowRender="{ record }">
        <ReceiptItemsSubTable :receiptId="record.id" />
      </template>
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增入库</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <!--update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】批量状态流转（Claude评审#7）----------->
        <a-divider type="vertical" />
        <a-button type="primary" :disabled="allStatus != '1'" @click="batchAudit">审核</a-button>
        <!--update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】批量按钮补充----------->
      </template>
      <!--update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】statusTag槽位（阶段颜色）----------->
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('receipt', record.status)">{{ record.status_dictText || (record.status === '2' ? '已入库' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <ReceiptDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive } from 'vue';
  import { useRouter } from 'vue-router';
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './receipt.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryReceiptList, deleteReceipt, getExportUrl, auditReceipt } from './receipt.api';
  import ReceiptDrawer from './ReceiptDrawer.vue';
  import ReceiptItemsSubTable from './ReceiptItemsSubTable.vue';
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

  //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】批量状态流转（rowSelection+allStatus）-----------
  const selectedRowKeys = reactive<string[]>([]);
  const selectedRows = reactive<Recordable[]>([]);
  const rowSelection = {
    type: 'checkbox' as const,
    columnWidth: 50,
    selectedRowKeys,
    onChange(keys: string[], rows: Recordable[]) {
      selectedRowKeys.length = 0;
      selectedRowKeys.push(...keys);
      selectedRows.length = 0;
      selectedRows.push(...rows);
    },
  };
  const allStatus = computed(() => {
    if (!selectedRows.length) return '';
    const s = selectedRows[0].status;
    return selectedRows.every((r) => r.status === s) ? s : '';
  });
  //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】批量状态流转-----------

  function getActions(record: Recordable) {
    const acts: any[] = [];
    if (record.status == '1') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '审核', popConfirm: { title: '确认审核该入库单吗？', confirm: () => handleAudit(record) } });
      acts.push({ label: '删除', popConfirm: { title: '确认删除该入库单吗？', confirm: () => handleDelete(record) } });
    }
    //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】收货→订单跳转（保留）-----------
    // 跨页面跳转：查看本收货单上游的采购订单
    acts.push({ label: '查看订单', onClick: () => router.push({ path: '/project/mes/purchase/order', query: { orderId: record.id } }) });
    //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】收货跳转按钮-----------
    return acts;
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }
  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }
  async function handleDelete(record: Recordable) {
    await deleteReceipt({ id: record.id });
    message.success('删除成功');
    reload();
  }
  async function handleAudit(record: Recordable) {
    await auditReceipt({ id: record.id });
    message.success('审核成功，库存已更新');
    reload();
  }
  //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】router实例化+批量处理函数（Claude评审#7）-----------
  const router = useRouter();
  async function batchAudit() {
    for (const r of selectedRows) {
      await auditReceipt({ id: r.id });
    }
    message.success(`已审核${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】router+批量函数-----------
</script>
