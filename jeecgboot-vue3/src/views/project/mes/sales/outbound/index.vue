<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增出库单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <!--update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转----------->
        <a-divider type="vertical" />
        <a-button type="primary" :disabled="allStatus != '1'" @click="batchAudit">审核</a-button>
        <a-button danger :disabled="allStatus != '1'" @click="batchCancel">取消</a-button>
        <!--update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转----------->
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <OutboundDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive } from 'vue';
  import { BasicTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './outbound.data';
  import { queryOutboundList, deleteOutbound, auditOutbound, cancelOutbound, getExportUrl } from './outbound.api';
  import OutboundDrawer from './OutboundDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesSalesOutbound' });
  const [registerDrawer, { openDrawer }] = useDrawer();

  //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
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
    return selectedRows.every(r => r.status === s) ? s : '';
  });
  //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-outbound',
    tableProps: { title: '销售出库', api: queryOutboundList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '销售出库', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(r: Recordable) {
    const acts: any[] = [];
    if (r.status == '1') {
      acts.push({ label: '编辑', onClick: () => openDrawer(true, { record: r, isUpdate: true }) });
      acts.push({ label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(r) } });
    }
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  async function handleDelete(r: Recordable) { await deleteOutbound({ id: r.id }); message.success('删除成功'); reload(); }
  async function batchAudit() { for (const r of selectedRows) { await auditOutbound({ id: r.id }); } message.success(`已审核${selectedRowKeys.length}条`); selectedRowKeys.length = 0; selectedRows.length = 0; reload(); }
  async function batchCancel() { for (const r of selectedRows) { await cancelOutbound({ id: r.id }); } message.success(`已取消${selectedRowKeys.length}条`); selectedRowKeys.length = 0; selectedRows.length = 0; reload(); }
</script>
