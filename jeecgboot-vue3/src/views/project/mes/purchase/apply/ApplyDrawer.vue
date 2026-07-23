<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1000px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-divider>申请行</a-divider>
    <div style="margin-bottom:8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" @click="addLine">添加行</a-button>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect v-model:modelValue="record.materialId" @change="(v:any) => updateItem(index, 'materialId', v?.value ?? v)" style="width:100%" />
      </template>
      <template #quantity="{ record, index }">
        <InputNumber :value="record.quantity" :min="0.01" :step="1" style="width:100%" @change="(v:number) => updateItem(index, 'quantity', v)" />
      </template>
      <!--update-begin---author:ruisuyun---date:2026-07-23---for: 采购申请明细加单价/金额列---------->
      <template #unitPrice="{ record, index }">
        <InputNumber :value="record.unitPrice" :min="0" :precision="2" style="width:100%" @change="(v:number) => updateItem(index, 'unitPrice', v)" />
      </template>
      <template #amount="{ record }">
        <span>{{ ((record.quantity || 0) * (record.unitPrice || 0)).toFixed(2) }}</span>
      </template>
      <!--update-end---author:ruisuyun---date:2026-07-23---for: 采购申请明细加单价/金额列---------->
      <template #unit="{ record, index }">
        <a-input :value="record.unit" style="width:100%" @change="(e:any) => updateItem(index, 'unit', e.target.value)" />
      </template>
      <template #purpose="{ record, index }">
        <a-input :value="record.purpose" style="width:100%" @change="(e:any) => updateItem(index, 'purpose', e.target.value)" />
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
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './apply.data';
  import { saveOrUpdateApply, queryApplyById } from './apply.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';
  import { useUserStore } from '/@/store/modules/user';

  const userStore = useUserStore();
  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const items = ref<any[]>([]);

  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 180 },
    { title: '数量', dataIndex: 'quantity', slots: { customRender: 'quantity' }, width: 100 },
    //update-begin---author:ruisuyun---date:2026-07-23---for: 采购申请明细加单价/金额列-----------
    { title: '单价', dataIndex: 'unitPrice', slots: { customRender: 'unitPrice' }, width: 110 },
    { title: '金额', slots: { customRender: 'amount' }, width: 100 },
    //update-end---author:ruisuyun---date:2026-07-23---for: 采购申请明细加单价/金额列-----------
    { title: '单位', dataIndex: 'unit', slots: { customRender: 'unit' }, width: 80 },
    { title: '用途说明', dataIndex: 'purpose', slots: { customRender: 'purpose' }, width: 200 },
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
    items.value = [{ lineNo: 1, quantity: 1, unitPrice: 0 }];
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    // 新增时自动填入当前用户为申请人 + 自动获取编码
      if (!unref(isUpdate)) {
        const applicant = userStore.getUserInfo?.realname || '';
        await setFieldsValue({ applicantId: applicant });
        try {
        const nextCode = await getNextCode(MES_BIZ_CODE.PURCHASE_APPLY);
        if (nextCode) await setFieldsValue({ code: nextCode });
      } catch (e) { /* fallback: 手动输入 */ }
    }
    if (unref(isUpdate) && data.record) {
      try {
        const apply = await queryApplyById({ id: data.record.id });
        if (apply) {
          await setFieldsValue(apply);
          items.value = apply.items?.length ? apply.items : [{ lineNo: 1, quantity: 1 }];
        }
      } catch (e) { /* fallback */ }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑采购申请' : '新增采购申请'));

  function addLine() { items.value.push({ lineNo: items.value.length + 1, quantity: 1, unitPrice: 0 }); }
  function removeLine(index: number) { if (items.value.length > 1) items.value.splice(index, 1); }
  function updateItem(index: number, field: string, value: any) { items.value[index] = { ...items.value[index], [field]: value }; }

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateApply({ ...values, items: items.value }, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
