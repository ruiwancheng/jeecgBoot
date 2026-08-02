<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <!--update-begin---author:ruiwancheng---date:20260730---for:【MES其它出入库】黄金模板对齐-模式8口径提示Alert----------->
    <!-- 模式 8：口径/快照提示（入库业务提示：库存增加） -->
    <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
    <!--update-end---author:ruiwancheng---date:20260730---for:【MES其它出入库】黄金模板对齐-模式8口径提示Alert----------->
    <a-divider>入库明细</a-divider>
    <div style="margin-bottom: 8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
      <a-button type="dashed" preIcon="ant-design:appstore-add-outlined" style="margin-left: 8px" @click="handleOpenBatchModal"
        >批量添加物料</a-button
      >
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect v-model:modelValue="record.materialId" @change="(v: any) => onMaterialChange(index, v)" style="width: 100%" />
      </template>
      <template #qty="{ record, index }">
        <InputNumber :value="record.qty" :min="0.01" :step="1" style="width: 100%" @change="(v: number) => updateItem(index, 'qty', v)" />
      </template>
      <template #unitCost="{ record, index }">
        <InputNumber
          :value="record.unitCost"
          :min="0"
          :step="0.01"
          :precision="4"
          style="width: 100%"
          placeholder="手工录入"
          @change="(v: number) => updateItem(index, 'unitCost', v)"
        />
      </template>
      <template #amount="{ record }"
        ><span>{{ calcAmount(record) }}</span></template
      >
      <template #action="{ index }"><a-button type="link" danger @click="removeLine(index)">删除</a-button></template>
    </a-table>
    <MaterialSelectModal
      :visible="batchModalVisible"
      mode="multiple"
      @update:visible="batchModalVisible = $event"
      @select="handleBatchAddMaterials"
    />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { InputNumber } from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import MaterialSelectModal from '/@/views/project/mes/basic/material/MaterialSelectModal.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './otherIn.data';
  import { saveOrUpdateOtherIn, queryOtherInById } from './otherIn.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any>([]);
  //update-begin---author:ruiwancheng---date:20260730---for:【MES其它出入库】黄金模板对齐-模式8口径提示Alert-----------
  // 模式 8：入库业务口径提示——库存增加
  const alertText = ref('成本按移动平均预填，可手工修改。入库后库存增加。');
  //update-end---author:ruiwancheng---date:20260730---for:【MES其它出入库】黄金模板对齐-模式8口径提示Alert-----------
  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 240 },
    { title: '数量', dataIndex: 'qty', slots: { customRender: 'qty' }, width: 110 },
    { title: '成本单价', dataIndex: 'unitCost', slots: { customRender: 'unitCost' }, width: 130 },
    { title: '金额', dataIndex: 'amount', slots: { customRender: 'amount' }, width: 110 },
    { title: '操作', slots: { customRender: 'action' }, width: 70 },
  ];

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({ schemas: formSchema, showActionButtonGroup: false, labelWidth: 100 });
  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    items.value = [{ qty: 1, unitCost: 0 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    // 新增时自动获取编码
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.OTHER_STOCK_IN);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) {
        /* fallback: 手动输入 */
      }
    }
    if (unref(isUpdate) && data.record) {
      try {
        const o = await queryOtherInById({ id: data.record.id });
        if (o) {
          await setFieldsValue(o);
          items.value = o.items?.length ? o.items : [{ qty: 1, unitCost: 0 }];
        }
      } catch (e) {}
    }
  });
  const getTitle = computed(() => (unref(isUpdate) ? '编辑入库单' : '新增入库单'));
  function addLine() {
    items.value.push({ qty: 1, unitCost: 0 });
  }
  function removeLine(i: number) {
    if (items.value.length > 1) items.value.splice(i, 1);
  }
  function updateItem(i: number, f: string, v: any) {
    items.value[i] = { ...items.value[i], [f]: v };
  }
  // 选中物料时预填移动平均成本（可手工修改）
  function onMaterialChange(i: number, v: any) {
    updateItem(i, 'materialId', v?.value ?? v);
    const cost = v?.record?.movingAvgCost;
    if (cost != null) updateItem(i, 'unitCost', cost);
  }
  function calcAmount(r: any) {
    return ((Number(r.qty) || 0) * (Number(r.unitCost) || 0)).toFixed(2);
  }

  // 批量添加物料（参考采购申请单）
  const batchModalVisible = ref(false);
  function handleOpenBatchModal() {
    batchModalVisible.value = true;
  }
  function handleBatchAddMaterials(materials: any[]) {
    materials.forEach((m) => {
      items.value.push({ materialId: m.id, qty: 1, unitCost: m.movingAvgCost ?? 0 });
    });
  }

  async function handleSubmit() {
    const v = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateOtherIn({ ...v, items: items.value }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
