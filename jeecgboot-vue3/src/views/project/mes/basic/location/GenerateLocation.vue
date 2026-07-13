<template>
  <BasicModal v-bind="$attrs" @register="registerModal" title="批量生成库位" @ok="handleSubmit" width="400px" destroyOnClose>
    <BasicForm @register="registerForm" />
  </BasicModal>
</template>

<script lang="ts" setup>
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicModal, useModalInner } from '/@/components/Modal';
  import { generateFormSchema } from './location.data';
  import { generateLocations } from './location.api';
  import { message } from 'ant-design-vue';

  const emit = defineEmits(['success', 'register']);

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: generateFormSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
  });

  const [registerModal, { setModalProps, closeModal }] = useModalInner(async (data) => {
    await resetFields();
    setModalProps({ confirmLoading: false });
    if (data?.warehouseId) await setFieldsValue({ warehouseId: data.warehouseId });
  });

  async function handleSubmit() {
    const values = await validate();
    setModalProps({ confirmLoading: true });
    try {
      const res: any = await generateLocations(values);
      const codes = res?.result || res?.records || res || [];
      message.success(`成功生成 ${Array.isArray(codes) ? codes.length : 0} 个库位`);
      closeModal();
      emit('success');
    } catch (e: any) { message.error(e?.message || '生成失败'); }
    finally { setModalProps({ confirmLoading: false }); }
  }
</script>
