<template>
  <div :class="prefixCls">
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" @click="handleAdd">新增库位</a-button>
        <a-button style="margin-left:8px" @click="handleGenerate">生成库位</a-button>
      </template>
      <template #action="{ record }">
        <TableAction :actions="[
          { label: '编辑', onClick: handleEdit.bind(null, record) },
          { label: '删除', color: 'error', popConfirm: { title: '确认删除?', confirm: handleDelete.bind(null, record) } },
        ]" />
      </template>
    </BasicTable>
    <LocationDrawer @register="registerDrawer" @success="reload" />
    <GenerateModal @register="registerGenModal" @success="reload" />
  </div>
</template>
<script lang="ts" setup name="demo-location">
import { BasicTable, TableAction } from '/@/components/Table';
import { useDrawer } from '/@/components/Drawer';
import { useModal } from '/@/components/Modal';
import { useListPage } from '/@/hooks/system/useListPage';
import LocationDrawer from './LocationDrawer.vue';
import GenerateModal from './GenerateLocation.vue';
import { list, del } from './location.api';
import { columns, searchFormSchema } from './location.data';
const { prefixCls, tableContext } = useListPage({ designScope: 'demo-location', tableProps: { title: '库位明细管理', api: list, columns, formConfig: { schemas: searchFormSchema } } });
const [registerTable, { reload }] = tableContext;
const [registerDrawer, { openDrawer }] = useDrawer();
const [registerGenModal, { openModal: openGenModal }] = useModal();
function handleAdd() { openDrawer(true, { isUpdate: false }); }
function handleEdit(record) { openDrawer(true, { record, isUpdate: true }); }
async function handleDelete(record) { await del({ id: record.id }); reload(); }
function handleGenerate() { openGenModal(true); }
</script>
<style lang="less" scoped>@prefixCls: ~'demo-location'; .@{prefixCls} { padding: 8px; }</style>
