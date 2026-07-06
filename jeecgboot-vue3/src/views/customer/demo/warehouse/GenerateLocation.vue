<template>
  <BasicModal @register="registerModal" title="生成库位" :width="500" @ok="handleOk">
    <BasicForm @register="registerForm" />
  </BasicModal>
</template>
<script lang="ts" setup>
import { BasicModal, useModalInner } from '/@/components/Modal';
import { BasicForm, useForm, FormSchema } from '/@/components/Form';
import { generate } from './location.api';
import { message } from 'ant-design-vue';
const forms: FormSchema[] = [
  { label: '选择仓库', field: 'warehouseId', component: 'Input', required: true },
  { label: '区域数量', field: 'zones', component: 'InputNumber', required: true, defaultValue: 1 },
  { label: '通道行数', field: 'channelRows', component: 'InputNumber', required: true, defaultValue: 1 },
  { label: '通道列数', field: 'channelCols', component: 'InputNumber', required: true, defaultValue: 1 },
  { label: '货架行数', field: 'shelfRows', component: 'InputNumber', required: true, defaultValue: 1 },
  { label: '货架列数', field: 'shelfCols', component: 'InputNumber', required: true, defaultValue: 1 },
];
const [registerForm, { resetFields, validate }] = useForm({ schemas: forms, showActionButtonGroup: false });
const [registerModal, { closeModal }] = useModalInner(() => { resetFields(); });
async function handleOk() { const v = await validate(); const r = await generate(v); if (r) { message.success(`成功生成 ${r.length} 个库位`); closeModal(); } }
</script>
