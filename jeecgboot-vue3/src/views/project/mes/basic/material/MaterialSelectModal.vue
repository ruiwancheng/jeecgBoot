<template>
  <a-modal
    :visible="visible"
    :title="mode === 'multiple' ? '批量选择物料' : '选择物料'"
    width="900px"
    :footer="null"
    :destroyOnClose="true"
    @cancel="handleCancel"
  >
    <!-- 搜索区 -->
    <div style="margin-bottom: 12px; display: flex; gap: 8px; flex-wrap: wrap">
      <a-input
        v-model:value="searchKeyword"
        placeholder="搜索编码/名称/规格"
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
      :rowSelection="mode === 'multiple' ? rowSelectionConfig : undefined"
      :rowClassName="(r: any) => mode === 'single' && selectedRow?.id === r.id ? 'ant-table-row-selected' : ''"
      @change="handleTableChange"
      @rowClick="handleRowClick"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'action' && mode === 'single'">
          <a-button
            :type="selectedRow?.id === record.id ? 'primary' : 'default'"
            size="small"
            @click="handleSelect(record)"
          >
            {{ selectedRow?.id === record.id ? '已选' : '选择' }}
          </a-button>
        </template>
      </template>
    </a-table>

    <!-- 底部：已选预览 + 确认 -->
    <div style="margin-top: 12px; padding: 10px; background: #f5f5f5; border-radius: 4px; display: flex; align-items: center; justify-content: space-between">
      <!-- 多选模式 -->
      <span v-if="mode === 'multiple'">
        已选：<strong>{{ selectedRows.length }}</strong> 项
        <span v-if="selectedRows.length > 0" style="margin-left: 8px; color: #666">
          {{ selectedRows.slice(0, 3).map(r => r.code).join(', ') }}
          <template v-if="selectedRows.length > 3">等</template>
        </span>
      </span>
      <!-- 单选模式 -->
      <span v-else>
        <template v-if="selectedRow">
          已选：<strong>{{ selectedRow.code }}</strong> — {{ selectedRow.name }}
          <span v-if="selectedRow.spec" style="color: #888; margin-left: 8px">{{ selectedRow.spec }}</span>
        </template>
        <span v-else style="color: #999">请点击表格中的"选择"按钮，或点击行选中物料</span>
      </span>
      <a-button type="primary" :disabled="mode === 'single' ? !selectedRow : selectedRows.length === 0" @click="handleConfirm">确认</a-button>
    </div>
  </a-modal>
</template>

<script lang="ts" setup>
  import { ref, reactive, watch, computed } from 'vue';
  import type { TableRowSelection } from 'ant-design-vue/es/table';
  import { selectMaterialPage } from './material.api';

  const props = defineProps<{
    visible: boolean;
    mode?: 'single' | 'multiple';
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
    { title: '物料编码', dataIndex: 'code', width: 140 },
    { title: '物料名称', dataIndex: 'name', width: 180 },
    { title: '类型', dataIndex: 'type_dictText', width: 100 },
    { title: '规格型号', dataIndex: 'spec', width: 120 },
    { title: '单位', dataIndex: 'unit_dictText', width: 80 },
    ...(props.mode === 'single' ? [{ title: '操作', dataIndex: 'action', width: 80 }] : []),
  ];

  const rowSelectionConfig = computed<TableRowSelection>(() => ({
    selectedRowKeys: selectedRowKeys.value,
    onChange: (keys: any[], rows: any[]) => {
      selectedRowKeys.value = keys as string[];
      selectedRows.value = rows;
    },
    preserveSelectedRowKeys: true,
  }));

  async function fetchData() {
    loading.value = true;
    try {
      const res = await selectMaterialPage({
        keyword: searchKeyword.value || undefined,
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

  function handleRowClick(record: any) {
    if (currentMode.value === 'single') {
      handleSelect(record);
    }
  }

  function handleSelect(record: any) {
    if (selectedRow.value?.id === record.id) {
      selectedRow.value = null;
    } else {
      selectedRow.value = record;
    }
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
