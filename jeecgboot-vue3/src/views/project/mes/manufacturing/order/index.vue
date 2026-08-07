<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增订单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位（阶段颜色）----------->
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('order', record.status)">{{ record.status_dictText || (record.status === '5' ? '已完工' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <OrderDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { useRouter } from 'vue-router';
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './order.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryOrderList, deleteOrder, auditOrder, releaseOrder, completeOrder, closeOrder, cancelOrder, generatePicking, getExportUrl } from './order.api';
  import OrderDrawer from './OrderDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesProductionOrder' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-manufacturing-order',
    tableProps: {
      title: '生产订单',
      api: queryOrderList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '生产订单', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    const acts: any[] = [];
    //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】订单状态机按钮（按 status 显隐）-----------
    // 状态机：1草稿 2已审核 3已下达 4执行中 5已完工 6已关闭 7已取消
    if (record.status === '1') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '删除', popConfirm: { title: '确认删除该订单吗？', confirm: () => handleDelete(record) } });
      acts.push({ label: '审核', popConfirm: { title: '确认审核该订单？', confirm: () => handleAudit(record) } });
    }
    if (record.status === '2') {
      acts.push({ label: '下达', popConfirm: { title: '确认下达该订单？下达后将生成领料单。', confirm: () => handleRelease(record) } });
    }
    if (record.status === '3' || record.status === '4') {
      acts.push({ label: '完工', popConfirm: { title: '确认完工该订单？', confirm: () => handleComplete(record) } });
    }
    if (record.status === '3' || record.status === '4') {
      acts.push({ label: '补领', popConfirm: { title: '确认为该订单生成补领单？', confirm: () => handleGeneratePicking(record) } });
    }
    if (record.status === '2' || record.status === '3' || record.status === '4') {
      acts.push({ label: '关闭', popConfirm: { title: '确认关闭该订单？', confirm: () => handleClose(record) } });
    }
    if (record.status === '1' || record.status === '2' || record.status === '3' || record.status === '4') {
      acts.push({ label: '取消', popConfirm: { title: '确认取消该订单？', confirm: () => handleCancel(record) } });
    }
    //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】订单状态机按钮-----------
    //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】订单→领料/完工跳转（保留）-----------
    // 跨页面跳转：查看本订单下游的领料单/完工入库单
    acts.push({
      label: '查看领料',
      onClick: () => router.push({ path: '/project/mes/manufacturing/picking', query: { productionOrderId: record.id } }),
    });
    acts.push({
      label: '查看完工',
      onClick: () => router.push({ path: '/project/mes/manufacturing/completion', query: { productionOrderId: record.id } }),
    });
    //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】订单跳转按钮-----------
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
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】订单状态机处理器-----------
  async function handleAudit(record: Recordable) {
    await auditOrder({ id: record.id });
    message.success('已审核');
    reload();
  }
  async function handleRelease(record: Recordable) {
    await releaseOrder({ id: record.id });
    message.success('已下达，领料单已生成');
    reload();
  }
  async function handleComplete(record: Recordable) {
    await completeOrder({ id: record.id });
    message.success('已完工');
    reload();
  }
  async function handleClose(record: Recordable) {
    await closeOrder({ id: record.id });
    message.success('已关闭');
    reload();
  }
  async function handleCancel(record: Recordable) {
    await cancelOrder({ id: record.id });
    message.success('已取消');
    reload();
  }
  async function handleGeneratePicking(record: Recordable) {
    await generatePicking({ orderId: record.id });
    message.success('补领单已生成');
    reload();
  }
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】订单状态机处理器-----------
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】router实例化（跳转按钮使用）-----------
  const router = useRouter();
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】router实例化-----------
</script>
