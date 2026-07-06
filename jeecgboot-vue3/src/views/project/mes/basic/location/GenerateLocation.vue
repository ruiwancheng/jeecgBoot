<template>
  <BasicModal v-bind="$attrs" @register="registerModal" title="批量生成库位" width="500px" destroyOnClose @ok="handleSubmit">
    <BasicForm @register="registerForm" />
  </BasicModal>
</template>

<script lang="ts" setup>
  import { ref, unref } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicModal, useModalInner } from '/@/components/Modal';
  import { generateFormSchema } from './location.data';
  import { generateLocations } from './location.api';
  import { message } from 'ant-design-vue';

  const emit = defineEmits(['success', 'register']);
  const warehouseId = ref('');

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: generateFormSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
  });

  const [registerModal, { setModalProps, closeModal }] = useModalInner(async (data) => {
    await resetFields();
    warehouseId.value = data?.warehouseId || '';
    setModalProps({ confirmLoading: false });
  });

  async function handleSubmit() {
    const values = await validate();
    setModalProps({ confirmLoading: true });
    try {
      const codes = await generateLocations({
        warehouseId: unref(warehouseId),
        area: values.area,
        channelRows: values.channelRows,
        channelCols: values.channelCols,
        shelfRows: values.shelfRows,
        shelfCols: values.shelfCols,
      });
      message.success(`成功生成 ${(codes as unknown as string[]).length} 条库位`);
      closeModal();
      emit('success');
    } finally {
      setModalProps({ confirmLoading: false });
    }
  }
</script>
