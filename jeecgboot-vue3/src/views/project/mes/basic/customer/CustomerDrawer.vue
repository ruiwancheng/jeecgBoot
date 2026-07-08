<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="600px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './customer.data';
  import { saveOrUpdateCustomer } from './customer.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: formSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    if (unref(isUpdate) && data.record) {
      await setFieldsValue({ ...data.record });
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑客户' : '新增客户'));

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateCustomer(values, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
