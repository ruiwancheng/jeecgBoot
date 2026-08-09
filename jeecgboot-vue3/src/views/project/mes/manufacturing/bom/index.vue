<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <!--update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式2复选框 rowSelection + 模式3展开子表----------->
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #expandedRowRender="{ record }">
        <BomItemsSubTable :bomId="record.id" />
      </template>
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增BOM</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <a-divider type="vertical" />
        <!-- 模式 2：批量生效/失效（状态守卫：全选同状态才可用） -->
        <a-button type="primary" :disabled="allStatus != '1'" @click="batchApprove">批量生效</a-button>
        <a-button danger :disabled="allStatus != '2'" @click="batchDisable">批量失效</a-button>
      </template>
      <!--update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式2复选框 rowSelection + 模式3展开子表----------->
      <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位（阶段颜色）----------->
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('bom', record.status)">{{ record.status_dictText || (record.status === '2' ? '生效' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <BomDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式2复选框 imports（computed/reactive）-----------
  import { computed, reactive } from 'vue';
  //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式2复选框 imports（computed/reactive）-----------
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './bom.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryBomList, deleteBom, approveBom, disableBom, getExportUrl } from './bom.api';
  import BomDrawer from './BomDrawer.vue';
  //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式3展开子表 import-----------
  import BomItemsSubTable from './BomItemsSubTable.vue';
  //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式3展开子表 import-----------
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesBom' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式2复选框 + 批量状态守卫-----------
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

  const allStatus = computed(() => {
    if (!selectedRows.length) return '';
    const s = selectedRows[0].status;
    return selectedRows.every((r) => r.status === s) ? s : '';
  });
  //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式2复选框 + 批量状态守卫-----------

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-manufacturing-bom',
    tableProps: {
      title: 'BOM管理',
      api: queryBomList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: 'BOM', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】BOM状态机按钮（按 status 显隐）-----------
    const acts: any[] = [];
    // 草稿（status=1）→ 显示生效按钮
    if (record.status === '1') {
      acts.push({ label: '生效', popConfirm: { title: '确认生效该BOM吗？', confirm: () => handleApprove(record) } });
    }
    // 生效（status=2）→ 显示失效按钮
    if (record.status === '2') {
      acts.push({ label: '失效', popConfirm: { title: '确认失效该BOM吗？失效后不可被订单引用。', confirm: () => handleDisable(record) } });
    }
    // 草稿/失效（status=1/3）→ 允许编辑删除
    if (record.status === '1' || record.status === '3') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '删除', popConfirm: { title: '确认删除该BOM吗？', confirm: () => handleDelete(record) } });
    }
    //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】BOM状态机按钮-----------
    return acts;
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }
  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }
  async function handleDelete(record: Recordable) {
    await deleteBom({ id: record.id });
    message.success('删除成功');
    reload();
  }
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】BOM生效/失效处理器-----------
  async function handleApprove(record: Recordable) {
    await approveBom({ id: record.id });
    message.success('已生效');
    reload();
  }
  async function handleDisable(record: Recordable) {
    await disableBom({ id: record.id });
    message.success('已失效');
    reload();
  }
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】BOM生效/失效处理器-----------

  //update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式2批量生效/失效处理器-----------
  async function batchApprove() {
    for (const r of selectedRows) {
      await approveBom({ id: r.id });
    }
    message.success(`已生效${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  async function batchDisable() {
    for (const r of selectedRows) {
      await disableBom({ id: r.id });
    }
    message.success(`已失效${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  //update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】模式2批量生效/失效处理器-----------
</script>