<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-divider>出库明细</a-divider>
    <div style="margin-bottom:8px"><a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button></div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JSearchSelect :value="record.materialId" @change="(v:any) => updateItem(index, 'materialId', v?.value || v)" :dict="'c_mes_material,name,id'" style="width:100%" />
      </template>
      <template #deliveryQty="{ record }"><span>{{ record.deliveryQty }}</span></template>
      <template #actualQty="{ record, index }">
        <InputNumber :value="record.actualQty" :min="0.01" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'actualQty', v)" />
      </template>
      <template #batch="{ record, index }">
        <Input :value="record.batch" style="width:100%" @change="(e:any) => updateItem(index, 'batch', e.target.value)" />
      </template>
      <template #location="{ record, index }">
        <Input :value="record.location" style="width:100%" @change="(e:any) => updateItem(index, 'location', e.target.value)" />
      </template>
      <template #action="{ index }"><a-button type="link" danger @click="removeLine(index)">删除</a-button></template>
    </a-table>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { Input, InputNumber, Divider } from 'ant-design-vue';
  import { JSearchSelect } from '/@/components/Form';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './outbound.data';
  import { saveOrUpdateOutbound, queryOutboundById } from './outbound.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);
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
    await resetFields(); items.value = [{ actualQty: 1 }]; isUpdate.value = !!data?.isUpdate; setDrawerProps({ confirmLoading: false });
    if (unref(isUpdate) && data.record) { try { const o = await queryOutboundById({ id: data.record.id }); if (o) { await setFieldsValue(o); items.value = o.items?.length ? o.items : [{ actualQty: 1 }]; } } catch (e) {} }
  });
  const getTitle = computed(() => (unref(isUpdate) ? '编辑出库单' : '新增出库单'));
  function addLine() { items.value.push({ actualQty: 1 }); }
  function removeLine(i: number) { if (items.value.length > 1) items.value.splice(i, 1); }
  function updateItem(i: number, f: string, v: any) { items.value[i] = { ...items.value[i], [f]: v }; }
  async function handleSubmit() { const v = await validate(); setDrawerProps({ confirmLoading: true }); try { await saveOrUpdateOutbound({ ...v, items: items.value }, unref(isUpdate)); closeDrawer(); emit('success'); } finally { setDrawerProps({ confirmLoading: false }); } }
</script>
