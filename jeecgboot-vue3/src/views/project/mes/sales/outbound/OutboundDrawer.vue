<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <!--update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】模式8口径提示Alert----------->
    <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
    <!--update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】模式8口径提示Alert----------->
    <a-divider>出库明细</a-divider>
    <div style="margin-bottom: 8px"><a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button></div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect
          v-model:modelValue="record.materialId"
          @change="(v: any) => updateItem(index, 'materialId', v?.value ?? v)"
          style="width: 100%"
        />
      </template>
      <template #deliveryQty="{ record }"
        ><span>{{ record.deliveryQty }}</span></template
      >
      <template #actualQty="{ record, index }">
        <InputNumber :value="record.actualQty" :min="0.01" :step="1" style="width: 100%" @change="(v: number) => updateItem(index, 'actualQty', v)" />
      </template>
      <template #batch="{ record, index }">
        <Input :value="record.batch" style="width: 100%" @change="(e: any) => updateItem(index, 'batch', e.target.value)" />
      </template>
      <template #location="{ record, index }">
        <Input :value="record.location" style="width: 100%" @change="(e: any) => updateItem(index, 'location', e.target.value)" />
      </template>
      <template #action="{ index }"><a-button type="link" danger @click="removeLine(index)">删除</a-button></template>
    </a-table>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { Input, InputNumber, Divider } from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './outbound.data';
  import { saveOrUpdateOutbound, queryOutboundById } from './outbound.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);
  //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】模式8口径提示Alert（响应式）-----------
  // 销售出库口径提示：默认文案。编辑时根据 queryById 返回的 _dictText 动态更新
  const alertText = ref('由发货单创建。审核后扣减库存、自动生成应收单。');
  //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】模式8口径提示Alert-----------
  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 200 },
    { title: '发货数量', dataIndex: 'deliveryQty', slots: { customRender: 'deliveryQty' }, width: 100 },
    { title: '实出数量', dataIndex: 'actualQty', slots: { customRender: 'actualQty' }, width: 120 },
    { title: '批次', slots: { customRender: 'batch' }, width: 100 },
    { title: '库位', slots: { customRender: 'location' }, width: 100 },
    { title: '操作', slots: { customRender: 'action' }, width: 80 },
  ];

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({ schemas: formSchema, showActionButtonGroup: false, labelWidth: 100 });
  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    items.value = [{ actualQty: 1 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    // 新增时自动获取编码
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.SALES_OUTBOUND);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) {
        /* fallback: 手动输入 */
      }
    }
    if (unref(isUpdate) && data.record) {
      try {
        const o = await queryOutboundById({ id: data.record.id });
        if (o) {
          await setFieldsValue(o);
          items.value = o.items?.length ? o.items : [{ actualQty: 1 }];
          //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】Alert文案响应式赋值（_dictText）-----------
          // 动态更新 Alert 文案：list 接口返回 deliveryNoteId_dictText，queryById 不返回（仅 ID）。
          const dnRef = o.deliveryNoteId_dictText || o.deliveryNoteId;
          if (dnRef) {
            alertText.value = `由发货单 ${dnRef} 出库。审核后扣减库存、自动生成应收单。`;
          }
          //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】Alert文案响应式赋值-----------
        }
      } catch (e) {
        /* fallback */
      }
    }
  });
  const getTitle = computed(() => (unref(isUpdate) ? '编辑出库单' : '新增出库单'));
  function addLine() {
    items.value.push({ actualQty: 1 });
  }
  function removeLine(i: number) {
    if (items.value.length > 1) items.value.splice(i, 1);
  }
  function updateItem(i: number, f: string, v: any) {
    items.value[i] = { ...items.value[i], [f]: v };
  }
  async function handleSubmit() {
    const v = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateOutbound({ ...v, items: items.value }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
