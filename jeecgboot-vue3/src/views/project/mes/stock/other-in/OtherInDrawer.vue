<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-divider>入库明细</a-divider>
    <div style="margin-bottom:8px"><a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button></div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect v-model:modelValue="record.materialId" @change="(v:any) => updateItem(index, 'materialId', v?.value ?? v)" style="width:100%" />
      </template>
      <template #warehouseId="{ record, index }">
        <ApiSelect :value="record.warehouseId" :api="queryWarehouseSelect" style="width:100%" @change="(v:any) => updateItem(index, 'warehouseId', v)" />
      </template>
      <template #locationId="{ record, index }">
        <ApiSelect :value="record.locationId" :api="(p:any) => queryLocationSelect({ ...p, warehouseId: record.warehouseId })" style="width:100%" @change="(v:any) => updateItem(index, 'locationId', v)" />
      </template>
      <template #qty="{ record, index }">
        <InputNumber :value="record.qty" :min="0.01" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'qty', v)" />
      </template>
      <template #action="{ index }"><a-button type="link" danger @click="removeLine(index)">删除</a-button></template>
    </a-table>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { InputNumber } from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { ApiSelect } from '/@/components/Form';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './otherIn.data';
  import { saveOrUpdateOtherIn, queryOtherInById, queryLocationSelect } from './otherIn.api';
  import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);
  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 220 },
    { title: '仓库', dataIndex: 'warehouseId', slots: { customRender: 'warehouseId' }, width: 170 },
    { title: '库位', dataIndex: 'locationId', slots: { customRender: 'locationId' }, width: 170 },
    { title: '数量', dataIndex: 'qty', slots: { customRender: 'qty' }, width: 110 },
    { title: '操作', slots: { customRender: 'action' }, width: 70 },
  ];

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({ schemas: formSchema, showActionButtonGroup: false, labelWidth: 100 });
  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields(); items.value = [{ qty: 1 }]; isUpdate.value = !!data?.isUpdate; setDrawerProps({ confirmLoading: false });
    // 新增时自动获取编码
    if (!unref(isUpdate)) { try { const nextCode = await getNextCode(MES_BIZ_CODE.OTHER_STOCK_IN); if (nextCode) await setFieldsValue({ code: nextCode }); } catch (e) { /* fallback: 手动输入 */ } }
    if (unref(isUpdate) && data.record) { try { const o = await queryOtherInById({ id: data.record.id }); if (o) { await setFieldsValue(o); items.value = o.items?.length ? o.items : [{ qty: 1 }]; } } catch (e) {} }
  });
  const getTitle = computed(() => (unref(isUpdate) ? '编辑入库单' : '新增入库单'));
  function addLine() { items.value.push({ qty: 1 }); }
  function removeLine(i: number) { if (items.value.length > 1) items.value.splice(i, 1); }
  function updateItem(i: number, f: string, v: any) { items.value[i] = { ...items.value[i], [f]: v }; }
  async function handleSubmit() { const v = await validate(); setDrawerProps({ confirmLoading: true }); try { await saveOrUpdateOtherIn({ ...v, items: items.value }, unref(isUpdate)); closeDrawer(); emit('success'); } finally { setDrawerProps({ confirmLoading: false }); } }
</script>
