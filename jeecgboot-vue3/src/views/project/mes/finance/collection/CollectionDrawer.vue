<!--update-begin---author:pi---date:2026-08-04---for:【TKT-001】财务收款单 Drawer（修复 #9）----------->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" title="新增收款单" width="600px" :showFooter="true" destroyOnClose @ok="handleSubmit">
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { message } from 'ant-design-vue';
  import { formSchema } from './collection.data';
  import { addCollection } from './collection.api';

  const emit = defineEmits(['success', 'register']);

  const [registerForm, { resetFields, validate, setFieldsValue }] = useForm({
    schemas: formSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async () => {
    await resetFields();
    // 默认收款日期 = 今天 + 默认状态 = 1
    await setFieldsValue({ status: '1', collectionDate: new Date().toISOString().slice(0, 10) });
    setDrawerProps({ confirmLoading: false });
  });

  async function handleSubmit() {
    const v = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await addCollection(v);
      message.success('收款成功，应收已更新');
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
<!--update-end---author:pi---date:2026-08-04---for:【TKT-001】财务收款单 Drawer（修复 #9）----------->