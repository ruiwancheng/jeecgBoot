<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert----------->
    <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
    <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert----------->
    <a-divider>入库行</a-divider>
    <div style="margin-bottom: 8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect
          v-model:modelValue="record.materialId"
          @change="(v: any) => onMaterialChange(index, v)"
          style="width: 100%"
        />
      </template>
      <template #planQty="{ record, index }">
        <InputNumber :value="record.planQty" :min="0" :step="1" style="width: 100%" @change="(v: number) => updateItem(index, 'planQty', v)" />
      </template>
      <template #receiptQty="{ record, index }">
        <InputNumber
          :value="record.receiptQty"
          :min="0.01"
          :step="1"
          style="width: 100%"
          @change="(v: number) => updateItem(index, 'receiptQty', v)"
        />
      </template>
      <template #action="{ index }">
        <a-button type="link" danger @click="removeLine(index)">删除</a-button>
      </template>
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
          @change="(v: any) => updateItem(index, 'productionDate', v)"
        />
      </template>
    </a-table>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { InputNumber} from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { useMessage } from '/@/hooks/web/useMessage';
  import { formSchema } from './completion.data';
  import { saveOrUpdateCompletion, queryCompletionById } from './completion.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';
  //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——加载总开关 store 控制明细列是否显示-----------
  import { useMesGlobalSwitchStore } from '/@/store/modules/mesGlobalSwitch';
  //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert（响应式）-----------
  // 完工入库口径提示：默认文案。审核后增加库存。Phase 2/3 将增加批次创建。
  const alertText = ref('完工入库审核后增加库存。状态：草稿 → 已入库。');
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert-----------
  //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——总开关 store + 错误提示-----------
  const mesGlobalSwitchStore = useMesGlobalSwitchStore();
  const { createMessage } = useMessage();
  // 总开关开启 = 显示批次号/生产日期两列 + 必填
  const isBatchOn = computed(() => mesGlobalSwitchStore.isBatchEnabled);
  //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------
  const items = ref<any[]>([]);

  //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——itemColumns 改 computed（总开关开启时插入批次号/生产日期两列）-----------
  const baseItemColumns = [
    { title: '产品物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 200 },
    { title: '计划数量', dataIndex: 'planQty', slots: { customRender: 'planQty' }, width: 120 },
    { title: '入库数量', dataIndex: 'receiptQty', slots: { customRender: 'receiptQty' }, width: 120 },
  ];
  const itemColumns = computed(() => {
    if (!unref(isBatchOn)) return [...baseItemColumns, { title: '操作', slots: { customRender: 'action' }, width: 80 }];
    // 总开关开启：在"入库数量"后插入"生产批次号"+"生产日期"两列
    const cols = [...baseItemColumns];
    cols.splice(cols.length - 1, 0,
      { title: '生产批次号', dataIndex: 'batchNo', slots: { customRender: 'batchNo' }, width: 180 },
      { title: '生产日期', dataIndex: 'productionDate', slots: { customRender: 'productionDate' }, width: 140 },
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
    items.value = [{ lineNo: 1, planQty: 0, receiptQty: 1 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——抽屉打开时加载总开关状态-----------
    await mesGlobalSwitchStore.load();
    //update-end---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式-----------
    // 新增时自动获取编码
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.COMPLETION_RECEIPT);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) {
        /* fallback: 手动输入 */
      }
    }
    if (unref(isUpdate) && data.record) {
      try {
        const completion = await queryCompletionById({ id: data.record.id });
        if (completion) {
          await setFieldsValue(completion);
          items.value = completion.items?.length ? completion.items : [{ lineNo: 1, planQty: 0, receiptQty: 1 }];
        }
      } catch (e) {
        /* fallback */
      }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑入库' : '新增入库'));

  function addLine() {
    items.value.push({ lineNo: items.value.length + 1, planQty: 0, receiptQty: 1 });
  }
  function removeLine(index: number) {
    if (items.value.length > 1) items.value.splice(index, 1);
  }
  function updateItem(index: number, field: string, value: any) {
    items.value[index] = { ...items.value[index], [field]: value };
  }
  //update-begin---author:ruiwancheng---date:20260801---for: 清理冗余——同 ReceiptDrawer 同一根因-----------
  function onMaterialChange(index: number, v: any) {
    updateItem(index, 'materialId', v?.value ?? v);
  }
  //update-end---author:ruiwancheng---date:20260801---for: 清理冗余字段-----------

  async function handleSubmit() {
    const values = await validate();
    //update-begin---author:ruiwancheng---date:20260801---for: V8.0.3 手工录入模式——提交时校验批次号必填 + 长度-----------
    if (unref(isBatchOn)) {
      for (let i = 0; i < items.value.length; i++) {
        const item = items.value[i];
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
      await saveOrUpdateCompletion({ ...values, items: items.value }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
