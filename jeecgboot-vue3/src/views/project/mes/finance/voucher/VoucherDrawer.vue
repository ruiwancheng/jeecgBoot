<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="isUpdate ? '编辑凭证' : '新增凭证'" width="800px" :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-divider>凭证明细</a-divider>
    <a-button type="dashed" @click="addLine" style="margin-bottom:8px">+ 添加行</a-button>
    <a-table :dataSource="items" :columns="itemColumns" rowKey="id" size="small" bordered :pagination="false">
      <template #bodyCell="{ column, record, index }">
        <template v-if="column.dataIndex === 'subjectId'">
          <JSearchSelect v-model:value="record.subjectId" :dict="'c_mes_account_subject,name,id'" style="width:100%" />
        </template>
        <template v-else-if="column.dataIndex === 'summary'">
          <a-input v-model:value="record.summary" size="small" />
        </template>
        <template v-else-if="column.dataIndex === 'debitAmount'">
          <a-input-number v-model:value="record.debitAmount" size="small" :min="0" style="width:100%" />
        </template>
        <template v-else-if="column.dataIndex === 'creditAmount'">
          <a-input-number v-model:value="record.creditAmount" size="small" :min="0" style="width:100%" />
        </template>
        <template v-else-if="column.dataIndex === 'action'">
          <a-button size="small" danger @click="removeLine(index)">删除</a-button>
        </template>
      </template>
    </a-table>
    <div style="text-align:right;margin-top:8px">借方合计: {{ drTotal }} | 贷方合计: {{ crTotal }} <span v-if="drTotal !== crTotal" style="color:red">不平衡!</span></div>
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, reactive } from 'vue';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { JSearchSelect } from '/@/components/Form';
  import { formSchema } from './voucher.data';
  import { saveOrUpdateVoucher, queryVoucherById } from './voucher.api';
  import { message } from 'ant-design-vue';

  const [registerForm, { validate, setFieldsValue }] = useForm({ schemas: formSchema, labelWidth: 100, showActionButtonGroup: false });
  const isUpdate = ref(false);
  let editId = '';

  const items = reactive<Recordable[]>([]);
  const itemColumns = [
    { title: '科目', dataIndex: 'subjectId', width: 200 },
    { title: '摘要', dataIndex: 'summary', width: 150 },
    { title: '借方金额', dataIndex: 'debitAmount', width: 120 },
    { title: '贷方金额', dataIndex: 'creditAmount', width: 120 },
    { title: '操作', dataIndex: 'action', width: 60 },
  ];

  const drTotal = computed(() => items.reduce((s: number, r: any) => s + (Number(r.debitAmount) || 0), 0).toFixed(2));
  const crTotal = computed(() => items.reduce((s: number, r: any) => s + (Number(r.creditAmount) || 0), 0).toFixed(2));

  function addLine() { items.push({ id: Date.now().toString(), subjectId: '', summary: '', debitAmount: 0, creditAmount: 0 }); }

  function removeLine(index: number) { items.splice(index, 1); }

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    items.length = 0;
    if (data.record) {
      editId = data.record.id;
      setFieldsValue(data.record);
      isUpdate.value = true;
      const res = await queryVoucherById({ id: data.record.id });
      if (res.items) { for (const item of res.items) items.push({ ...item }); }
    } else {
      setFieldsValue({ sourceType: '1', voucherDate: new Date().toISOString().slice(0, 10) });
      isUpdate.value = false; editId = '';
    }
  });

  async function handleSubmit() {
    if (drTotal.value !== crTotal.value) { message.error('借贷不平衡，请调整'); return; }
    const values = await validate();
    values.items = items.map((r, i) => ({ ...r, lineNo: i + 1, debitAmount: Number(r.debitAmount) || 0, creditAmount: Number(r.creditAmount) || 0 }));
    if (isUpdate.value) values.id = editId;
    await saveOrUpdateVoucher(values, isUpdate.value);
    message.success(isUpdate.value ? '编辑成功' : '新增成功');
    closeDrawer();
  }
</script>
