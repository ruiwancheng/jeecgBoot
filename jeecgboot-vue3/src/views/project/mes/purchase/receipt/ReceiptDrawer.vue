<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm">
      <template #purchaseOrderIdSlot="{ model, field }">
        <JPurchaseOrderSelect v-model:modelValue="model[field]" status="3" @change="onOrderSelected" />
      </template>
    </BasicForm>
    <a-divider>入库行</a-divider>
    <div style="margin-bottom:8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">手动添加行</a-button>
      <span v-if="items.length > 0" style="margin-left: 12px; color: #666;">已勾选 <strong>{{ selectedCount }}</strong> 行 / 共 {{ items.length }} 行</span>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo" :rowSelection="rowSelection">
      <template #materialId="{ record, index }">
        <JMaterialSelect v-model:modelValue="record.materialId" @change="(v:any) => updateItem(index, 'materialId', v?.value ?? v)" style="width:100%" />
      </template>
      <template #orderQuantity="{ record }">
        <span>{{ record.orderQuantity }}</span>
      </template>
      <template #receiptQuantity="{ record, index }">
        <InputNumber :value="record.receiptQuantity" :min="0.01" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'receiptQuantity', v)" />
      </template>
      <template #qcResult="{ record, index }">
        <a-select :value="record.qcResult" style="width:100%" @change="(v:any) => updateItem(index, 'qcResult', v)" :options="qcOptions" placeholder="请选择" />
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
  import JPurchaseOrderSelect from '/@/views/project/mes/purchase/order/JPurchaseOrderSelect.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './receipt.data';
  import { saveOrUpdateReceipt, queryReceiptById, loadOrderItemsForReceipt } from './receipt.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);

  const qcOptions = [
    { label: '合格', value: '1' },
    { label: '不合格', value: '2' },
    { label: '待检', value: '3' },
  ];

  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 180 },
    { title: '物料编码', dataIndex: 'materialCode', width: 100 },
    { title: '采购数量', dataIndex: 'orderQuantity', slots: { customRender: 'orderQuantity' }, width: 100 },
    { title: '已入库', dataIndex: 'receivedQty', width: 80 },
    { title: '可入库', dataIndex: 'remainQty', width: 80 },
    { title: '本次入库数量', dataIndex: 'receiptQuantity', slots: { customRender: 'receiptQuantity' }, width: 120 },
    { title: '质检结果', dataIndex: 'qcResult', slots: { customRender: 'qcResult' }, width: 100 },
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
    items.value = [{ lineNo: 1, receiptQuantity: 1 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    // 新增时自动获取编码
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.PURCHASE_RECEIPT);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) { /* fallback: 手动输入 */ }
    }
    if (unref(isUpdate) && data.record) {
      try {
        const receipt = await queryReceiptById({ id: data.record.id });
        if (receipt) {
          await setFieldsValue(receipt);
          items.value = receipt.items?.length ? receipt.items : [{ lineNo: 1, receiptQuantity: 1 }];
        }
      } catch (e) { /* fallback */ }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑采购入库' : '新增采购入库'));

  const selectedRowKeys = ref<string[]>([]);
  const rowSelection = computed(() => ({
    selectedRowKeys: selectedRowKeys.value,
    onChange: (keys: string[]) => { selectedRowKeys.value = keys; },
    getCheckboxProps: (record: any) => ({ disabled: record.remainQty != null && record.remainQty <= 0 }),
  }));
  const selectedCount = computed(() => selectedRowKeys.value.length);

  function addLine() { items.value.push({ lineNo: items.value.length + 1, receiptQuantity: 1 }); }

  // 选择采购订单后自动加载明细
  async function onOrderSelected(selected: { value: string; label: string; record: any }) {
    if (!selected?.value) { items.value = []; selectedRowKeys.value = []; return; }
    try {
      const orderItems = await loadOrderItemsForReceipt(selected.value);
      if (orderItems && orderItems.length > 0) {
        items.value = orderItems.map((it: any, idx: number) => ({
          lineNo: idx + 1,
          materialId: it.materialId,
          materialCode: it.materialCode || '',
          orderQuantity: it.orderQty,
          receivedQty: it.receivedQty || 0,
          remainQty: it.remainQty || 0,
          receiptQuantity: it.remainQty && it.remainQty > 0 ? it.remainQty : 0,
          qcResult: undefined,
          _itemId: it.itemId,
          _unitPrice: it.unitPrice,
          _taxRate: it.taxRate,
        }));
        // 默认全选可入库行
        selectedRowKeys.value = items.value
          .filter((it: any) => it.remainQty > 0)
          .map((_: any, i: number) => String(i));
      } else {
        items.value = [];
        selectedRowKeys.value = [];
      }
    } catch (e) {
      items.value = [];
      selectedRowKeys.value = [];
    }
  }
  function removeLine(index: number) { if (items.value.length > 1) items.value.splice(index, 1); }
  function updateItem(index: number, field: string, value: any) { items.value[index] = { ...items.value[index], [field]: value }; }

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      // 仅提交勾选的行
      const selectedIndices = new Set(selectedRowKeys.value.map(Number));
      const submitItems = items.value.filter((_: any, i: number) => selectedIndices.has(i));
      if (submitItems.length === 0) {
        setDrawerProps({ confirmLoading: false });
        return;
      }
      await saveOrUpdateReceipt({ ...values, items: submitItems }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
