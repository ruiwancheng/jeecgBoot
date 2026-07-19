<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增付款</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './payment.data';
  import { queryPaymentList, getExportUrl } from './payment.api';
  import { useRouter } from 'vue-router';

  defineOptions({ name: 'MesPayment' });
  const router = useRouter();
  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-payment',
    tableProps: { title: '付款单', api: queryPaymentList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '付款单', url: getExportUrl },
  });
  const [registerTable] = tableContext;
  function handleAdd() { router.push('/project/mes/finance/payment/add'); }
</script>
