<template>
  <div>
    <BasicTable @register="registerTable">
      <template #expandedRowRender="{ record }">
        <InventoryLedgerSubTable :materialId="record.material_id" :warehouseId="record.warehouse_id" />
      </template>
      <template #tableTitle>
        <span>库存总览</span>
        <span style="margin-left:16px; color:#888; font-weight:normal; font-size:13px">
          库存金额合计：<b style="color:#1677ff">{{ pageTotalAmount }}</b>（零库存红标，点行首 + 看最近台账）
        </span>
      </template>
      <!-- 孤儿行兜底：物料/仓库被删后显示“已删除”而非空白 -->
      <template #matText="{ record }">
        <span v-if="record.material_code">{{ record.material_code }}</span>
        <span v-else style="color:#bbb" title="物料已被删除，建议清理该库存行">（物料已删除）</span>
      </template>
      <template #whText="{ record }">
        <span v-if="record.warehouse_name">{{ record.warehouse_name }}</span>
        <span v-else style="color:#bbb">（仓库已删除）</span>
      </template>
      <!-- 模式 9 变体：零库存红标 -->
      <template #qtyTag="{ record }">
        <span v-if="Number(record.current_qty) === 0" style="color:#f5222d; font-weight:600">0（零库存）</span>
        <span v-else>{{ record.current_qty }}</span>
      </template>
      <template #amountText="{ record }">
        <span :style="{ color: Number(record.inventory_amount) > 0 ? '#1677ff' : '#999' }">{{ record.inventory_amount }}</span>
      </template>
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { BasicTable } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './inventory.data';
  import { queryInventoryList } from './inventory.api';
  import InventoryLedgerSubTable from './InventoryLedgerSubTable.vue';

  defineOptions({ name: 'MesInventoryOverview' });

  const pageTotalAmount = ref('0.00');

  const { tableContext } = useListPage({
    designScope: 'mes-inventory',
    tableProps: {
      title: '库存总览',
      api: queryInventoryList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
      pagination: { pageSize: 20 },
    },
  });

  const [registerTable] = tableContext;

  onMounted(async () => {
    // 库存金额合计（前200条粗算；全量精确汇总留后端汇总接口，V3候选）
    try {
      const res: any = await queryInventoryList({ pageNo: 1, pageSize: 200 });
      const total = (res?.records || []).reduce((s: number, r: any) => s + Number(r.inventory_amount || 0), 0);
      pageTotalAmount.value = total.toFixed(2);
    } catch (e) { /* 合计失败不阻塞 */ }
  });
</script>
