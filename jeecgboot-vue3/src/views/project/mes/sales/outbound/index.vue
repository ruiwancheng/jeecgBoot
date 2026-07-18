<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增出库单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <!--update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
        <template v-if="selectedRowKeys.length > 0">
          <a-divider type="vertical" />
          <span style="color:#999;margin-right:8px">已选{{ selectedRowKeys.length }}项</span>
          <a-button v-if="allStatus == '1'" type="primary" @click="batchAudit">审核</a-button>
          <a-button v-if="allStatus == '1'" danger @click="batchCancel">取消</a-button>
        </template>
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
  import { computed } from 'vue';
  import { BasicTable } from '/@/components/Table'; import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage'; import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './outbound.data';
  import { queryOutboundList, deleteOutbound, auditOutbound, cancelOutbound, getExportUrl } from './outbound.api';
  import OutboundDrawer from './OutboundDrawer.vue'; import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesSalesOutbound' });
  const [registerDrawer, { openDrawer }] = useDrawer();
  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-outbound',
    tableProps: { title: '销售出库', api: queryOutboundList, columns, rowKey: 'id', rowSelection: null, formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '销售出库', url: getExportUrl },
  });

  //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
  const [registerTable, { reload }, { selectedRowKeys, selectedRows }] = tableContext;

  const allStatus = computed(() => {
    const rows = selectedRows.value as Recordable[];
    if (!rows || !rows.length) return '';
    const s = rows[0].status;
    return rows.every((r: Recordable) => r.status === s) ? s : '';
  });

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
  async function batchAudit() { for (const r of selectedRows.value as Recordable[]) { await auditOutbound({ id: r.id }); } message.success(`已审核${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  async function batchCancel() { for (const r of selectedRows.value as Recordable[]) { await cancelOutbound({ id: r.id }); } message.success(`已取消${selectedRowKeys.value.length}条`); selectedRowKeys.value = []; reload(); }
  //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
</script>
