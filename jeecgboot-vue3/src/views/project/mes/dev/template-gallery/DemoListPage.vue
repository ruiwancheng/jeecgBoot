<template>
  <div>
    <h3>列表页模式（1/2/7/10）</h3>
    <BasicForm @register="registerForm" />
    <a-table :dataSource="rows" :columns="cols" :pagination="false" rowKey="code" :rowSelection="rowSelection" size="middle" style="margin-top:8px">
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'status'">
          <a-tag :color="record.status === '2' ? 'green' : 'orange'">{{ record.status === '2' ? '已审核' : '草稿' }}</a-tag>
        </template>
        <template v-else-if="column.dataIndex === 'action'">
          <!-- 模式 10：操作列按状态显隐 + popConfirm -->
          <template v-if="record.status === '1'">
            <a-button type="link" size="small">编辑</a-button>
            <a-popconfirm title="确认删除？"><a-button type="link" size="small" danger>删除</a-button></a-popconfirm>
          </template>
          <span v-else style="color:#bbb">（已审核不可操作）</span>
        </template>
      </template>
    </a-table>
    <div style="margin-top:12px">
      <!-- 模式 2/7：批量按钮状态守卫（选中全为草稿才可审核） -->
      <a-button type="primary" :disabled="allStatus != '1'" style="margin-right:8px">审核</a-button>
      <a-button danger :disabled="allStatus != '2'">反审核</a-button>
      <span style="margin-left:12px; color:#888">已选 {{ selectedRows.length }} 行（全草稿亮"审核"，全已审亮"反审核"）</span>
    </div>
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';

  // 模式 1：搜索区下拉（字典 + 仓库 ApiSelect，真实接口）
  const [registerForm] = useForm({
    schemas: [
      { field: 'code', label: '单号', component: 'Input', colProps: { span: 6 } },
      { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_other_stock_status' } },
      { field: 'warehouseId', label: '仓库', component: 'ApiSelect', colProps: { span: 6 }, componentProps: { api: queryWarehouseSelect } },
    ],
    labelWidth: 80,
    showActionButtonGroup: false,
  });

  const rows = [
    { code: 'DEMO-001', warehouse: '一号仓', total: 500, status: '1' },
    { code: 'DEMO-002', warehouse: '一号仓', total: 800, status: '1' },
    { code: 'DEMO-003', warehouse: '二号仓', total: 300, status: '2' },
  ];
  const cols = [
    { title: '单号', dataIndex: 'code', width: 160 },
    { title: '仓库', dataIndex: 'warehouse', width: 120 },
    { title: '总金额', dataIndex: 'total', width: 100 },
    { title: '状态', dataIndex: 'status', width: 90 },
    { title: '操作', dataIndex: 'action', width: 200 },
  ];

  // 模式 2：复选框 + 状态守卫
  const selectedRows = reactive<any[]>([]);
  const rowSelection = {
    type: 'checkbox' as const,
    onChange(_keys: string[], rs: any[]) { selectedRows.length = 0; selectedRows.push(...rs); },
  };
  const allStatus = computed(() => {
    if (!selectedRows.length) return '';
    const s = selectedRows[0].status;
    return selectedRows.every((r) => r.status === s) ? s : '';
  });
</script>
