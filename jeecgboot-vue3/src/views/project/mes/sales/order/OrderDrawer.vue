<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-divider>订单行</a-divider>
    <div style="margin-bottom:8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
      <a-button type="dashed" preIcon="ant-design:unordered-list-outlined" @click="handleOpenBatchModal" style="margin-left: 8px">添加物料</a-button>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect v-model:modelValue="record.materialId" @change="(v:any) => onMaterialChange(index, v)" style="width:100%" />
      </template>
      <template #spec="{ record }">
        <span>{{ record.spec || '-' }}</span>
      </template>
      <template #unitText="{ record }">
        <span>{{ record.unitText || '-' }}</span>
      </template>
      <template #quantity="{ record, index }">
        <InputNumber :value="record.quantity" :min="0.01" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'quantity', v)" />
      </template>
      <template #unitPrice="{ record, index }">
        <InputNumber :value="record.unitPrice" :min="0" :precision="2" style="width:100%" @change="(v:number) => updateItem(index, 'unitPrice', v)" />
      </template>
      <template #taxRate="{ record, index }">
        <InputNumber :value="record.taxRate" :min="0" :max="1" :step="0.01" style="width:100%" @change="(v:number) => updateItem(index, 'taxRate', v)" />
      </template>
      <template #taxAmount="{ record }">
        <span>{{ ((record.quantity || 0) * (record.unitPrice || 0) * (record.taxRate || 0)).toFixed(2) }}</span>
      </template>
      <template #amount="{ record }">
        <span>{{ ((record.quantity || 0) * (record.unitPrice || 0)).toFixed(2) }}</span>
      </template>
      <template #action="{ index }">
        <a-button type="link" danger @click="removeLine(index)">删除</a-button>
      </template>
    </a-table>
    <div style="text-align:right; padding:8px 4px; font-weight:500">
      合计：数量 {{ totalQty }} ｜ 金额 ¥{{ totalAmount }} ｜ 税额 ¥{{ totalTax }}
    </div>
    <MaterialSelectModal :visible="batchModalVisible" mode="multiple" @update:visible="batchModalVisible = $event" @select="handleBatchAddMaterials" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref, nextTick } from 'vue';
  import { InputNumber, Divider } from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import MaterialSelectModal from '/@/views/project/mes/basic/material/MaterialSelectModal.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './order.data';
  import { saveOrUpdateOrder, queryOrderById } from './order.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';
  import { queryMaterialById } from '../../basic/material/material.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);

  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 180 },
    { title: '规格', dataIndex: 'spec', slots: { customRender: 'spec' }, width: 100 },
    { title: '单位', dataIndex: 'unitText', slots: { customRender: 'unitText' }, width: 60 },
    { title: '数量', dataIndex: 'quantity', slots: { customRender: 'quantity' }, width: 100 },
    { title: '单价', dataIndex: 'unitPrice', slots: { customRender: 'unitPrice' }, width: 110 },
    { title: '税率', dataIndex: 'taxRate', slots: { customRender: 'taxRate' }, width: 90 },
    { title: '金额', slots: { customRender: 'amount' }, width: 100 },
    { title: '税额', slots: { customRender: 'taxAmount' }, width: 90 },
    { title: '操作', slots: { customRender: 'action' }, width: 70 },
  ];

  // 合计行（数量/金额/税额实时汇总）
  const totalQty = computed(() => items.value.reduce((s, i) => s + (Number(i.quantity) || 0), 0));
  const totalAmount = computed(() => items.value.reduce((s, i) => s + (i.quantity || 0) * (i.unitPrice || 0), 0).toFixed(2));
  const totalTax = computed(() => items.value.reduce((s, i) => s + (i.quantity || 0) * (i.unitPrice || 0) * (i.taxRate || 0), 0).toFixed(2));

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: formSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
    actionColOptions: { span: 24 },
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    items.value = [{ lineNo: 1, quantity: 1, unitPrice: 0, taxRate: 0.13 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    // 新增时自动获取编码
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.SALES_ORDER);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) { /* fallback: 手动输入 */ }
    }
    if (unref(isUpdate) && data.record) {
      try {
        const order = await queryOrderById({ id: data.record.id });
        if (order) {
          await setFieldsValue(order);
          items.value = order.items?.length ? await enrichItems(order.items) : [{ lineNo: 1, quantity: 1, unitPrice: 0, taxRate: 0.13 }];
        }
      } catch (e) { /* fallback to list data */ }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑订单' : '新增订单'));

  function addLine() { items.value.push({ lineNo: items.value.length + 1, quantity: 1, unitPrice: 0, taxRate: 0.13 }); }
  function removeLine(index: number) { if (items.value.length > 1) items.value.splice(index, 1); }
  function updateItem(index: number, field: string, value: any) { items.value[index] = { ...items.value[index], [field]: value }; }

  // 选择物料时同步带出规格/单位
  function onMaterialChange(index: number, v: any) {
    const m = v?.record;
    items.value[index] = { ...items.value[index], materialId: v?.value ?? v, spec: m?.spec || '', unitText: m?.unit_dictText || '' };
  }

  // 编辑时补齐明细行的规格/单位（订单行不冗余存储，按物料ID批量查）
  async function enrichItems(list: any[]) {
    const ids = [...new Set(list.map((i) => i.materialId).filter(Boolean))] as string[];
    const materials = await Promise.all(ids.map((id) => queryMaterialById({ id }).catch(() => null)));
    const map: Record<string, any> = {};
    materials.forEach((m) => { if (m?.id) map[m.id] = m; });
    return list.map((i) => ({ ...i, spec: map[i.materialId]?.spec || '', unitText: map[i.materialId]?.unit_dictText || '', taxRate: i.taxRate ?? 0.13 }));
  }

  const batchModalVisible = ref(false);
  function handleOpenBatchModal() { batchModalVisible.value = true; }
  function handleBatchAddMaterials(materials: any[]) {
    const startLineNo = items.value.length + 1;
    materials.forEach((m, i) => {
      items.value.push({
        lineNo: startLineNo + i,
        materialId: m.id,
        spec: m.spec || '',
        unitText: m.unit_dictText || '',
        quantity: 1,
        unitPrice: 0,
        taxRate: 0.13,
      });
    });
  }

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
