<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="isUpdate ? '编辑科目' : '新增科目'" width="500px" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { formSchema } from './subject.data';
  import { saveOrUpdateSubject } from './subject.api';
  import { message } from 'ant-design-vue';

  const [registerForm, { validate, setFieldsValue }] = useForm({ schemas: formSchema, labelWidth: 100, showActionButtonGroup: false });
  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    setFieldsValue(data.record || { status: '1', level: 1, isLeaf: 1 });
    isUpdate.value = !!data.isUpdate;
  });
  const isUpdate = ref(false);

  async function handleSubmit() {
    const values = await validate();
    await saveOrUpdateSubject(values, isUpdate.value);
    message.success(isUpdate.value ? '编辑成功' : '新增成功');
    closeDrawer();
  }
</script>
