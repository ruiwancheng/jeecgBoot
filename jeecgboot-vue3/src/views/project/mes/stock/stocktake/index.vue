<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #expandedRowRender="{ record }">
        <StocktakeItemsSubTable :docId="record.id" />
      </template>
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增盘点单</a-button>
        <a-divider type="vertical" />
        <a-button type="primary" :disabled="allStatus != '1'" @click="batchAudit">批量审核</a-button>
      </template>
      <template #statusTag="{ record }">
        <a-tag :color="record.status === '2' ? 'green' : 'orange'">{{ record.status_dictText || (record.status === '2' ? '已审核' : '草稿') }}</a-tag>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <StocktakeDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { computed, reactive } from 'vue';
  import { columns, searchFormSchema } from './stocktake.data';
  import { queryStocktakeList, deleteStocktake, auditStocktake } from './stocktake.api';
  import StocktakeDrawer from './StocktakeDrawer.vue';
  import StocktakeItemsSubTable from './StocktakeItemsSubTable.vue';
  import { message, Modal } from 'ant-design-vue';

  defineOptions({ name: 'MesStocktake' });
  const [registerDrawer, { openDrawer }] = useDrawer();

  // 模式 2：复选框 + 批量审核状态守卫
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
    return selectedRows.every((r) => r.status === s) ? s : '';
  });

  const { tableContext } = useListPage({
    designScope: 'mes-stocktake',
    tableProps: { title: '盘点单', api: queryStocktakeList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(r: Recordable) {
    const acts: any[] = [];
    if (r.status == '1') {
      acts.push({ label: '录入实盘', onClick: () => openDrawer(true, { record: r, isUpdate: true }) });
      acts.push({ label: '审核', popConfirm: { title: '差异以账面快照时点为准，审核后将自动生成盘盈/盘亏调整单并生效库存。确认审核？', confirm: () => handleAudit(r) } });
      acts.push({ label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(r) } });
    }
    return acts;
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  async function batchAudit() {
    for (const r of selectedRows) { await auditStocktake({ id: r.id }); }
    message.success(`已审核${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  async function handleDelete(r: Recordable) { await deleteStocktake({ id: r.id }); message.success('删除成功'); reload(); }
  async function handleAudit(r: Recordable) {
    const res: any = await auditStocktake({ id: r.id });
    Modal.success({ title: '盘点审核完成', content: res || '审核成功' });
    reload();
  }
</script>
