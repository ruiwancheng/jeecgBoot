<template>
  <div :class="prefixCls">
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" @click="handleAdd">新增仓库</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="[
          { label: '编辑', onClick: handleEdit.bind(null, record) },
          { label: '删除', color: 'error', popConfirm: { title: '确认删除?', confirm: handleDelete.bind(null, record) } },
        ]" />
      </template>
    </BasicTable>
    <WarehouseDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>
<script lang="ts" setup name="demo-warehouse">
import { BasicTable, TableAction } from '/@/components/Table';
import { useDrawer } from '/@/components/Drawer';
import { useListPage } from '/@/hooks/system/useListPage';
import WarehouseDrawer from './WarehouseDrawer.vue';
import { list, del } from './warehouse.api';
import { columns, searchFormSchema } from './warehouse.data';
const { prefixCls, tableContext } = useListPage({ designScope: 'demo-warehouse', tableProps: { title: '仓库管理', api: list, columns, formConfig: { schemas: searchFormSchema } } });
const [registerTable, { reload }] = tableContext;
const [registerDrawer, { openDrawer }] = useDrawer();
function handleAdd() { openDrawer(true, { isUpdate: false }); }
function handleEdit(record) { openDrawer(true, { record, isUpdate: true }); }
async function handleDelete(record) { await del({ id: record.id }); reload(); }
</script>
<style lang="less" scoped>@prefixCls: ~'demo-warehouse'; .@{prefixCls} { padding: 8px; }</style>
