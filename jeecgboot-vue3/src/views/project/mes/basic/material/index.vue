<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增物料</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <j-upload-button type="primary" preIcon="ant-design:import-outlined" @click="onImportXls">导入</j-upload-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <MaterialDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './material.data';
  import { queryMaterialList, deleteMaterial, deleteBatchMaterial, getExportUrl, getImportUrl, editMaterial } from './material.api';
  import MaterialDrawer from './MaterialDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesBasicMaterial' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls, onImportXls } = useListPage({
    designScope: 'mes-material',
    tableProps: {
      title: '物料管理',
      api: queryMaterialList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
      beforeEditSubmit: async ({ record, key, value }: any) => {
        const params = { ...record, [key]: value };
        delete params.type_dictText;
        delete params.unit_dictText;
        delete params.status_dictText;
        return await editMaterial(params).then(() => message.success(`标准售价已更新`));
      },
    },
    exportConfig: { name: '物料管理', url: getExportUrl },
    importConfig: { url: getImportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    return [
      { label: '编辑', onClick: () => handleEdit(record) },
      {
        label: '删除',
        popConfirm: { title: '确认删除该物料吗？', confirm: () => handleDelete(record) },
      },
    ];
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }

  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }

  async function handleDelete(record: Recordable) {
    await deleteMaterial({ id: record.id });
    message.success('删除成功');
    reload();
  }
</script>
