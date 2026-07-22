<template>
  <a-modal
    :visible="visible"
    title="选择采购订单"
    width="900px"
    :footer="null"
    :destroyOnClose="true"
    @cancel="handleCancel"
  >
    <!-- 搜索区 -->
    <div style="margin-bottom: 12px; display: flex; gap: 8px; flex-wrap: wrap">
      <a-input
        v-model:value="searchKeyword"
        placeholder="搜索订单编号/供应商"
        allowClear
        style="width: 260px"
        @pressEnter="handleSearch"
      />
      <a-button type="primary" @click="handleSearch">搜索</a-button>
      <a-button @click="handleReset">重置</a-button>
      <span style="margin-left: auto; line-height: 32px; color: #888">
        共 {{ pagination.total }} 条
      </span>
    </div>

    <!-- 数据表格 -->
    <a-table
      :columns="columns"
      :dataSource="dataSource"
      :pagination="pagination"
      :loading="loading"
      size="small"
      rowKey="id"
      :rowSelection="rowSelectionConfig"
      @change="handleTableChange"
    />

    <!-- 底部：已选预览 + 确认 -->
    <div style="margin-top: 12px; padding: 10px; background: #f5f5f5; border-radius: 4px; display: flex; align-items: center; justify-content: space-between">
      <span v-if="currentMode === 'multiple'">
        已选：<strong>{{ selectedRows.length }}</strong> 项
        <span v-if="selectedRows.length > 0" style="margin-left: 8px; color: #666">
          {{ selectedRows.slice(0, 3).map(r => r.code).join(', ') }}
          <template v-if="selectedRows.length > 3">等</template>
        </span>
      </span>
      <span v-else>
        <template v-if="selectedRow">
          已选：<strong>{{ selectedRow.code }}</strong> — {{ selectedRow.supplierId_dictText || '-' }}
          <span v-if="selectedRow.orderDate" style="color: #888; margin-left: 8px">{{ selectedRow.orderDate }}</span>
        </template>
        <span v-else style="color: #999">请点选采购订单</span>
      </span>
      <a-button type="primary" :disabled="currentMode === 'multiple' ? selectedRows.length === 0 : !selectedRow" @click="handleConfirm">确认</a-button>
    </div>
  </a-modal>
</template>

<script lang="ts" setup>
  import { ref, reactive, watch, computed } from 'vue';
  import type { TableRowSelection } from 'ant-design-vue/es/table';
  import { selectPurchaseOrderPage } from './order.api';

  const props = defineProps<{
    visible: boolean;
    mode?: 'single' | 'multiple';
    status?: string;
  }>();

  const emit = defineEmits(['update:visible', 'select']);

  const searchKeyword = ref('');
  const selectedRow = ref<any>(null);
  const selectedRows = ref<any[]>([]);
  const selectedRowKeys = ref<string[]>([]);
  const dataSource = ref<any[]>([]);
  const loading = ref(false);

  const currentMode = computed(() => props.mode || 'single');

  const pagination = reactive({
    current: 1,
    pageSize: 20,
    total: 0,
    showSizeChanger: true,
    showTotal: (total: number) => `共 ${total} 条`,
  });

  const columns = [
    { title: '订单编号', dataIndex: 'code', width: 160 },
    { title: '供应商', dataIndex: 'supplierId_dictText', width: 180 },
    { title: '订单日期', dataIndex: 'orderDate', width: 110 },
    { title: '交货日期', dataIndex: 'deliveryDate', width: 110 },
    { title: '状态', dataIndex: 'status_dictText', width: 80 },
    { title: '不含税金额', dataIndex: 'totalAmount', width: 110 },
  ];

  const rowSelectionConfig = computed<TableRowSelection>(() => {
    if (currentMode.value === 'single') {
      return {
        type: 'radio',
        selectedRowKeys: selectedRowKeys.value,
        onChange: (keys: any[], rows: any[]) => {
          selectedRowKeys.value = keys as string[];
          selectedRow.value = rows[0] || null;
        },
      };
    }
    return {
      type: 'checkbox',
      selectedRowKeys: selectedRowKeys.value,
      onChange: (keys: any[], rows: any[]) => {
        selectedRowKeys.value = keys as string[];
        selectedRows.value = rows;
      },
      preserveSelectedRowKeys: true,
    };
  });

  async function fetchData() {
    loading.value = true;
    try {
      const res = await selectPurchaseOrderPage({
        keyword: searchKeyword.value || undefined,
        status: props.status || undefined,
        pageNo: pagination.current,
        pageSize: pagination.pageSize,
      });
      dataSource.value = res.records || [];
      pagination.total = res.total || 0;
    } finally {
      loading.value = false;
    }
  }

  function handleSearch() {
    pagination.current = 1;
    selectedRow.value = null;
    selectedRows.value = [];
    fetchData();
  }

  function handleReset() {
    searchKeyword.value = '';
    pagination.current = 1;
    selectedRow.value = null;
    selectedRows.value = [];
    selectedRowKeys.value = [];
    fetchData();
  }

  function handleTableChange(pag: any) {
    pagination.current = pag.current;
    pagination.pageSize = pag.pageSize;
    fetchData();
  }

  function handleConfirm() {
    if (currentMode.value === 'multiple') {
      if (selectedRows.value.length > 0) {
        emit('select', selectedRows.value);
        selectedRows.value = [];
        selectedRowKeys.value = [];
        emit('update:visible', false);
      }
    } else {
      if (selectedRow.value) {
        emit('select', selectedRow.value);
        selectedRow.value = null;
        selectedRowKeys.value = [];
        emit('update:visible', false);
      }
    }
  }

  function handleCancel() {
    selectedRow.value = null;
    selectedRows.value = [];
    selectedRowKeys.value = [];
    emit('update:visible', false);
  }

  watch(() => props.visible, (val) => {
    if (val) {
      searchKeyword.value = '';
      selectedRow.value = null;
      selectedRows.value = [];
      selectedRowKeys.value = [];
      pagination.current = 1;
      fetchData();
    }
  });
</script>
