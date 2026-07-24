<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <span>库存总览</span>
      </template>
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './inventory.data';
  import { queryInventoryList } from './inventory.api';

  defineOptions({ name: 'MesInventoryOverview' });

  const { tableContext } = useListPage({
    designScope: 'mes-inventory',
    tableProps: {
      title: '库存总览',
      api: queryInventoryList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
      pagination: { pageSize: 20 },
    },
  });

  const [registerTable] = tableContext;
</script>
