<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="isUpdate ? '编辑发票' : '新增发票'" width="600px" :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>
<script lang="ts" setup>
  import { ref } from 'vue'; import { BasicDrawer, useDrawerInner } from '/@/components/Drawer'; import { BasicForm, useForm } from '/@/components/Form/index';
  import { formSchema } from './invoice.data'; import { saveOrUpdateInvoice } from './invoice.api'; import { message } from 'ant-design-vue';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api'; import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';
  const [registerForm, { validate, setFieldsValue }] = useForm({ schemas: formSchema, labelWidth: 100, showActionButtonGroup: false });
  const isUpdate = ref(false);
  const [registerDrawer, { closeDrawer }] = useDrawerInner(async (data) => {
    setFieldsValue(data.record || { invoiceType: '1', taxRate: 0.13 }); isUpdate.value = !!data.isUpdate;
    if (!isUpdate.value) { try { const nextCode = await getNextCode(MES_BIZ_CODE.SALES_INVOICE); if (nextCode) await setFieldsValue({ code: nextCode }); } catch (e) { /* fallback: 手动输入 */ } }
  });
  async function handleSubmit() { const v = await validate(); await saveOrUpdateInvoice(v, isUpdate.value); message.success(isUpdate.value ? '编辑成功' : '新增成功'); closeDrawer(); }
</script>
