<template>
  <BasicDrawer v-bind="$attrs" @register="registerModal" :title="isUpdate ? '编辑仓库' : '新增仓库'" :width="500" :showFooter="true" destroyOnClose @ok="handleOk">
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>
<script lang="ts" setup>
import { ref, unref } from 'vue';
import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
import { BasicForm, useForm } from '/@/components/Form';
import { formSchema } from './warehouse.data';
import { add, edit } from './warehouse.api';
const emit = defineEmits(['success', 'register']);
const isUpdate = ref(false);
let recordId = '';
const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({ labelWidth: 100, schemas: formSchema, showActionButtonGroup: false });
const [registerModal, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
  await resetFields();
  setDrawerProps({ confirmLoading: false, showFooter: true });
  isUpdate.value = !!data?.isUpdate;
  if (unref(isUpdate) && data.record) { recordId = data.record.id; await setFieldsValue({ ...data.record }); }
});
async function handleOk() {
  try { const v = await validate(); setDrawerProps({ confirmLoading: true }); unref(isUpdate) ? await edit({ ...v, id: recordId }) : await add(v); closeDrawer(); emit('success'); }
  finally { setDrawerProps({ confirmLoading: false }); }
}
</script>
