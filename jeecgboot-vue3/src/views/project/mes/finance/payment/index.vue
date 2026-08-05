<!--update-begin---author:pi---date:2026-08-04---for:【TKT-001】财务付款页改用 useDrawer（修复 #11 路由 404）----------->
<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增付款</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
    </BasicTable>
    <PaymentDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './payment.data';
  import { queryPaymentList, getExportUrl } from './payment.api';
  import PaymentDrawer from './PaymentDrawer.vue';

  defineOptions({ name: 'MesPayment' });
  const [registerDrawer, { openDrawer }] = useDrawer();
  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-payment',
    tableProps: { title: '付款单', api: queryPaymentList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '付款单', url: getExportUrl },
  });
  const [registerTable, { reload }] = tableContext;
  function handleAdd() { openDrawer(true, { isUpdate: false }); }
</script>
<!--update-end---author:pi---date:2026-08-04---for:【TKT-001】财务付款页改用 useDrawer（修复 #11 路由 404）----------->
