<template>
  <div>
    <BasicTable @register="registerTable">
      <template #toolbar>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增规则</a-button>
      </template>
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'action'">
          <TableAction :actions="[{ label: '编辑', onClick: handleEdit.bind(null, record) }, { label: '删除', onClick: handleDelete.bind(null, record) }]" />
        </template>
      </template>
    </BasicTable>
    <CodeRuleModal @register="registerModal" @success="handleSuccess" />
  </div>
</template>

<script lang="ts" setup>
  import { BasicTable, useTable, TableAction } from '/@/components/Table';
  import { useModal } from '/@/components/Modal';
  import { columns, searchFormSchema } from './codeRule.data';
  import { queryCodeRuleList, deleteCodeRule } from './codeRule.api';
  import CodeRuleModal from './CodeRuleModal.vue';

  const [registerModal, { openModal }] = useModal();
  const [registerTable, { reload }] = useTable({
    api: queryCodeRuleList,
    columns,
    searchInfo: {},
    useSearchForm: true,
    formConfig: { schemas: searchFormSchema },
    showTableSetting: true,
    showIndexColumn: false,
    actionColumn: { width: 150, dataIndex: 'action' },
  });

  function handleAdd() { openModal(true, { isUpdate: false }); }
  function handleEdit(record: Recordable) { openModal(true, { isUpdate: true, record }); }
  async function handleDelete(record: Recordable) { await deleteCodeRule({ id: record.id }); reload(); }
  function handleSuccess() { reload(); }
</script>
