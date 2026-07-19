<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增科目</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <a-button @click="loadTree">树形视图</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <SubjectDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './subject.data';
  import { querySubjectList, deleteSubject, getExportUrl } from './subject.api';
  import SubjectDrawer from './SubjectDrawer.vue';
  import { message } from 'ant-design-vue';
  import { useRouter } from 'vue-router';

  defineOptions({ name: 'MesAccountSubject' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { tableContext, onExportXls } = useListPage({
    designScope: 'mes-subject',
    tableProps: {
      title: '会计科目',
      api: querySubjectList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '会计科目', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    return [
      { label: '编辑', onClick: () => openDrawer(true, { record, isUpdate: true }) },
      { label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(record) } },
    ];
  }

  function handleAdd() { openDrawer(true, { isUpdate: false }); }
  async function handleDelete(record: Recordable) { await deleteSubject({ id: record.id }); message.success('删除成功'); reload(); }
  function loadTree() { reload(); }
</script>
