<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增出库单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <OutboundDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable } from '/@/components/Table'; import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage'; import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './outbound.data';
  import { queryOutboundList, deleteOutbound, auditOutbound, cancelOutbound, getExportUrl } from './outbound.api';
  import OutboundDrawer from './OutboundDrawer.vue'; import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesSalesOutbound' });
  const [registerDrawer, { openDrawer }] = useDrawer();
  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-outbound',
    tableProps: { title: '销售出库', api: queryOutboundList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '销售出库', url: getExportUrl },
  });
  const [registerTable, { reload }] = tableContext;

  function getActions(r: Recordable) {
    const acts: any[] = [{ label: '编辑', onClick: () => openDrawer(true, { record: r, isUpdate: true }) }];
    if (r.status == '1') { acts.push({ label: '审核', popConfirm: { title: '确认审核？', confirm: () => handleAudit(r) } }); }
    if (r.status != '3') { acts.push({ label: '取消', popConfirm: { title: '确认取消？', confirm: () => handleCancel(r) } }); }
    acts.push({ label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(r) } });
    return acts;
  }
  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  async function handleAudit(r: Recordable) { await auditOutbound({ id: r.id }); message.success('审核成功'); reload(); }
  async function handleCancel(r: Recordable) { await cancelOutbound({ id: r.id }); message.success('已取消'); reload(); }
  async function handleDelete(r: Recordable) { await deleteOutbound({ id: r.id }); message.success('删除成功'); reload(); }
</script>
