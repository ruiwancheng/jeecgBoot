<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #expandedRowRender="{ record }">
        <OtherInItemsSubTable :docId="record.id" />
      </template>
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增入库单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <a-divider type="vertical" />
        <!-- 批量审核/反审核（状态守卫：全选同状态才可用） -->
        <a-button type="primary" :disabled="allStatus != '1'" @click="batchAudit">审核</a-button>
        <a-button danger :disabled="allStatus != '2'" @click="batchUnaudit">反审核</a-button>
      </template>
      <!--update-begin---author:ruiwancheng---date:20260730---for:【MES其它出入库】黄金模板对齐-加statusTag槽位---------->
      <template #statusTag="{ record }">
        <a-tag :color="record.status === '2' ? 'green' : 'orange'">{{ record.status_dictText || (record.status === '2' ? '已审核' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260730---for:【MES其它出入库】黄金模板对齐-加statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <OtherInDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive } from 'vue';
  import { BasicTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './otherIn.data';
  import { queryOtherInList, deleteOtherIn, auditOtherIn, unauditOtherIn, getExportUrl } from './otherIn.api';
  import OtherInDrawer from './OtherInDrawer.vue';
  import OtherInItemsSubTable from './OtherInItemsSubTable.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesOtherStockIn' });
  const [registerDrawer, { openDrawer }] = useDrawer();

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

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-other-stock-in',
    tableProps: { title: '其它入库', api: queryOtherInList, columns, rowKey: 'id', formConfig: { labelWidth: 120, schemas: searchFormSchema } },
    exportConfig: { name: '其它入库', url: getExportUrl },
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

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }
  async function handleDelete(r: Recordable) {
    await deleteOtherIn({ id: r.id });
    message.success('删除成功');
    reload();
  }
  async function batchAudit() {
    for (const r of selectedRows) {
      await auditOtherIn({ id: r.id });
    }
    message.success(`已审核${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  async function batchUnaudit() {
    for (const r of selectedRows) {
      await unauditOtherIn({ id: r.id });
    }
    message.success(`已反审核${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
</script>
