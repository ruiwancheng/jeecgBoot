<template>
  <div>
    <h3>抽屉模式（4/5/6/8/9）</h3>
    <!-- 模式 8：口径 Alert -->
    <a-alert type="info" show-icon style="margin-bottom:12px" message="成本单价按移动平均成本预填，可手工修改（模式 8 提示样式）" />
    <BasicForm @register="registerForm" />
    <a-divider>明细行（模式 5/6/9）</a-divider>
    <div style="margin-bottom:8px">
      <a-button type="dashed" @click="addLine">添加行</a-button>
      <!-- 模式 6：批量添加物料（真实弹窗组件，调真实接口） -->
      <a-button type="dashed" style="margin-left:8px" @click="batchVisible = true">批量添加物料</a-button>
      <span style="margin-left:12px; color:#888">弹窗为生产真实 MaterialSelectModal</span>
    </div>
    <a-table :dataSource="items" :columns="cols" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <JMaterialSelect v-model:modelValue="record.materialId" @change="(v:any) => onMaterialChange(index, v)" style="width:100%" />
      </template>
      <template #qty="{ record, index }">
        <InputNumber :value="record.qty" :min="0.01" style="width:100%" @change="(v:number) => updateItem(index, 'qty', v)" />
      </template>
      <template #unitCost="{ record, index }">
        <InputNumber :value="record.unitCost" :min="0" :precision="4" style="width:100%" @change="(v:number) => updateItem(index, 'unitCost', v)" />
      </template>
      <template #amount="{ record }"><span>{{ (record.qty * record.unitCost).toFixed(2) }}</span></template>
      <!-- 模式 9：差异红标 -->
      <template #diff="{ record }">
        <span :style="{ color: record.diff !== 0 ? '#f5222d' : '#999', fontWeight: record.diff !== 0 ? 600 : 400 }">{{ record.diff }}</span>
      </template>
    </a-table>
    <MaterialSelectModal :visible="batchVisible" mode="multiple" @update:visible="batchVisible = $event" @select="onBatch" />
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import { InputNumber } from 'ant-design-vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import MaterialSelectModal from '/@/views/project/mes/basic/material/MaterialSelectModal.vue';

  // 模式 4：自动编码演示（固定展示，真实接线用 getNextCode）
  const [registerForm] = useForm({
    schemas: [
      { field: 'code', label: '单号', component: 'Input', colProps: { span: 8 }, componentProps: { placeholder: '打开抽屉时自动获取（getNextCode）' } },
      { field: 'bizDate', label: '业务日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
      { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 16 } },
    ],
    labelWidth: 90,
    showActionButtonGroup: false,
  });

  const cols = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 240 },
    { title: '数量', dataIndex: 'qty', slots: { customRender: 'qty' }, width: 110 },
    { title: '成本单价', dataIndex: 'unitCost', slots: { customRender: 'unitCost' }, width: 130 },
    { title: '金额', dataIndex: 'amount', slots: { customRender: 'amount' }, width: 100 },
    { title: '差异', dataIndex: 'diff', slots: { customRender: 'diff' }, width: 90 },
  ];

  const items = ref<any[]>([
    { lineNo: 1, materialId: '', qty: 10, unitCost: 25.5, diff: 0 },
    { lineNo: 2, materialId: '', qty: 3, unitCost: 30, diff: -5 },
  ]);
  function updateItem(i: number, f: string, v: any) { items.value[i] = { ...items.value[i], [f]: v }; }
  function addLine() { items.value.push({ lineNo: items.value.length + 1, materialId: '', qty: 1, unitCost: 0, diff: 0 }); }
  // 模式 6：选物料预填移动平均成本
  function onMaterialChange(i: number, v: any) {
    updateItem(i, 'materialId', v?.value ?? v);
    const cost = v?.record?.movingAvgCost;
    if (cost != null) updateItem(i, 'unitCost', cost);
  }
  const batchVisible = ref(false);
  function onBatch(materials: any[]) {
    materials.forEach((m) => items.value.push({ lineNo: items.value.length + 1, materialId: m.id, qty: 1, unitCost: m.movingAvgCost ?? 0, diff: 0 }));
  }
</script>
