<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert----------->
    <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
    <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert----------->
    <a-divider>BOM行</a-divider>
    <div style="margin-bottom: 8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
      <!--update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗----------->
      <a-button type="dashed" preIcon="ant-design:appstore-add-outlined" style="margin-left:8px" @click="handleOpenBatchModal">批量添加物料</a-button>
      <!--update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗----------->
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect
          v-model:modelValue="record.materialId"
          @change="(v: any) => updateItem(index, 'materialId', v?.value ?? v)"
          style="width: 100%"
        />
      </template>
      <template #quantity="{ record, index }">
        <InputNumber :value="record.quantity" :min="0.01" :step="1" style="width: 100%" @change="(v: number) => updateItem(index, 'quantity', v)" />
      </template>
      <template #lossRate="{ record, index }">
        <!--update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式9损耗率>50%红标（drawer 内编辑时也提示）----------->
        <span :style="(Number(record.lossRate) || 0) > 50 ? { color: '#ff4d4f', fontWeight: 'bold' } : {}">
          <InputNumber
            :value="record.lossRate"
            :min="0"
            :max="100"
            :precision="2"
            style="width: 100%"
            @change="(v: number) => updateItem(index, 'lossRate', v)"
          />
        </span>
        <!--update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式9损耗率>50%红标----------->
      </template>
      <template #isAlternative="{ record, index }">
        <a-switch
          :checked="record.isAlternative === 1"
          :checkedValue="1"
          :unCheckedValue="0"
          @change="(v: number) => updateItem(index, 'isAlternative', v)"
        />
      </template>
      <template #action="{ index }">
        <a-button type="link" danger @click="removeLine(index)">删除</a-button>
      </template>
    </a-table>
    <!--update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗（实例）----------->
    <MaterialSelectModal
      :visible="batchModalVisible"
      mode="multiple"
      @update:visible="batchModalVisible = $event"
      @select="handleBatchAddMaterials"
    />
    <!--update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗（实例）----------->
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { InputNumber, Divider } from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗（imports）-----------
  import MaterialSelectModal from '/@/views/project/mes/basic/material/MaterialSelectModal.vue';
  //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗（imports）-----------
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './bom.data';
  import { saveOrUpdateBom, queryBomById } from './bom.api';
  //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式4自动编码接线（imports）-----------
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';
  //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式4自动编码接线（imports）-----------

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any>([]);
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert（响应式）-----------
  // BOM 口径提示：默认文案。BOM 生效后才能被生产订单引用。
  const alertText = ref('BOM 生效后才能被生产订单引用。状态：草稿 → 生效 → 失效。');
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】模式8口径提示Alert-----------
  //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗（state）-----------
  const batchModalVisible = ref(false);
  //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗（state）-----------

  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 200 },
    { title: '用量', dataIndex: 'quantity', slots: { customRender: 'quantity' }, width: 120 },
    { title: '损耗率(%)', dataIndex: 'lossRate', slots: { customRender: 'lossRate' }, width: 120 },
    { title: '替代料', dataIndex: 'isAlternative', slots: { customRender: 'isAlternative' }, width: 80 },
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
    items.value = [{ lineNo: 1, quantity: 1, lossRate: 0, isAlternative: 0 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式4自动编码接线（新增时）-----------
    // 模式 4：新增时自动获取编码（失败回退手工输入，不阻塞开单）
    if (!unref(isUpdate)) {
      try {
        const nextCode = await getNextCode(MES_BIZ_CODE.BOM);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) {
        /* fallback: 手工输入 */
      }
    }
    //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式4自动编码接线（新增时）-----------
    if (unref(isUpdate) && data.record) {
      try {
        const bom = await queryBomById({ id: data.record.id });
        if (bom) {
          await setFieldsValue(bom);
          items.value = bom.items?.length ? bom.items : [{ lineNo: 1, quantity: 1, lossRate: 0, isAlternative: 0 }];
        }
      } catch (e) {
        /* fallback */
      }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑BOM' : '新增BOM'));

  function addLine() {
    items.value.push({ lineNo: items.value.length + 1, quantity: 1, lossRate: 0, isAlternative: 0 });
  }
  function removeLine(index: number) {
    if (items.value.length > 1) items.value.splice(index, 1);
  }
  function updateItem(index: number, field: string, value: any) {
    items.value[index] = { ...items.value[index], [field]: value };
  }

  //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗（handlers）-----------
  function handleOpenBatchModal() {
    batchModalVisible.value = true;
  }
  function handleBatchAddMaterials(materials: any[]) {
    const startLineNo = items.value.length + 1;
    materials.forEach((m, i) => {
      items.value.push({
        lineNo: startLineNo + i,
        materialId: m.id,
        materialId_dictText: m.name || m.code || '',
        quantity: 1,
        lossRate: 0,
        isAlternative: 0,
      });
    });
  }
  //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式6批量添加物料弹窗（handlers）-----------

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateBom({ ...values, items: items.value }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>