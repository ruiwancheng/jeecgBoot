<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-divider>入库行</a-divider>
    <div style="margin-bottom:8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect v-model:modelValue="record.materialId" @change="(v:any) => updateItem(index, 'materialId', v?.value ?? v)" style="width:100%" />
      </template>
      <template #planQty="{ record, index }">
        <InputNumber :value="record.planQty" :min="0" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'planQty', v)" />
      </template>
      <template #receiptQty="{ record, index }">
        <InputNumber :value="record.receiptQty" :min="0.01" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'receiptQty', v)" />
      </template>
      <template #action="{ index }">
        <a-button type="link" danger @click="removeLine(index)">删除</a-button>
      </template>
    </a-table>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { InputNumber, Divider } from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './completion.data';
  import { saveOrUpdateCompletion, queryCompletionById } from './completion.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);

  const itemColumns = [
    { title: '产品物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 200 },
    { title: '计划数量', dataIndex: 'planQty', slots: { customRender: 'planQty' }, width: 120 },
    { title: '入库数量', dataIndex: 'receiptQty', slots: { customRender: 'receiptQty' }, width: 120 },
    { title: '操作', slots: { customRender: 'action' }, width: 80 },
  ];

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: formSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
    actionColOptions: { span: 24 },
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    items.value = [{ lineNo: 1, planQty: 0, receiptQty: 1 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    if (unref(isUpdate) && data.record) {
      try {
        const completion = await queryCompletionById({ id: data.record.id });
        if (completion) {
          await setFieldsValue(completion);
          items.value = completion.items?.length ? completion.items : [{ lineNo: 1, planQty: 0, receiptQty: 1 }];
        }
      } catch (e) { /* fallback */ }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑入库' : '新增入库'));

  function addLine() { items.value.push({ lineNo: items.value.length + 1, planQty: 0, receiptQty: 1 }); }
  function removeLine(index: number) { if (items.value.length > 1) items.value.splice(index, 1); }
  function updateItem(index: number, field: string, value: any) { items.value[index] = { ...items.value[index], [field]: value }; }

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateCompletion({ ...values, items: items.value }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
