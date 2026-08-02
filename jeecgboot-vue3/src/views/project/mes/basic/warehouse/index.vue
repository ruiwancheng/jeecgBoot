<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增仓库</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <j-upload-button type="primary" preIcon="ant-design:import-outlined" @click="onImportXls">导入</j-upload-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <WarehouseDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './warehouse.data';
  import { queryWarehouseList, deleteWarehouse, deleteBatchWarehouse, getExportUrl, getImportUrl, deactivateWarehouse, activateWarehouse } from './warehouse.api';
  import WarehouseDrawer from './WarehouseDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesWarehouse' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls, onImportXls } = useListPage({
    designScope: 'mes-warehouse',
    tableProps: {
      title: '仓库管理',
      api: queryWarehouseList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '仓库管理', url: getExportUrl },
    importConfig: { url: getImportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    const actions: any[] = [
      { label: '编辑', onClick: () => handleEdit(record) },
    ];
    if (record.status === 1) {
      actions.push({
        label: '停用',
        popConfirm: { title: '确认停用该仓库吗？', confirm: () => handleDeactivate(record) },
      });
    } else {
      actions.push({
        label: '启用',
        popConfirm: { title: '确认启用该仓库吗？', confirm: () => handleActivate(record) },
      });
    }
    actions.push({
      label: '删除',
      popConfirm: { title: '确认删除该仓库吗？', confirm: () => handleDelete(record) },
    });
    return actions;
  }

  async function handleDeactivate(record: Recordable) {
    await deactivateWarehouse({ id: record.id });
    message.success('停用成功');
    reload();
  }

  async function handleActivate(record: Recordable) {
    await activateWarehouse({ id: record.id });
    message.success('启用成功');
    reload();
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }

  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }

  async function handleDelete(record: Recordable) {
    await deleteWarehouse({ id: record.id });
    message.success('删除成功');
    reload();
  }
</script>
