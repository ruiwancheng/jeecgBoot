<template>
  <a-modal
    :visible="visible"
    title="选择物料"
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
      :rowClassName="(r: any) => selectedRow?.id === r.id ? 'ant-table-row-selected' : ''"
      @change="handleTableChange"
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'action'">
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

    <!-- 已选预览 + 确认 -->
    <div style="margin-top: 12px; padding: 10px; background: #f5f5f5; border-radius: 4px; display: flex; align-items: center; justify-content: space-between">
      <span v-if="selectedRow">
        已选：<strong>{{ selectedRow.code }}</strong> — {{ selectedRow.name }}
        <span v-if="selectedRow.spec" style="color: #888; margin-left: 8px">{{ selectedRow.spec }}</span>
      </span>
      <span v-else style="color: #999">请点击表格中的"选择"按钮，或点击行选中物料</span>
      <a-button type="primary" :disabled="!selectedRow" @click="handleConfirm">确认</a-button>
    </div>
  </a-modal>
</template>

<script lang="ts" setup>
  import { ref, reactive, watch } from 'vue';
  import { selectMaterialPage } from './material.api';

  const props = defineProps<{ visible: boolean }>();
  const emit = defineEmits(['update:visible', 'select']);

  const searchKeyword = ref('');
  const selectedRow = ref<any>(null);
  const dataSource = ref<any[]>([]);
  const loading = ref(false);

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
    { title: '操作', dataIndex: 'action', width: 80 },
  ];

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
    fetchData();
  }

  function handleTableChange(pag: any) {
    pagination.current = pag.current;
    pagination.pageSize = pag.pageSize;
    fetchData();
  }

  function handleSelect(record: any) {
    if (selectedRow.value?.id === record.id) {
      selectedRow.value = null;
    } else {
      selectedRow.value = record;
    }
  }

  function handleConfirm() {
    if (selectedRow.value) {
      emit('select', selectedRow.value);
      selectedRow.value = null;
      emit('update:visible', false);
    }
  }

  function handleCancel() {
    selectedRow.value = null;
    emit('update:visible', false);
  }

  watch(() => props.visible, (val) => {
    if (val) {
      searchKeyword.value = '';
      selectedRow.value = null;
      pagination.current = 1;
      fetchData();
    }
  });
</script>
