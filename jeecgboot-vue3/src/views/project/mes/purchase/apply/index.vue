<template>
  <div>
    <BasicTable @register="registerTable">
      <template #expandedRowRender="{ record }">
        <ApplyItemsSubTable :applyId="record.id" />
      </template>
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增申请</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <a-button v-if="selectedRowKeys.length > 0" danger preIcon="ant-design:delete-outlined" @click="handleBatchDelete">批量删除 ({{ selectedRowKeys.length }})</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <ApplyDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './apply.data';
  import { queryApplyList, deleteApply, deleteBatchApply, auditApply, getExportUrl } from './apply.api';
  import ApplyDrawer from './ApplyDrawer.vue';
  import ApplyItemsSubTable from './ApplyItemsSubTable.vue';
  import { message, Modal } from 'ant-design-vue';

  defineOptions({ name: 'MesPurchaseApply' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-purchase-apply',
    tableProps: {
      title: '采购申请',
      api: queryApplyList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
      rowSelection: { type: 'checkbox', onChange: (keys: string[]) => { selectedRowKeys.value = keys; } },
    },
    exportConfig: { name: '采购申请', url: getExportUrl },
  });

  const selectedRowKeys = ref<string[]>([]);

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    const acts: any[] = [];
    if (record.status == '1') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '审核', popConfirm: { title: '确认审核该申请吗？', confirm: () => handleAudit(record) } });
      acts.push({ label: '删除', popConfirm: { title: '确认删除该申请吗？', confirm: () => handleDelete(record) } });
    }
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openDrawer(true, { record, isUpdate: true }); }
  async function handleAudit(record: Recordable) { await auditApply({ id: record.id }); message.success('审核成功'); reload(); }
  async function handleDelete(record: Recordable) { await deleteApply({ id: record.id }); message.success('删除成功'); reload(); }
  async function handleBatchDelete() {
    Modal.confirm({
      title: `确认删除选中的 ${selectedRowKeys.value.length} 条申请吗？`,
      content: '删除后无法恢复',
      okText: '确认删除',
      okType: 'danger',
      cancelText: '取消',
      onOk: async () => {
        await deleteBatchApply({ ids: selectedRowKeys.value.join(',') });
        message.success('批量删除成功');
        selectedRowKeys.value = [];
        reload();
      },
    });
  }
</script>
