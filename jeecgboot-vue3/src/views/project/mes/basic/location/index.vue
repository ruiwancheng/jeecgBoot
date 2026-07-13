<template>
  <a-row :gutter="16">
    <a-col :xl="6" :lg="6" :md="8" :sm="24" style="margin-bottom: 10px">
      <a-card title="仓库结构" size="small" :bodyStyle="{ padding: '8px' }">
        <template #extra>
          <a-space :size="4">
            <a-tooltip title="新增库区">
              <a-button size="small" type="text" @click="handleAddZone" :disabled="!canAddZone">
                <template #icon><Icon icon="ant-design:plus-circle-outlined" /></template>
              </a-button>
            </a-tooltip>
            <a-tooltip title="新增货架">
              <a-button size="small" type="text" @click="handleAddShelf" :disabled="!canAddShelf">
                <template #icon><Icon icon="ant-design:block-outlined" /></template>
              </a-button>
            </a-tooltip>
            <a-tooltip title="编辑节点">
              <a-button size="small" type="text" @click="handleEditNode" :disabled="!selectedNode">
                <template #icon><Icon icon="ant-design:edit-outlined" /></template>
              </a-button>
            </a-tooltip>
            <a-tooltip title="删除节点">
              <a-popconfirm title="确认删除？子节点需先删除" @confirm="handleDeleteNode" :disabled="!selectedNode">
                <a-button size="small" type="text" :disabled="!selectedNode" danger>
                  <template #icon><Icon icon="ant-design:delete-outlined" /></template>
                </a-button>
              </a-popconfirm>
            </a-tooltip>
          </a-space>
        </template>
        <a-spin :spinning="treeLoading">
          <a-tree
            :tree-data="treeData"
            :field-names="{ key: 'id', title: 'name' }"
            :load-data="onLoadData"
            :selected-keys="selectedKeys"
            show-icon
            @select="onTreeSelect"
            style="max-height: 650px; overflow: auto"
          >
            <template #icon="{ dataRef }">
              <Icon v-if="dataRef.nodeType === 'warehouse'" icon="ant-design:home-filled" style="color: #1890ff" />
              <Icon v-else-if="dataRef.nodeType === 'zone'" icon="ant-design:block-outlined" style="color: #52c41a" />
              <Icon v-else-if="dataRef.nodeType === 'shelf'" icon="ant-design:gold-outlined" style="color: #faad14" />
            </template>
          </a-tree>
        </a-spin>
      </a-card>
    </a-col>

    <a-col :xl="18" :lg="18" :md="16" :sm="24">
      <BasicTable @register="registerTable">
        <template #tableTitle>
          <a-space>
            <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAddLocation" :disabled="!selectedShelfId">
              新增库位
            </a-button>
            <a-button type="primary" preIcon="ant-design:thunderbolt-outlined" @click="handleGenerate" :disabled="!selectedShelfId">
              批量生成
            </a-button>
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
  <ZoneDrawer @register="registerZoneDrawer" @success="handleZoneSaved" />
  <ShelfDrawer @register="registerShelfDrawer" @success="handleShelfSaved" />
  <GenerateLocation @register="registerGenModal" @success="reload" />
</template>

<script lang="ts" setup>
  import { ref, unref, onMounted, computed } from 'vue';
  import { BasicTable } from '/@/components/Table';
  import { TableAction } from '/@/components/Table';
  import { useListPage } from '/@/hooks/system/useListPage';
  import { useModal } from '/@/components/Modal';
  import { useDrawer } from '/@/components/Drawer';
  import { message } from 'ant-design-vue';
  import { Icon } from '/@/components/Icon';
  import { columns, searchFormSchema } from './location.data';
  import { queryLocationList, deleteLocation, getExportUrl, getImportUrl, queryZoneTree, queryShelfTree, deleteZone, deleteShelf } from './location.api';
  import { queryAllWarehouse } from '../warehouse/warehouse.api';
  import LocationDrawer from './LocationDrawer.vue';
  import ZoneDrawer from './ZoneDrawer.vue';
  import ShelfDrawer from './ShelfDrawer.vue';
  import GenerateLocation from './GenerateLocation.vue';

  defineOptions({ name: 'MesLocation' });

  interface TreeNode {
    id: string;
    name: string;
    nodeType: 'warehouse' | 'zone' | 'shelf';
    parentId?: string;
    warehouseId?: string;
    zoneId?: string;
    isLeaf: boolean;
    children?: TreeNode[];
  }

  const treeData = ref<TreeNode[]>([]);
  const treeLoading = ref(false);
  const selectedKeys = ref<string[]>([]);
  const selectedNode = ref<TreeNode | null>(null);
  const selectedWarehouseId = ref('');
  const selectedZoneId = ref('');
  const selectedShelfId = ref('');

  const canAddZone = computed(() => selectedNode.value?.nodeType === 'warehouse' || (selectedNode.value && selectedNode.value.nodeType === 'warehouse'));
  const canAddShelf = computed(() => selectedNode.value?.nodeType === 'zone');
  const hasWarehouseSelection = computed(() => !!selectedNode.value);

  const [registerDrawer, { openDrawer }] = useDrawer();
  const [registerZoneDrawer, { openDrawer: openZoneDrawer }] = useDrawer();
  const [registerShelfDrawer, { openDrawer: openShelfDrawer }] = useDrawer();
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
        if (unref(selectedWarehouseId)) params.warehouseId = unref(selectedWarehouseId);
        if (unref(selectedZoneId)) params.zoneId = unref(selectedZoneId);
        if (unref(selectedShelfId)) params.shelfId = unref(selectedShelfId);
      },
    },
    exportConfig: { name: '库位管理', url: getExportUrl },
    importConfig: { url: getImportUrl },
  });

  const [registerTable, { reload }] = tableContext;

  onMounted(loadWarehouseTree);

  async function loadWarehouseTree() {
    treeLoading.value = true;
    try {
      const res = await queryAllWarehouse();
      const list = (res as any)?.result || (res as any)?.records || res || [];
      treeData.value = list.map((w: any) => ({
        id: w.id,
        name: w.name,
        nodeType: 'warehouse' as const,
        isLeaf: false,
      }));
    } finally {
      treeLoading.value = false;
    }
  }

  async function onLoadData(treeNode: any) {
    const { dataRef } = treeNode;
    if (!dataRef || dataRef.children) return;

    treeLoading.value = true;
    try {
      if (dataRef.nodeType === 'warehouse') {
        const res = await queryZoneTree(dataRef.id);
        const list = (res as any)?.result || (res as any)?.records || res || [];
        dataRef.children = list.map((z: any) => ({
          id: z.id,
          name: z.name || z.code,
          nodeType: 'zone' as const,
          parentId: dataRef.id,
          warehouseId: dataRef.id,
          isLeaf: false,
        }));
        treeData.value = [...treeData.value];
      } else if (dataRef.nodeType === 'zone') {
        const res = await queryShelfTree(dataRef.id);
        const list = (res as any)?.result || (res as any)?.records || res || [];
        dataRef.children = list.map((s: any) => ({
          id: s.id,
          name: s.name || s.code,
          nodeType: 'shelf' as const,
          parentId: dataRef.id,
          warehouseId: dataRef.warehouseId,
          zoneId: dataRef.id,
          isLeaf: true,
        }));
        treeData.value = [...treeData.value];
      }
    } finally {
      treeLoading.value = false;
    }

    return Promise.resolve();
  }

  function onTreeSelect(keys: string[], info: any) {
    if (keys.length === 0) {
      selectedKeys.value = [];
      selectedNode.value = null;
      selectedWarehouseId.value = '';
      selectedZoneId.value = '';
      selectedShelfId.value = '';
    } else {
      selectedKeys.value = keys;
      const node = info.node?.dataRef as TreeNode;
      selectedNode.value = node;
      selectedWarehouseId.value = node.nodeType === 'warehouse' ? node.id : (node.warehouseId || '');
      selectedZoneId.value = node.nodeType === 'zone' ? node.id : (node.zoneId || '');
      selectedShelfId.value = node.nodeType === 'shelf' ? node.id : '';
    }
    reload();
  }

  function refreshCurrentNode() {
    const node = unref(selectedNode);
    if (!node) return;
    // Clear children to force reload
    const parentList = node.nodeType === 'warehouse' ? treeData.value : [];
    // Simple: reload the whole tree and re-expand
    loadWarehouseTree().then(() => {
      selectedKeys.value = [];
      selectedNode.value = null;
      selectedWarehouseId.value = '';
      selectedZoneId.value = '';
      selectedShelfId.value = '';
      reload();
    });
  }

  function findNodeById(nodes: TreeNode[], id: string): TreeNode | null {
    for (const n of nodes) {
      if (n.id === id) return n;
      if (n.children) {
        const found = findNodeById(n.children, id);
        if (found) return found;
      }
    }
    return null;
  }

  // Zone operations
  function handleAddZone() {
    const node = unref(selectedNode);
    const whId = node?.nodeType === 'warehouse' ? node.id : node?.warehouseId || '';
    openZoneDrawer(true, { isUpdate: false, warehouseId: whId });
  }

  function handleZoneSaved() {
    const node = unref(selectedNode);
    if (node?.nodeType === 'warehouse') {
      node.children = undefined; // Force lazy reload
    }
    refreshCurrentNode();
  }

  // Shelf operations
  function handleAddShelf() {
    const node = unref(selectedNode);
    if (node?.nodeType !== 'zone') return;
    openShelfDrawer(true, { isUpdate: false, zoneId: node.id, warehouseId: node.warehouseId || '' });
  }

  function handleShelfSaved() {
    const node = unref(selectedNode);
    if (node?.nodeType === 'zone') {
      node.children = undefined;
    }
    refreshCurrentNode();
  }

  // Edit node
  function handleEditNode() {
    const node = unref(selectedNode);
    if (!node) return;
    if (node.nodeType === 'warehouse') {
      // Navigate to warehouse page or inline edit
      message.info('请在仓库管理页面编辑仓库');
      return;
    }
    if (node.nodeType === 'zone') {
      openZoneDrawer(true, { isUpdate: true, record: { id: node.id, code: node.name, warehouseId: node.warehouseId || node.parentId } });
      return;
    }
    if (node.nodeType === 'shelf') {
      openShelfDrawer(true, { isUpdate: true, record: { id: node.id, code: node.name, zoneId: node.parentId, warehouseId: node.warehouseId } });
      return;
    }
  }

  // Delete node
  async function handleDeleteNode() {
    const node = unref(selectedNode);
    if (!node) return;
    try {
      if (node.nodeType === 'zone') {
        await deleteZone({ id: node.id });
      } else if (node.nodeType === 'shelf') {
        await deleteShelf({ id: node.id });
      } else {
        message.warning('请在仓库管理页面删除仓库');
        return;
      }
      message.success('删除成功');
      refreshCurrentNode();
    } catch (e: any) {
      message.error(e?.message || '删除失败');
    }
  }

  // Location operations
  function handleAddLocation() {
    const shelfId = unref(selectedShelfId);
    if (!shelfId) { message.warning('请先在左侧树中选择一个货架'); return; }
    const node = unref(selectedNode);
    openDrawer(true, {
      isUpdate: false,
      shelfId,
      zoneId: node?.zoneId || '',
      warehouseId: node?.warehouseId || '',
    });
  }

  function handleGenerate() {
    const shelfId = unref(selectedShelfId);
    if (!shelfId) { message.warning('请先在左侧树中选择一个货架'); return; }
    openGenModal(true, { shelfId });
  }

  function getActions(record: Recordable) {
    return [
      { label: '编辑', onClick: () => openDrawer(true, { record, isUpdate: true }) },
      {
        label: '删除',
        popConfirm: { title: '确认删除该库位吗？', confirm: () => handleDelete(record) },
      },
    ];
  }

  async function handleDelete(record: Recordable) {
    await deleteLocation({ id: record.id });
    message.success('删除成功');
    reload();
  }
</script>
