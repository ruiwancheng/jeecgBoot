<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="900px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <!--update-begin---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】模式8口径提示Alert----------->
    <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
    <!--update-end---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】模式8口径提示Alert----------->
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './master.data';
  import { addBatch, editBatch, queryBatchById } from './master.api';
  import { message } from 'ant-design-vue';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  //update-begin---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】模式8口径提示Alert-----------
  // 批次主档口径提示：状态语义。冻结/过期/已耗尽 都会影响库存可用性。
  const alertText = ref('批次创建后由来源单据自动产生。状态：在用 → 冻结 / 过期 / 已耗尽。冻结或过期的批次不能被出库。');
  //update-end---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】模式8口径提示Alert-----------

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
      try {
        const rec = await queryBatchById({ id: data.record.id });
        if (rec) await setFieldsValue(rec);
      } catch (e) {
        /* fallback */
      }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑批次' : '新增批次'));

  async function handleSubmit() {
    const v = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      if (unref(isUpdate)) await editBatch(v, true);
      else await addBatch(v);
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
