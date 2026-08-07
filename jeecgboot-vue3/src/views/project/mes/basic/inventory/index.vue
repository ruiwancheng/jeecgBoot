<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】加 rowSelection（黄金模板模式 2）---------->
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
    <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】加 rowSelection----------->
      <template #expandedRowRender="{ record }">
        <InventoryLedgerSubTable :materialId="record.material_id" :warehouseId="record.warehouse_id" />
      </template>
      <template #tableTitle>
        <span>库存总览</span>
        <span style="margin-left:16px; color:#888; font-weight:normal; font-size:13px">
          库存金额合计：<b style="color:#1677ff">{{ pageTotalAmount }}</b>（零库存红标，点行首 + 看最近台账）
        </span>
        <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删除按钮（仅当选中含孤儿行时显示）---------->
        <a-button
          v-if="selectedOrphanKeys.length > 0"
          danger
          preIcon="ant-design:delete-outlined"
          style="margin-left:16px"
          @click="batchDeleteOrphan">
          批量删除孤儿行（{{ selectedOrphanKeys.length }}）
        </a-button>
        <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删除按钮----------->
        <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】导出孤儿清单按钮（独立条件 orphanCount > 0）---------->
        <a-button
          v-if="orphanCount > 0"
          preIcon="ant-design:export-outlined"
          style="margin-left:8px"
          @click="exportOrphanXls">
          导出孤儿清单（{{ orphanCount }}）
        </a-button>
        <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】导出孤儿清单按钮----------->
      </template>
      <!-- 孤儿行兜底：物料/仓库被删后显示"已删除"而非空白 -->
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
      <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】orphanTag 槽位（孤儿标识 + 字典翻译）---------->
      <template #orphanTag="{ record }">
        <a-tag v-if="record.isOrphan === '1'" :color="orphanColor(record)" :title="record.isOrphan_dictText || orphanReason(record)">孤儿行</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】orphanTag 槽位----------->
      <!--update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】action 槽位（单行删除按钮）---------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
      <!--update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】action 槽位----------->
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增 imports + TableAction + Modal.confirm-----------
  import { ref, computed, reactive, onMounted } from 'vue';
  import { BasicTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { columns, searchFormSchema } from './inventory.data';
  import { queryInventoryList, deleteOrphanInventory, batchDeleteOrphanInventory, getOrphanExportUrl, queryOrphanCount } from './inventory.api';
  import InventoryLedgerSubTable from './InventoryLedgerSubTable.vue';
  import { message, Modal } from 'ant-design-vue';

  defineOptions({ name: 'MesInventoryOverview' });

  const pageTotalAmount = ref('0.00');
  const orphanCount = ref(0);
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增 imports-----------

  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】rowSelection reactive 模式（黄金模板 1:1 对齐）-----------
  const selectedRowKeys = reactive<string[]>([]);
  const selectedRows = reactive<Recordable[]>([]);

  const rowSelection = {
    type: 'checkbox' as const,
    columnWidth: 50,
    selectedRowKeys,
    onChange(keys: string[], rows: Recordable[]) {
      selectedRowKeys.length = 0;
      selectedRowKeys.push(...keys);
      selectedRows.length = 0;
      selectedRows.push(...rows);
    },
  };
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】rowSelection reactive 模式-----------

  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】isOrphan + orphanReason（material + warehouse 双维度 + status 字段）-----------
  function isOrphan(record: Recordable): boolean {
    return !record.material_code || !record.warehouse_name;
  }

  function orphanReason(record: Recordable): string {
    const reasons: string[] = [];
    if (!record.material_code) reasons.push('物料已删除');
    if (!record.warehouse_name) reasons.push('仓库已删除');
    return reasons.length ? reasons.join(' / ') : '';
  }

  function orphanColor(record: Recordable): string {
    if (!record.material_code && !record.warehouse_name) return 'red';
    return 'default';
  }
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】isOrphan + orphanReason-----------

  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】选中行中孤儿行 ID 列表（computed）-----------
  const selectedOrphanKeys = computed(() =>
    selectedRows.filter((r) => r.isOrphan === '1').map((r) => r.id)
  );
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】选中行中孤儿行 ID 列表-----------

  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】单行删除 action + popConfirm 确认（按 status === '1' 显隐）-----------
  function getActions(record: Recordable) {
    if (record.isOrphan !== '1') return [];
    return [{
      label: '删除',
      popConfirm: {
        title: `确认删除该孤儿行？\n原因：${orphanReason(record)}\nID：${record.id}`,
        confirm: () => handleDeleteOne(record),
      },
    }];
  }

  async function handleDeleteOne(record: Recordable) {
    await deleteOrphanInventory({ id: record.id });
    message.success('已删除');
    reload();
    refreshOrphanCount();
  }
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】单行删除 action + popConfirm 确认-----------

  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删除（Modal.confirm + POST + body）-----------
  async function batchDeleteOrphan() {
    if (!selectedOrphanKeys.value.length) return;
    Modal.confirm({
      title: `确认删除 ${selectedOrphanKeys.value.length} 条孤儿行？`,
      content: '后端会写审计表，可通过 SQL rollback 命令恢复。',
      okText: '确认删除',
      okButtonProps: { danger: true },
      onOk: async () => {
        await batchDeleteOrphanInventory({ ids: selectedOrphanKeys.value });
        message.success(`已删除 ${selectedOrphanKeys.value.length} 条`);
        selectedRowKeys.length = 0;
        selectedRows.length = 0;
        reload();
        refreshOrphanCount();
      },
    });
  }

  function exportOrphanXls() {
    window.open(getOrphanExportUrl());
  }
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】批量删除 + 导出孤儿清单-----------

  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】refreshOrphanCount（前端 orphanCount 状态）-----------
  async function refreshOrphanCount() {
    try {
      const res: any = await queryOrphanCount();
      orphanCount.value = Number(res?.result || 0);
    } catch (e) { /* 静默失败，不阻塞 */ }
  }
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】refreshOrphanCount-----------

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

  const [registerTable, { reload }] = tableContext;

  onMounted(async () => {
    // 库存金额合计（前200条粗算；全量精确汇总留后端汇总接口，V3候选）
    try {
      const res: any = await queryInventoryList({ pageNo: 1, pageSize: 200 });
      const total = (res?.records || []).reduce((s: number, r: any) => s + Number(r.inventory_amount || 0), 0);
      pageTotalAmount.value = total.toFixed(2);
    } catch (e) { /* 合计失败不阻塞 */ }
    // 孤儿行总数（用于导出按钮 + 业务感知）
    refreshOrphanCount();
  });
</script>
