<template>
  <div>
    <a-button type="primary" size="small" preIcon="ant-design:plus-outlined" @click="handleAdd" style="margin-bottom:8px">新增地址</a-button>
    <BasicTable @register="registerTable">
      <template #action="{ record }">
        <TableAction :actions="[{ label:'编辑', onClick:()=>handleEdit(record) },{ label:'删除', popConfirm:{ title:'确认删除?', confirm:()=>handleDelete(record) } }]" />
      </template>
    </BasicTable>
    <BasicDrawer v-bind="$attrs" @register="registerInnerDrawer" :title="innerTitle" width="600px" destroyOnClose :showFooter="true" @ok="handleInnerSubmit">
      <BasicForm @register="registerInnerForm" />
    </BasicDrawer>
  </div>
</template>
<script lang="ts" setup>
import { ref, computed, unref } from 'vue';
import { BasicTable, useTable, TableAction } from '/@/components/Table';
import { BasicForm, useForm } from '/@/components/Form';
import { BasicDrawer, useDrawer } from '/@/components/Drawer';
import { addressColumns, addressFormSchema } from './address.data';
import { queryAddressList, addAddress, editAddress, deleteAddress } from './customer.api';

const props = defineProps<{ customerId: string }>();
const isUpdate = ref(false);

const [registerInnerForm, { resetFields, setFieldsValue, validate }] = useForm({
  schemas: addressFormSchema,
  showActionButtonGroup: false,
  labelWidth: 100,
});

const [registerInnerDrawer, { openDrawer, closeDrawer }] = useDrawer();
const innerTitle = computed(() => unref(isUpdate) ? '编辑地址' : '新增地址');

const [registerTable, { reload }] = useTable({
  api: queryAddressList,
  columns: addressColumns,
  rowKey: 'id',
  beforeFetch: (params: Recordable) => { params.customerId = props.customerId; return params; },
  showIndexColumn: false,
  showTableSetting: false,
  pagination: { pageSize: 10 },
  immediate: false,
});

function handleAdd() { isUpdate.value = false; resetFields(); openDrawer(true); }
function handleEdit(record: Recordable) { isUpdate.value = true; resetFields(); setFieldsValue({ ...record }); openDrawer(true); }
async function handleDelete(record: Recordable) { await deleteAddress({ id: record.id }); reload(); }
async function handleInnerSubmit() {
  const values = await validate();
  isUpdate.value ? await editAddress(values) : await addAddress({ ...values, customerId: props.customerId });
  closeDrawer();
  reload();
}
defineExpose({ reload });
</script>
