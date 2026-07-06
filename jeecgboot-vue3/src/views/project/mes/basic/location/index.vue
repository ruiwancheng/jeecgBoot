<template>
  <a-row :gutter="16" style="max-height: 800px">
    <a-col :xl="6" :lg="6" :md="8" :sm="24" style="margin-bottom: 10px">
      <a-card title="仓库列表" size="small" :bodyStyle="{ padding: '12px' }">
        <a-input-search v-model:value="searchText" placeholder="搜索仓库" style="margin-bottom: 8px" @search="onSearch" />
        <a-spin :spinning="treeLoading">
          <a-tree
            :tree-data="treeData"
            :field-names="{ key: 'id', title: 'name' }"
            :filter-node-method="filterNode"
            @select="onTreeSelect"
            style="max-height: 650px; overflow: auto"
          />
        </a-spin>
      </a-card>
    </a-col>

    <a-col :xl="18" :lg="18" :md="16" :sm="24">
      <BasicTable @register="registerTable">
        <template #tableTitle>
          <a-space>
            <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增库位</a-button>
            <a-button type="primary" preIcon="ant-design:thunderbolt-outlined" @click="handleGenerate">批量生成</a-button>
            <a-button type="primary" preIcon="ant-design:export-outlined" @click="onExportXls">导出</a-button>
            <j-upload-button type="primary" preIcon="ant-design:import-outlined" @click="onImportXls">导入</j-upload-button>
          </a-space>
        </template>
        <template #action="{ record }">
          <TableAction :actions="getActions(record)" />
        </template>
      </BasicTable>
    </a-col>
  </a-row>

  <LocationDrawer @register="registerDrawer" @success="reload" />
  <GenerateLocation @register="registerGenModal" @success="reload" />
</template>

<script lang="ts" setup>
  import { ref, unref, onMounted } from 'vue';
  import { BasicTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useModal } from '/@/components/Modal';
  import { useDrawer } from '/@/components/Drawer';
  import { message } from 'ant-design-vue';
  import { columns, searchFormSchema } from './location.data';
  import { queryLocationList, deleteLocation, getExportUrl, getImportUrl } from './location.api';
  import { queryAllWarehouse } from '../warehouse/warehouse.api';
  import LocationDrawer from './LocationDrawer.vue';
  import GenerateLocation from './GenerateLocation.vue';

  defineOptions({ name: 'MesLocation' });

  const searchText = ref('');
  const treeData = ref<any[]>([]);
  const treeLoading = ref(false);
  const selectedWarehouseId = ref('');

  const [registerDrawer, { openDrawer }] = useDrawer();
  const [registerGenModal, { openModal: openGenModal }] = useModal();

  const { tableContext, onExportXls, onImportXls } = useListPage({
    designScope: 'mes-location',
    tableProps: {
      title: '库位管理',
      api: queryLocationList,
      columns: columns,
      rowKey: 'id',
      formConfig: { labelWidth: 120, schemas: searchFormSchema },
      beforeFetch: (params) => {
        if (unref(selectedWarehouseId)) {
          params.warehouseId = unref(selectedWarehouseId);
        }
      },
    },
    exportConfig: { name: '库位管理', url: getExportUrl },
    importConfig: { url: getImportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  onMounted(loadTree);

  async function loadTree() {
    treeLoading.value = true;
    try {
      const res = await queryAllWarehouse();
      const list = (res as any)?.result || (res as any)?.records || res || [];
      treeData.value = list.map((item: any) => ({
        id: item.id,
        name: item.name,
        isLeaf: true,
      }));
    } finally {
      treeLoading.value = false;
    }
  }

  function filterNode(keyword: string, node: any) {
    return node.name?.includes(keyword);
  }

  function onSearch() {
    loadTree();
  }

  function onTreeSelect(selectedKeys: string[], info: any) {
    if (selectedKeys.length > 0) {
      selectedWarehouseId.value = selectedKeys[0];
    } else {
      selectedWarehouseId.value = '';
    }
    reload();
  }

  function getActions(record: Recordable) {
    return [
      { label: '编辑', onClick: () => handleEdit(record) },
      {
        label: '删除',
        popConfirm: { title: '确认删除该库位吗？', confirm: () => handleDelete(record) },
      },
    ];
  }

  function handleAdd() {
    openDrawer(true, { isUpdate: false, warehouseId: unref(selectedWarehouseId) });
  }

  function handleGenerate() {
    if (!unref(selectedWarehouseId)) {
      message.warning('请先在左侧选择仓库');
      return;
    }
    openGenModal(true, { warehouseId: unref(selectedWarehouseId) });
  }

  function handleEdit(record: Recordable) {
    openDrawer(true, { record, isUpdate: true });
  }

  async function handleDelete(record: Recordable) {
    await deleteLocation({ id: record.id });
    message.success('删除成功');
    reload();
  }
</script>
