<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <div>
    <BasicTable @register="registerTable">
      <template #tableTitle>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增领料</a-button>
        <a-button type="primary" preIcon="ant-design:plus-circle-outlined" @click="openGenerateModal">补领</a-button>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
      </template>
      <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位（阶段颜色）----------->
      <template #statusTag="{ record }">
        <a-tag :color="getStatusColor('picking', record.status)">{{ record.status_dictText || (record.status === '2' ? '已审核' : '草稿') }}</a-tag>
      </template>
      <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】statusTag槽位----------->
      <template #action="{ record }">
        <TableAction :actions="getActions(record)" />
      </template>
    </BasicTable>
    <PickingDrawer @register="registerDrawer" @success="reload" />
    <!--update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】补领弹窗（选订单）----------->
    <a-modal
      v-model:visible="generateModalVisible"
      title="补领 - 选择订单"
      ok-text="生成补领单"
      cancel-text="取消"
      :confirmLoading="generateLoading"
      @ok="confirmGeneratePicking"
    >
      <a-form layout="vertical">
        <a-form-item label="选择生产订单" required>
          <a-select
            v-model:value="selectedOrderId"
            placeholder="请选择订单"
            show-search
            :filter-option="filterOrderOption"
            :loading="orderLoading"
            style="width: 100%"
          >
            <a-select-option v-for="o in orderList" :key="o.id" :value="o.id">
              {{ o.code }} - {{ o.productName_dictText || o.productName || '' }}（{{ o.status_dictText || o.status }}）
            </a-select-option>
          </a-select>
        </a-form-item>
      </a-form>
    </a-modal>
    <!--update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】补领弹窗----------->
  </div>
</template>

<script lang="ts" setup>
  import { ref } from 'vue';
  import { useRouter } from 'vue-router';
  import { BasicTable, useTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useDrawer } from '/@/components/Drawer';
  import { columns, searchFormSchema } from './picking.data';
  import { getStatusColor } from '../shared/statusColor';
  import { queryPickingList, deletePicking, generatePickingByOrder, getExportUrl } from './picking.api';
  import { queryOrderList } from '../order/order.api';
  import PickingDrawer from './PickingDrawer.vue';
  import { message } from 'ant-design-vue';

  defineOptions({ name: 'MesProductionPicking' });

  const [registerDrawer, { openDrawer }] = useDrawer();

  const { prefixCls, tableContext, onExportXls } = useListPage({
    designScope: 'mes-manufacturing-picking',
    tableProps: {
      title: '生产领料',
      api: queryPickingList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
    },
    exportConfig: { name: '生产领料', url: getExportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  function getActions(record: Recordable) {
    const acts: any[] = [
      { label: '编辑', onClick: () => handleEdit(record) },
      { label: '删除', popConfirm: { title: '确认删除该领料单吗？', confirm: () => handleDelete(record) } },
    ];
    //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】领料→订单跳转（保留）-----------
    // 跨页面跳转：查看本领料单上游的生产订单
    acts.push({ label: '查看订单', onClick: () => router.push({ path: '/project/mes/manufacturing/order', query: { orderId: record.id } }) });
    //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】领料跳转按钮-----------
    return acts;
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false });
  }
  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }
  async function handleDelete(record: Recordable) {
    await deletePicking({ id: record.id });
    message.success('删除成功');
    reload();
  }
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】router实例化（跳转按钮使用）-----------
  const router = useRouter();
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】router实例化-----------
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】补领弹窗逻辑-----------
  const generateModalVisible = ref(false);
  const generateLoading = ref(false);
  const orderLoading = ref(false);
  const orderList = ref<any[]>([]);
  const selectedOrderId = ref<string>('');

  function filterOrderOption(input: string, option: any) {
    return (option?.children?.toString?.() || '').toLowerCase().includes(input.toLowerCase());
  }

  async function openGenerateModal() {
    selectedOrderId.value = '';
    generateModalVisible.value = true;
    orderLoading.value = true;
    try {
      // 只取可下达的订单：状态 2/3/4（已审核/已下达/执行中）
      const res: any = await queryOrderList({ pageNo: 1, pageSize: 200, status: '2,3,4' });
      orderList.value = res?.records || res?.data?.records || [];
    } catch (e) {
      orderList.value = [];
    } finally {
      orderLoading.value = false;
    }
  }

  async function confirmGeneratePicking() {
    if (!selectedOrderId.value) {
      message.warning('请先选择订单');
      return;
    }
    generateLoading.value = true;
    try {
      await generatePickingByOrder({ orderId: selectedOrderId.value });
      message.success('补领单已生成');
      generateModalVisible.value = false;
      reload();
    } catch (e: any) {
      message.error(e?.message || '补领失败');
    } finally {
      generateLoading.value = false;
    }
  }
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】补领弹窗逻辑-----------
</script>
