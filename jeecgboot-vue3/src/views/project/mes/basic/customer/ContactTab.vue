<template>
  <div>
    <a-button type="primary" size="small" preIcon="ant-design:plus-outlined" @click="handleAdd" style="margin-bottom:8px">新增联系人</a-button>
    <BasicTable @register="registerTable">
      <template #action="{ record }">
        <TableAction :actions="[{ label:'编辑', onClick:()=>handleEdit(record) },{ label:'删除', popConfirm:{ title:'确认删除?', confirm:()=>handleDelete(record) } }]" />
      </template>
    </BasicTable>
    <BasicDrawer v-bind="$attrs" @register="registerInnerDrawer" :title="innerTitle" width="500px" destroyOnClose :showFooter="true" @ok="handleInnerSubmit">
      <BasicForm @register="registerInnerForm" />
    </BasicDrawer>
  </div>
</template>
<script lang="ts" setup>
import { ref, computed, unref } from 'vue';
import { BasicTable, useTable, TableAction } from '/@/components/Table';
import { BasicForm, useForm } from '/@/components/Form';
import { BasicDrawer, useDrawer } from '/@/components/Drawer';
import { contactColumns, contactFormSchema } from './contact.data';
import { queryContactList, addContact, editContact, deleteContact } from './customer.api';

const props = defineProps<{ customerId: string }>();
const isUpdate = ref(false);

const [registerInnerForm, { resetFields, setFieldsValue, validate }] = useForm({
  schemas: contactFormSchema,
  showActionButtonGroup: false,
  labelWidth: 100,
});

const [registerInnerDrawer, { openDrawer, closeDrawer }] = useDrawer();
const innerTitle = computed(() => unref(isUpdate) ? '编辑联系人' : '新增联系人');

const [registerTable, { reload }] = useTable({
  api: queryContactList,
  columns: contactColumns,
  rowKey: 'id',
  beforeFetch: (params: Recordable) => { params.customerId = props.customerId; return params; },
  showIndexColumn: false,
  showTableSetting: false,
  pagination: { pageSize: 10 },
  immediate: true,
});

function handleAdd() { isUpdate.value = false; resetFields(); openDrawer(true); }
function handleEdit(record: Recordable) { isUpdate.value = true; resetFields(); setFieldsValue({ ...record }); openDrawer(true); }
async function handleDelete(record: Recordable) { await deleteContact({ id: record.id }); reload(); }
async function handleInnerSubmit() {
  const values = await validate();
  isUpdate.value ? await editContact(values) : await addContact({ ...values, customerId: props.customerId });
  closeDrawer();
  reload();
}
defineExpose({ reload });
</script>
