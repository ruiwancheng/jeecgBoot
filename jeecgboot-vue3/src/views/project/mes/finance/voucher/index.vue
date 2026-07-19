<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增凭证</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <VoucherDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './voucher.data';
  import { queryVoucherList, deleteVoucher, auditVoucher, getExportUrl } from './voucher.api';
  import VoucherDrawer from './VoucherDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesVoucher' });

  const [registerDrawer, { openDrawer }] = useDrawer();
  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-voucher',
    tableProps: { title: '凭证管理', api: queryVoucherList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '凭证', url: getExportUrl },
  });
  const [registerTable, { reload }] = tableContext;

  function getActions(r: Recordable) {
    const acts: any[] = [];
    if (r.status == '1') {
      acts.push({ label: '编辑', onClick: () => openDrawer(true, { record: r, isUpdate: true }) });
      acts.push({ label: '审核', popConfirm: { title: '确认审核？', confirm: () => handleAudit(r) } });
      acts.push({ label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(r) } });
    }
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  async function handleDelete(r: Recordable) { await deleteVoucher({ id: r.id }); message.success('删除成功'); reload(); }
  async function handleAudit(r: Recordable) { await auditVoucher({ id: r.id }); message.success('审核成功'); reload(); }
</script>
