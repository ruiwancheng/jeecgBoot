<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-divider>发货明细</a-divider>
    <div style="margin-bottom:8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JSearchSelect :value="record.materialId" @change="(v:any) => updateItem(index, 'materialId', v?.value || v)" :dict="'c_mes_material,name,id'" style="width:100%" />
      </template>
      <template #orderedQty="{ record }">
        <span>{{ record.orderedQty }}</span>
      </template>
      <template #deliveryQty="{ record, index }">
        <InputNumber :value="record.deliveryQty" :min="0.01" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'deliveryQty', v)" />
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
  import { formSchema } from './delivery.data';
  import { saveOrUpdateDelivery, queryDeliveryById } from './delivery.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);

  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 220 },
    { title: '订单数量', dataIndex: 'orderedQty', slots: { customRender: 'orderedQty' }, width: 100 },
    { title: '发货数量', dataIndex: 'deliveryQty', slots: { customRender: 'deliveryQty' }, width: 120 },
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
    items.value = [{ deliveryQty: 1 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    if (unref(isUpdate) && data.record) {
      try {
        const delivery = await queryDeliveryById({ id: data.record.id });
        if (delivery) {
          await setFieldsValue(delivery);
          items.value = delivery.items?.length ? delivery.items : [{ deliveryQty: 1 }];
        }
      } catch (e) { /* fallback */ }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑发货单' : '新增发货单'));

  function addLine() { items.value.push({ deliveryQty: 1 }); }
  function removeLine(index: number) { if (items.value.length > 1) items.value.splice(index, 1); }
  function updateItem(index: number, field: string, value: any) { items.value[index] = { ...items.value[index], [field]: value }; }

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateDelivery({ ...values, items: items.value }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
