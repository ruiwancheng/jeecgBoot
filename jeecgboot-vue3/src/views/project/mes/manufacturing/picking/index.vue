<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增领料</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位（阶段颜色）----------->
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('picking', record.status)">{{ record.status_dictText || (record.status === '2' ? '已审核' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <PickingDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { useRouter } from 'vue-router';
  import { BasicTable, _useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './picking.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryPickingList, deletePicking, getExportUrl } from './picking.api';
  import PickingDrawer from './PickingDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesProductionPicking' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { , tableContext, onExportXls } = useListPage({
    designScope: 'mes-manufacturing-picking',
    tableProps: {
      title: '生产领料',
      api: queryPickingList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '生产领料', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    const acts: any[] = [
      { label: '编辑', onClick: () => handleEdit(record) },
      { label: '删除', popConfirm: { title: '确认删除该领料单吗？', confirm: () => handleDelete(record) } },
    ];
    //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】领料→订单跳转（保留）-----------
    // 跨页面跳转：查看本领料单上游的生产订单
    acts.push({ label: '查看订单', onClick: () => router.push({ path: '/project/mes/manufacturing/order', query: { orderId: record.id } }) });
    //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】领料跳转按钮-----------
    return acts;
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }
  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }
  async function handleDelete(record: Recordable) {
    await deletePicking({ id: record.id });
    message.success('删除成功');
    reload();
  }
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】router实例化（跳转按钮使用）-----------
  const router = useRouter();
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】router实例化-----------
</script>
