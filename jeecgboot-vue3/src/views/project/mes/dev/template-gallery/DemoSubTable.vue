<template>
  <div>
    <h3>模式 3：明细子表展开行</h3>
    <p style="color:#888">点击行首 "+" 展开明细（生产实现：expandedRowRender + ItemsSubTable 组件，异步加载明细+物料编码映射）</p>
    <a-table :dataSource="docs" :columns="cols" :pagination="false" rowKey="code" :expandedRowKeys="expandedKeys" @expand="onExpand" size="middle">
      <template #expandedRowRender="{ record }">
        <div style="padding: 4px 16px 8px 48px; background: #fafafa">
          <a-table :dataSource="record.items" :columns="itemCols" :pagination="false" size="small" rowKey="material" />
        </div>
      </template>
    </a-table>
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';

  const cols = [
    { title: '单号', dataIndex: 'code', width: 160 },
    { title: '仓库', dataIndex: 'warehouse', width: 120 },
    { title: '总金额', dataIndex: 'total', width: 100 },
  ];
  const itemCols = [
    { title: '物料', dataIndex: 'material', width: 220 },
    { title: '规格型号', dataIndex: 'spec', width: 120 },
    { title: '数量', dataIndex: 'qty', width: 100 },
    { title: '成本单价', dataIndex: 'unitCost', width: 100 },
    { title: '金额', dataIndex: 'amount', width: 100 },
  ];
  const docs = [
    { code: 'DEMO-001', warehouse: '一号仓', total: 555, items: [
      { material: 'MAT-001 — 钢板', spec: '2mm', qty: 10, unitCost: 25.5, amount: '255.00' },
      { material: 'MAT-027 — 环保支架', spec: '-', qty: 10, unitCost: 30, amount: '300.00' },
    ] },
    { code: 'DEMO-002', warehouse: '二号仓', total: 120, items: [
      { material: 'MAT-003 — 螺丝', spec: 'M6', qty: 12, unitCost: 10, amount: '120.00' },
    ] },
  ];
  const expandedKeys = ref<string[]>(['DEMO-001']);
  function onExpand(expanded: boolean, record: any) {
    expandedKeys.value = expanded ? [...expandedKeys.value, record.code] : expandedKeys.value.filter((k) => k !== record.code);
  }
</script>
