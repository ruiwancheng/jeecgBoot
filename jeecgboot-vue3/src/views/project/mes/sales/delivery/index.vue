<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable" :rowSelection="rowSelection">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增发货单</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
        <!--update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转----------->
        <a-divider type="vertical" />
        <a-button type="primary" :disabled="allStatus != '1'" @click="batchSubmit">提交</a-button>
        <a-button danger :disabled="allStatus != '1'" @click="batchCancel">取消</a-button>
        <a-button type="primary" :disabled="allStatus != '3'" @click="batchSign">签收</a-button>
        <!--update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转----------->
      </template>
      <!--update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】statusTag槽位（阶段颜色）----------->
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('delivery', record.status)">{{ record.status_dictText || (record.status === '2' ? '待出库' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <DeliveryDrawer @register="registerDrawer" @success="reload" />
  </div>
</template>

<script lang="ts" setup>
  import { computed, reactive } from 'vue';
  import { useRouter } from 'vue-router';
  import { BasicTable, useTable, TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './delivery.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryDeliveryList, deleteDelivery, submitDelivery, signDelivery, cancelDelivery, getExportUrl } from './delivery.api';
  import DeliveryDrawer from './DeliveryDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesSalesDelivery' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  //update-begin---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------
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
  //update-end---author:ruiwancheng---date:2026-07-18---for: Phase2 批量状态流转-----------

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-delivery',
    tableProps: {
      title: '发货单',
      api: queryDeliveryList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '发货单', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    const acts: any[] = [];
    if (record.status == '1') {
      acts.push({ label: '编辑', onClick: () => handleEdit(record) });
      acts.push({ label: '删除', popConfirm: { title: '确认删除？', confirm: () => handleDelete(record) } });
    }
    //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】发货单→出库跳转（保留）-----------
    // 跨页面跳转：查看本发货单下游的销售出库
    acts.push({ label: '查看出库', onClick: () => router.push({ path: '/project/mes/sales/outbound', query: { deliveryNoteId: record.id } }) });
    //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】发货单跳转按钮-----------
    return acts;
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }
  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }
  async function handleDelete(record: Recordable) {
    await deleteDelivery({ id: record.id });
    message.success('删除成功');
    reload();
  }
  //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】router实例化（跳转按钮使用）-----------
  const router = useRouter();
  //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】router实例化-----------
  async function batchSubmit() {
    for (const r of selectedRows) {
      await submitDelivery({ id: r.id });
    }
    message.success(`已提交${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  async function batchSign() {
    for (const r of selectedRows) {
      await signDelivery({ id: r.id });
    }
    message.success(`已签收${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
  async function batchCancel() {
    for (const r of selectedRows) {
      await cancelDelivery({ id: r.id });
    }
    message.success(`已取消${selectedRowKeys.length}条`);
    selectedRowKeys.length = 0;
    selectedRows.length = 0;
    reload();
  }
</script>
