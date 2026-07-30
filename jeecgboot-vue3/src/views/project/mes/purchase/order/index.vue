<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #expandedRowRender="{ record }">
        <OrderItemsSubTable :orderId="record.id" />
      </template>
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增订单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <!--update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】批量状态流转（Claude评审#6）----------->
        <a-divider type="vertical" />
        <a-button type="primary" :disabled="allStatus != '1'" @click="batchAudit">审核</a-button>
        <a-button :disabled="allStatus != '3'" @click="batchUnaudit">反审核</a-button>
        <!--update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】批量按钮补充----------->
      </template>
      <!--update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】statusTag槽位（阶段颜色）----------->
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('order', record.status)">{{ record.status_dictText || (record.status === '5' ? '已到货' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <OrderDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive } from 'vue';
  import { useRouter } from 'vue-router';
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './order.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryOrderList, deleteOrder, auditOrder, unauditOrder, getExportUrl } from './order.api';
  import OrderDrawer from './OrderDrawer.vue';
  import OrderItemsSubTable from './OrderItemsSubTable.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesPurchaseOrder' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-purchase-order',
    tableProps: {
      title: '采购订单',
      api: queryOrderList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '采购订单', url: getExportUrl },
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
      acts.push({ label: '审核', popConfirm: { title: '确认审核该订单吗？', confirm: () => handleAudit(record) } });
      acts.push({ label: '删除', popConfirm: { title: '确认删除该订单吗？', confirm: () => handleDelete(record) } });
    }
    //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】订单→收货跳转（保留）-----------
    // 跨页面跳转：查看本订单下游的采购收货单
    acts.push({ label: '查看收货', onClick: () => router.push({ path: '/project/mes/purchase/receipt', query: { orderId: record.id } }) });
    //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】订单跳转按钮-----------
    return acts;
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }
  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }
  async function handleDelete(record: Recordable) {
    await deleteOrder({ id: record.id });
    message.success('删除成功');
    reload();
  }
  async function handleAudit(record: Recordable) {
    await auditOrder({ id: record.id });
    message.success('审核成功');
    reload();
  }
  //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】router实例化+批量处理函数（Claude评审#6）-----------
  const router = useRouter();
  async function batchAudit() {
    for (const r of selectedRows) {
      await auditOrder({ id: r.id });
    }
    message.success(`已审核${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  async function batchUnaudit() {
    for (const r of selectedRows) {
      await unauditOrder({ id: r.id });
    }
    message.success(`已反审核${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】router+批量函数-----------
</script>
