<template>
  <BasicModal v-bind="$attrs" @register="registerModal" :title="getTitle" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
  </BasicModal>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { BasicModal, useModalInner } from '/@/components/Modal';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { formSchema } from './codeRule.data';
  import { addCodeRule, editCodeRule } from './codeRule.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: formSchema, showActionButtonGroup: false, labelWidth: 100,
    actionColOptions: { span: 24 },
  });

  const [registerModal, { setModalProps, closeModal }] = useModalInner(async (data) => {
    await resetFields();
    isUpdate.value = !!data?.isUpdate;
    setModalProps({ confirmLoading: false });
    if (unref(isUpdate) && data.record) {
      await setFieldsValue(data.record);
    }
  });

  const getTitle = computed(() => unref(isUpdate) ? '编辑编码规则' : '新增编码规则');

  async function handleSubmit() {
    const values = await validate();
    setModalProps({ confirmLoading: true });
    try {
      unref(isUpdate) ? await editCodeRule(values) : await addCodeRule(values);
      closeModal();
      emit('success');
    } finally {
      setModalProps({ confirmLoading: false });
    }
  }
</script>
