<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增批次</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('batch', record.status)">{{ record.status_dictText || (record.status === '1' ? '在用' : '冻结') }}</a-tag>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <BatchMasterDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './master.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryBatchList, deleteBatch, freezeBatch, unfreezeBatch, getExportUrl } from './master.api';
  import BatchMasterDrawer from './BatchMasterDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesBatchMaster' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-batch-master',
    tableProps: {
      title: '批次主档',
      api: queryBatchList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '批次主档', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    const acts: any[] = [
      { label: '编辑', onClick: () => handleEdit(record) },
      { label: '删除', popConfirm: { title: '确认删除该批次？', confirm: () => handleDelete(record) } },
    ];
    if (record.status === '1') {
      acts.push({ label: '冻结', popConfirm: { title: '确认冻结该批次？', confirm: () => handleFreeze(record) } });
    } else if (record.status === '2') {
      acts.push({ label: '解冻', popConfirm: { title: '确认解冻该批次？', confirm: () => handleUnfreeze(record) } });
    }
    return acts;
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }
  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }
  async function handleDelete(record: Recordable) {
    await deleteBatch({ id: record.id });
    message.success('删除成功');
    reload();
  }
  async function handleFreeze(record: Recordable) {
    await freezeBatch({ id: record.id });
    message.success('已冻结');
    reload();
  }
  async function handleUnfreeze(record: Recordable) {
    await unfreezeBatch({ id: record.id });
    message.success('已解冻');
    reload();
  }
</script>
