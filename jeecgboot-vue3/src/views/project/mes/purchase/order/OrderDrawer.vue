<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-divider>订单行</a-divider>
    <div style="margin-bottom:8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JSearchSelect :value="record.materialId" @change="(v:any) => updateItem(index, 'materialId', v?.value || v)" :dict="'c_mes_material,name,id'" style="width:100%" />
      </template>
      <template #quantity="{ record, index }">
        <InputNumber :value="record.quantity" :min="0.01" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'quantity', v)" />
      </template>
      <template #unitPrice="{ record, index }">
        <InputNumber :value="record.unitPrice" :min="0" :precision="2" style="width:100%" @change="(v:number) => updateItem(index, 'unitPrice', v)" />
      </template>
      <template #amount="{ record }">
        <span>{{ ((record.quantity || 0) * (record.unitPrice || 0)).toFixed(2) }}</span>
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
  import { JSearchSelect } from '/@/components/Form';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './order.data';
  import { saveOrUpdateOrder, queryOrderById } from './order.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);

  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 200 },
    { title: '数量', dataIndex: 'quantity', slots: { customRender: 'quantity' }, width: 120 },
    { title: '单价', dataIndex: 'unitPrice', slots: { customRender: 'unitPrice' }, width: 120 },
    { title: '金额', slots: { customRender: 'amount' }, width: 100 },
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
    items.value = [{ lineNo: 1, quantity: 1, unitPrice: 0 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    if (unref(isUpdate) && data.record) {
      try {
        const order = await queryOrderById({ id: data.record.id });
        if (order) {
          await setFieldsValue(order);
          items.value = order.items?.length ? order.items : [{ lineNo: 1, quantity: 1, unitPrice: 0 }];
        }
      } catch (e) { /* fallback */ }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑采购订单' : '新增采购订单'));

  function addLine() { items.value.push({ lineNo: items.value.length + 1, quantity: 1, unitPrice: 0 }); }
  function removeLine(index: number) { if (items.value.length > 1) items.value.splice(index, 1); }
  function updateItem(index: number, field: string, value: any) { items.value[index] = { ...items.value[index], [field]: value }; }

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateOrder({ ...values, items: items.value }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
