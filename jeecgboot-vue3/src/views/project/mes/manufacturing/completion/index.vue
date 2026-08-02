<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增入库</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位（阶段颜色）----------->
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('completion', record.status)">{{ record.status_dictText || (record.status === '2' ? '已入库' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <CompletionReceiptDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { useRouter } from 'vue-router';
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './completion.data';
  import { getStatusColor } from '../shared/statusColor';
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
    const acts: any[] = [
      { label: '编辑', onClick: () => handleEdit(record) },
      { label: '删除', popConfirm: { title: '确认删除该入库单吗？', confirm: () => handleDelete(record) } },
    ];
    //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】完工→订单跳转（保留）-----------
    // 跨页面跳转：查看本完工入库单上游的生产订单
    acts.push({ label: '查看订单', onClick: () => router.push({ path: '/project/mes/manufacturing/order', query: { orderId: record.id } }) });
    //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】完工跳转按钮-----------
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleDelete(record: Recordable) { await deleteCompletion({ id: record.id }); message.success('删除成功'); reload(); }
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】router实例化（跳转按钮使用）-----------
  const router = useRouter();
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】router实例化-----------
</script>
