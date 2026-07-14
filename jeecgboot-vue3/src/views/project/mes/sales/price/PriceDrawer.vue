<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="700px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
import { ref, computed, unref } from 'vue';
import { BasicForm, useForm } from '/@/components/Form/index';
import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
import { formSchema } from './price.data';
import { saveOrUpdatePrice, queryPriceById } from './price.api';

const emit = defineEmits(['success', 'register']);
const isUpdate = ref(false);

const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
  schemas: formSchema,
  showActionButtonGroup: false,
  labelWidth: 100,
  actionColOptions: { span: 24 },
});

const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
  await resetFields();
  isUpdate.value = !!data?.isUpdate;
  setDrawerProps({ confirmLoading: false });
  if (unref(isUpdate) && data.record) {
    const res = await queryPriceById({ id: data.record.id });
    if (res) await setFieldsValue({ ...res });
  }
});

const getTitle = computed(() => (unref(isUpdate) ? '编辑价格' : '新增价格'));

async function handleSubmit() {
  const values = await validate();
  setDrawerProps({ confirmLoading: true });
  try {
    await saveOrUpdatePrice(values, unref(isUpdate));
    closeDrawer();
    emit('success');
  } finally {
    setDrawerProps({ confirmLoading: false });
  }
}
</script>
