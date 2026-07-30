<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="800px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert----------->
    <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
    <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert----------->
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './order.data';
  import { saveOrUpdateOrder, queryOrderById } from './order.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert（响应式）-----------
  // 生产订单口径提示：默认文案。状态流转：草稿→已审核→已下达→执行中→已完工/已关闭/已取消。
  const alertText = ref('下达后领料/完工单可引用本订单。状态：草稿 → 已审核 → 已下达 → 执行中 → 已完工。');
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert-----------

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
    // 新增时自动获取编码
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.PRODUCTION_ORDER);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) {
        /* fallback: 手动输入 */
      }
    }
    if (unref(isUpdate) && data.record) {
      await setFieldsValue({ ...data.record });
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑订单' : '新增订单'));

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateOrder(values, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
