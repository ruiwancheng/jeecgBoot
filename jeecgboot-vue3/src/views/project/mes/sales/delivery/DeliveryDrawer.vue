<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <!--update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】模式8口径提示Alert----------->
    <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
    <!--update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】模式8口径提示Alert----------->
    <a-divider>发货明细</a-divider>
    <div style="margin-bottom: 8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect
          v-model:modelValue="record.materialId"
          @change="(v: any) => updateItem(index, 'materialId', v?.value ?? v)"
          style="width: 100%"
        />
      </template>
      <template #orderedQty="{ record }">
        <span>{{ record.orderedQty }}</span>
      </template>
      <template #deliveryQty="{ record, index }">
        <InputNumber
          :value="record.deliveryQty"
          :min="0.01"
          :step="1"
          style="width: 100%"
          @change="(v: number) => updateItem(index, 'deliveryQty', v)"
        />
      </template>
      <template #action="{ index }">
        <a-button type="link" danger @click="removeLine(index)">删除</a-button>
      </template>
    </a-table>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { InputNumber, _Divider } from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './delivery.data';
  import { saveOrUpdateDelivery, queryDeliveryById } from './delivery.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any>([]);
  //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】模式8口径提示Alert（响应式）-----------
  // 发货单口径提示：默认文案。编辑时根据 queryById 返回的 _dictText 动态更新
  const alertText = ref('由销售订单创建。出库后订单自动置已发货。');
  //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】模式8口径提示Alert-----------

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
    // 新增时自动获取编码
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.DELIVERY_NOTE);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) {
        /* fallback: 手动输入 */
      }
    }
    if (unref(isUpdate) && data.record) {
      try {
        const delivery = await queryDeliveryById({ id: data.record.id });
        if (delivery) {
          await setFieldsValue(delivery);
          items.value = delivery.items?.length ? delivery.items : [{ deliveryQty: 1 }];
          //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】Alert文案响应式赋值（_dictText）-----------
          // 动态更新 Alert 文案：list 接口返回 salesOrderId_dictText，queryById 不返回（仅 ID）。
          // 这里用 dictText 或 ID 充底两者取其一
          const orderRef = delivery.salesOrderId_dictText || delivery.salesOrderId;
          if (orderRef) {
            alertText.value = `由订单 ${orderRef} 创建。出库后订单自动置已发货。`;
          }
          //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】Alert文案响应式赋值-----------
        }
      } catch (e) {
        /* fallback */
      }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑发货单' : '新增发货单'));

  function addLine() {
    items.value.push({ deliveryQty: 1 });
  }
  function removeLine(index: number) {
    if (items.value.length > 1) items.value.splice(index, 1);
  }
  function updateItem(index: number, field: string, value: any) {
    items.value[index] = { ...items.value[index], [field]: value };
  }

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
