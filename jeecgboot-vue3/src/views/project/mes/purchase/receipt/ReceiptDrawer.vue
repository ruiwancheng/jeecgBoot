<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm">
      <!--update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】模式8口径提示Alert----------->
      <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
      <!--update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】模式8口径提示Alert----------->
      <template #purchaseOrderIdSlot="{ model, field }">
        <JPurchaseOrderSelect v-model:modelValue="model[field]" status="3" @change="onOrderSelected" />
      </template>
    </BasicForm>
    <a-divider>入库行</a-divider>
    <div style="margin-bottom: 8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">手动添加行</a-button>
      <span v-if="items.length > 0" style="margin-left: 12px; color: #666"
        >已勾选 <strong>{{ selectedCount }}</strong> 行 / 共 {{ items.length }} 行</span
      >
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo" :rowSelection="rowSelection">
      <template #materialId="{ record, index }">
        <JMaterialSelect
          v-model:modelValue="record.materialId"
          @change="(v: any) => onMaterialChange(index, v)"
          style="width: 100%"
        />
      </template>
      <template #orderQuantity="{ record }">
        <span>{{ record.orderQuantity }}</span>
      </template>
      <template #receiptQuantity="{ record, index }">
        <InputNumber
          :value="record.receiptQuantity"
          :min="0.01"
          :step="1"
          style="width: 100%"
          @change="(v: number) => updateItem(index, 'receiptQuantity', v)"
        />
      </template>
      <template #qcResult="{ record, index }">
        <a-select
          :value="record.qcResult"
          style="width: 100%"
          @change="(v: any) => updateItem(index, 'qcResult', v)"
          :options="qcOptions"
          placeholder="请选择"
        />
      </template>
      <!--update-begin---author:ruiwancheng---date:20260803---for: V10.0.1 入库明细表单增加 unitPrice/taxRate 编辑插槽（订单物料自动带出/手动物料自动带入 standardPrice）----------->
      <template #unitPrice="{ record, index }">
        <InputNumber
          :value="record.unitPrice"
          :min="0"
          :step="0.01"
          :precision="2"
          style="width: 100%"
          placeholder="单价(不含税)"
          @change="(v: any) => updateItem(index, 'unitPrice', v)"
        />
      </template>
      <template #taxRate="{ record, index }">
        <InputNumber
          :value="record.taxRate"
          :min="0"
          :max="1"
          :step="0.01"
          :precision="2"
          style="width: 100%"
          placeholder="如0.13"
          @change="(v: any) => updateItem(index, 'taxRate', v)"
        />
      </template>
      <!--update-end---author:ruiwancheng---date:20260803---for: V10.0.1 入库明细表单增加 unitPrice/taxRate 编辑插槽----------->
      <template v-if="isBatchOn" #batchNo="{ record, index }">
        <a-input
          :value="record.batchNo"
          placeholder="如：20240101-A 或厂家标签号"
          :maxlength="50"
          style="width: 100%"
          @change="(e: any) => updateItem(index, 'batchNo', e.target.value)"
        />
      </template>
      <template v-if="isBatchOn" #productionDate="{ record, index }">
        <a-date-picker
          :value="record.productionDate"
          valueFormat="YYYY-MM-DD"
          style="width: 100%"
          @change="(v: any) => onProductionDateChange(index, v)"
        />
      </template>
      <!--update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细保质期+有效期至列编辑插槽----------->
      <template v-if="isBatchOn" #shelfLife="{ record, index }">
        <InputNumber
          :value="record.shelfLife"
          :min="0"
          style="width: 100%"
          @change="(v: any) => onShelfLifeChange(index, v)"
        />
      </template>
      <template v-if="isBatchOn" #expiryDate="{ record, index }">
        <a-date-picker
          :value="record.expiryDate"
          valueFormat="YYYY-MM-DD"
          style="width: 100%"
          @change="(v: any) => onExpiryDateChange(index, v)"
        />
      </template>
      <!--update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细保质期+有效期至列编辑插槽----------->
      <template #action="{ index }">
        <a-button type="link" danger @click="removeLine(index)">删除</a-button>
      </template>
    </a-table>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { InputNumber} from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import JPurchaseOrderSelect from '/@/views/project/mes/purchase/order/JPurchaseOrderSelect.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { useMessage } from '/@/hooks/web/useMessage';
  import { formSchema } from './receipt.data';
  import { saveOrUpdateReceipt, queryReceiptById, loadOrderItemsForReceipt } from './receipt.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';
  //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——加载总开关 store 控制明细列是否显示-----------
  import { useMesGlobalSwitchStore } from '/@/store/modules/mesGlobalSwitch';
  //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------
  //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细保质期+有效期至接入物料主数据-----------
  import { queryMaterialById } from '../../basic/material/material.api';
  //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细保质期+有效期至接入物料主数据-----------

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);
  //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】模式8口径提示Alert（响应式）-----------
  // 采购收货口径提示：默认文案。审核后增加库存、重算物料移动平均成本。
  const alertText = ref('由采购订单入库。审核后增加库存、重算物料移动平均成本。');
  //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】模式8口径提示Alert-----------
  //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——总开关 store + 错误提示-----------
  const mesGlobalSwitchStore = useMesGlobalSwitchStore();
  const { createMessage } = useMessage();
  // 总开关开启 = 显示批次号/生产日期两列 + 必填
  const isBatchOn = computed(() => mesGlobalSwitchStore.isBatchEnabled);
  //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------

  const qcOptions = [
    { label: '合格', value: '1' },
    { label: '不合格', value: '2' },
    { label: '待检', value: '3' },
  ];

  //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——itemColumns 改 computed（总开关开启时插入批次号/生产日期两列）-----------
  //update-begin---author:ruiwancheng---date:20260803---for: V10.0.1 入库明细列增加 unitPrice/taxRate（订单物料自动带出/手动物料手动填）-----------
  const baseItemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 180 },
    { title: '采购数量', dataIndex: 'orderQuantity', slots: { customRender: 'orderQuantity' }, width: 100 },
    { title: '已入库', dataIndex: 'receivedQty', width: 80 },
    { title: '可入库', dataIndex: 'remainQty', width: 80 },
    { title: '本次入库数量', dataIndex: 'receiptQuantity', slots: { customRender: 'receiptQuantity' }, width: 120 },
    { title: '单价(不含税)', dataIndex: 'unitPrice', slots: { customRender: 'unitPrice' }, width: 130 },
    { title: '税率', dataIndex: 'taxRate', slots: { customRender: 'taxRate' }, width: 110 },
    { title: '质检结果', dataIndex: 'qcResult', slots: { customRender: 'qcResult' }, width: 100 },
  ];
  //update-end---author:ruiwancheng---date:20260803---for: V10.0.1 入库明细列增加 unitPrice/taxRate-----------
  const itemColumns = computed(() => {
    if (!unref(isBatchOn)) return [...baseItemColumns, { title: '操作', slots: { customRender: 'action' }, width: 80 }];
    // 总开关开启：在"质检结果"后插入"生产批次号"+"生产日期"+"保质期(天)"+"有效期至"四列
    const cols = [...baseItemColumns];
    cols.splice(cols.length - 1, 0,
      { title: '生产批次号', dataIndex: 'batchNo', slots: { customRender: 'batchNo' }, width: 180 },
      { title: '生产日期', dataIndex: 'productionDate', slots: { customRender: 'productionDate' }, width: 140 },
      //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细列增加保质期+有效期至两列-----------
      { title: '保质期(天)', dataIndex: 'shelfLife', slots: { customRender: 'shelfLife' }, width: 110 },
      { title: '有效期至', dataIndex: 'expiryDate', slots: { customRender: 'expiryDate' }, width: 130 },
      //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细列增加保质期+有效期至两列-----------
    );
    cols.push({ title: '操作', slots: { customRender: 'action' }, width: 80 });
    return cols;
  });
  //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: formSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
    actionColOptions: { span: 24 },
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    items.value = [{ lineNo: 1, receiptQuantity: 1, _userTouchedExpiry: false }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——抽屉打开时加载总开关状态-----------
    await mesGlobalSwitchStore.load();
    //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------
    // 新增时自动获取编码
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.PURCHASE_RECEIPT);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) {
        /* fallback: 手动输入 */
      }
    }
    if (unref(isUpdate) && data.record) {
      try {
        const receipt = await queryReceiptById({ id: data.record.id });
        if (receipt) {
          await setFieldsValue(receipt);
          items.value = (
            receipt.items?.length
              ? receipt.items
              : [{ lineNo: 1, receiptQuantity: 1 }]
          ).map((it: any) => ({ ...it, _userTouchedExpiry: !!it._userTouchedExpiry }));
          //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】Alert文案响应式赋值（_dictText）-----------
          // 动态更新 Alert 文案：list 接口返回 purchaseOrderId_dictText，queryById 不返回（仅 ID）。
          const orderRef = receipt.purchaseOrderId_dictText || receipt.purchaseOrderId;
          if (orderRef) {
            alertText.value = `由订单 ${orderRef} 入库。审核后增加库存、重算物料移动平均成本。`;
          }
          //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】Alert文案响应式赋值-----------
        }
      } catch (e) {
        /* fallback */
      }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑采购入库' : '新增采购入库'));

  const selectedRowKeys = ref<string[]>([]);
  const rowSelection = computed(() => ({
    selectedRowKeys: selectedRowKeys.value,
    onChange: (keys: string[]) => {
      selectedRowKeys.value = keys;
    },
    getCheckboxProps: (record: any) => ({ disabled: record.remainQty != null && record.remainQty <= 0 }),
  }));
  const selectedCount = computed(() => selectedRowKeys.value.length);

  function addLine() {
    //update-begin---author:ruiwancheng---date:20260803---for: V10.0.1 手动加行默认 unitPrice=0/taxRate=0.13（手动物料路径，unitPrice 由 onMaterialChange 带 standardPrice）-----------
    items.value.push({
      lineNo: items.value.length + 1,
      receiptQuantity: 1,
      unitPrice: 0,
      taxRate: 0.13,
      _userTouchedExpiry: false,
    });
    //update-end---author:ruiwancheng---date:20260803---for: V10.0.1 手动加行默认 unitPrice=0/taxRate=0.13-----------
  }

  // 选择采购订单后自动加载明细
  async function onOrderSelected(selected: { value: string; label: string; record: any }) {
    if (!selected?.value) {
      items.value = [];
      selectedRowKeys.value = [];
      return;
    }
    try {
      const orderItems = await loadOrderItemsForReceipt(selected.value);
      if (orderItems && orderItems.length > 0) {
        items.value = orderItems.map((it: any, idx: number) => ({
          lineNo: idx + 1,
          materialId: it.materialId,
          orderQuantity: it.orderQty,
          receivedQty: it.receivedQty || 0,
          remainQty: it.remainQty || 0,
          receiptQuantity: it.remainQty && it.remainQty > 0 ? it.remainQty : 0,
          qcResult: undefined,
          // V10.0.1 方案1：订单物料的 unitPrice/taxRate 直接写入 item，audit 不必再反查订单
          // （前缀去掉，不再用 _ 前缀藏起来——直接进 DTO 提交给后端）
          unitPrice: it.unitPrice,
          taxRate: it.taxRate,
          _itemId: it.itemId,
          //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-采购订单加载默认_unusedTouchedExpiry=false-----------
          _userTouchedExpiry: false,
          //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-采购订单加载默认_unusedTouchedExpiry=false-----------
        }));
        // 默认全选可入库行
        selectedRowKeys.value = items.value.filter((it: any) => it.remainQty > 0).map((_: any, i: number) => String(i));
      } else {
        items.value = [];
        selectedRowKeys.value = [];
      }
    } catch (e) {
      items.value = [];
      selectedRowKeys.value = [];
    }
  }
  function removeLine(index: number) {
    if (items.value.length > 1) items.value.splice(index, 1);
  }
  function updateItem(index: number, field: string, value: any) {
    items.value[index] = { ...items.value[index], [field]: value };
  }
  //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细自动带入物料保质期+计算有效期至（替换 V8.0.3 清理冗余版本）-----------
  /** 计算有效期至：YYYY-MM-DD + shelfLife 天。无输入返回 undefined。 */
  function calcExpiry(productionDate?: any, shelfLife?: any): string | undefined {
    if (!productionDate || shelfLife == null || Number(shelfLife) <= 0) return undefined;
    const d = new Date(productionDate);
    if (isNaN(d.getTime())) return undefined;
    d.setDate(d.getDate() + Number(shelfLife));
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  /** 行级：生产日期变化 → 同步重算有效期至（仅程序模式下） */
  function onProductionDateChange(index: number, v: any) {
    const item = items.value[index];
    updateItem(index, 'productionDate', v);
    if (!item._userTouchedExpiry) {
      const exp = calcExpiry(v, item.shelfLife);
      updateItem(index, 'expiryDate', exp ?? null);
    }
  }

  /** 行级：保质期变化 → 同步重算有效期至（仅程序模式下） */
  function onShelfLifeChange(index: number, v: any) {
    const item = items.value[index];
    updateItem(index, 'shelfLife', v);
    if (!item._userTouchedExpiry) {
      const exp = calcExpiry(item.productionDate, v);
      updateItem(index, 'expiryDate', exp ?? null);
    }
  }

  /** 行级：用户手动改有效期至 → 标记不再自动覆盖 */
  function onExpiryDateChange(index: number, v: any) {
    updateItem(index, 'expiryDate', v);
    updateItem(index, '_userTouchedExpiry', true);
  }

  /** 物料选择：回写 materialId + 自动带出物料保质期 + 单价(标准价) + 重算有效期至 */
  async function onMaterialChange(index: number, v: any) {
    const id = v?.value ?? v;
    updateItem(index, 'materialId', id);
    if (!id) return;
    const item = items.value[index];
    // 读取物料主数据：自动带出 standardPrice → unitPrice + shelfLife + 重算 expiryDate
    // 仅在当前未填时自动带入（避免覆盖用户已填值）
    const needFetch = (item.shelfLife == null || item.shelfLife === '')
      || (item.unitPrice == null || item.unitPrice === 0 || item.unitPrice === '');
    if (!needFetch) return;
    try {
      const mat: any = await queryMaterialById({ id });
      if (!mat) return;
      if ((item.shelfLife == null || item.shelfLife === '') && mat.shelfLife != null) {
        updateItem(index, 'shelfLife', mat.shelfLife);
        if (!item._userTouchedExpiry) {
          const exp = calcExpiry(item.productionDate, mat.shelfLife);
          updateItem(index, 'expiryDate', exp ?? null);
        }
      }
      //update-begin---author:ruiwancheng---date:20260803---for: V10.0.1 手动物料路径：物料选择时自动带入 standardPrice 作为 unitPrice 默认值（可改）-----------
      if ((item.unitPrice == null || item.unitPrice === 0 || item.unitPrice === '') && mat.standardPrice != null) {
        updateItem(index, 'unitPrice', mat.standardPrice);
      }
      //update-end---author:ruiwancheng---date:20260803---for: V10.0.1 手动物料自动带入 standardPrice-----------
    } catch (e) {
      /* silent：物料读取失败不影响主流程 */
    }
  }
  //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-入库明细自动带入物料保质期+计算有效期至（替换 V8.0.3 清理冗余版本）-----------

  async function handleSubmit() {
    const values = await validate();
    //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——提交时校验批次号必填 + 长度-----------
    if (unref(isBatchOn)) {
      const selectedIndices = new Set(selectedRowKeys.value.map(Number));
      const submitItems = items.value.filter((_: any, i: number) => selectedIndices.has(i));
      for (let i = 0; i < submitItems.length; i++) {
        const item = submitItems[i];
        if (!item.batchNo || !item.batchNo.trim()) {
          createMessage.error(`第 ${i + 1} 行：生产批次号不能为空（总开关+物料开关已开启）`);
          setDrawerProps({ confirmLoading: false });
          return;
        }
        if (item.batchNo.length > 50) {
          createMessage.error(`第 ${i + 1} 行：生产批次号长度超过 50 个字符`);
          setDrawerProps({ confirmLoading: false });
          return;
        }
      }
    }
    //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------
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
