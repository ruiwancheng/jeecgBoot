<template>
  <div>
    <a-button type="primary" size="small" preIcon="ant-design:plus-outlined" @click="handleAdd" style="margin-bottom:8px">新增价格</a-button>
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
import { priceColumns, priceFormSchema } from './price.data';
import { queryPriceList, addPrice, editPrice, deletePrice } from './customer.api';

const props = defineProps<{ customerId: string }>();
const isUpdate = ref(false);

const [registerInnerForm, { resetFields, setFieldsValue, validate }] = useForm({
  schemas: priceFormSchema,
  showActionButtonGroup: false,
  labelWidth: 100,
});

const [registerInnerDrawer, { openDrawer, closeDrawer }] = useDrawer();
const innerTitle = computed(() => unref(isUpdate) ? '编辑价格' : '新增价格');

const [registerTable, { reload }] = useTable({
  api: queryPriceList,
  columns: priceColumns,
  rowKey: 'id',
  beforeFetch: (params: Recordable) => { params.customerId = props.customerId; return params; },
  showIndexColumn: false,
  showTableSetting: false,
  pagination: { pageSize: 10 },
  immediate: false,
});

function handleAdd() { isUpdate.value = false; resetFields(); openDrawer(true); }
function handleEdit(record: Recordable) { isUpdate.value = true; resetFields(); setFieldsValue({ ...record }); openDrawer(true); }
async function handleDelete(record: Recordable) { await deletePrice({ id: record.id }); reload(); }
async function handleInnerSubmit() {
  const values = await validate();
  isUpdate.value ? await editPrice(values) : await addPrice({ ...values, customerId: props.customerId });
  closeDrawer();
  reload();
}
defineExpose({ reload });
</script>
