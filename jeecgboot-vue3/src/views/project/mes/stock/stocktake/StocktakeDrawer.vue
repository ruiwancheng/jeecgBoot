<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="1100px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <a-alert v-if="snapshotTime" type="info" show-icon style="margin-bottom:8px">
      <template #message>
        账面数为快照时点（{{ snapshotTime }}）的库存；审核差异以此为准
        <a-button type="link" size="small" :loading="refreshing" @click="handleRefresh">刷新账面数</a-button>
      </template>
    </a-alert>
    <a-divider>盘点明细</a-divider>
    <div v-if="!isUpdate && createTakeType === '1'" style="color:#888;margin-bottom:8px">全盘：保存后自动带出该仓全部库存物料明细，无需手工添加；保存后请在「录入实盘」中填写实盘数</div>
    <div style="margin-bottom:8px">
      <a-button type="dashed" preIcon="ant-design:plus-outlined" :disabled="isFullCreate" @click="addLine">添加行</a-button>
      <a-button type="dashed" preIcon="ant-design:appstore-add-outlined" style="margin-left:8px" :disabled="isFullCreate" @click="batchVisible = true">批量添加物料</a-button>
      <span v-if="isFullCreate" style="margin-left:8px;color:#bbb">全盘无需添加</span>
    </div>
    <a-table :dataSource="items" :columns="itemColumns" :pagination="false" size="small" rowKey="lineNo">
      <template #materialId="{ record, index }">
        <span v-if="isUpdate">{{ materialText(record) }}</span>
        <JMaterialSelect v-else v-model:modelValue="record.materialId" @change="(v:any) => onMaterialChange(index, v)" style="width:100%" />
      </template>
      <template #bookQty="{ record }">
        <span>{{ record.bookQty }}</span>
      </template>
      <template #actualQty="{ record, index }">
        <InputNumber :value="record.actualQty" :min="0" :step="1" style="width:100%" placeholder="填这里" @change="(v:number) => updateItem(index, 'actualQty', v)" />
      </template>
      <template #diffQty="{ record }">
        <span :style="{ color: calcDiff(record) !== '-' && Number(calcDiff(record)) !== 0 ? '#f5222d' : '#999', fontWeight: calcDiff(record) !== '-' && Number(calcDiff(record)) !== 0 ? 600 : 400 }">{{ calcDiff(record) }}</span>
      </template>
      <template #unitCost="{ record, index }">
        <InputNumber :value="record.unitCost" :min="0" :step="0.01" :precision="4" style="width:100%" placeholder="移动平均" @change="(v:number) => updateItem(index, 'unitCost', v)" />
      </template>
      <template #diffAmount="{ record }">
        <span>{{ calcDiffAmount(record) }}</span>
      </template>
      <template #action="{ index }">
        <a-button type="link" danger @click="removeLine(index)">删除</a-button>
      </template>
    </a-table>
    <MaterialSelectModal :visible="batchVisible" mode="multiple" @update:visible="batchVisible = $event" @select="onBatchMaterials" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { InputNumber, message } from 'ant-design-vue';
  import JMaterialSelect from '/@/views/project/mes/basic/material/JMaterialSelect.vue';
  import MaterialSelectModal from '/@/views/project/mes/basic/material/MaterialSelectModal.vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema, createTakeType } from './stocktake.data';
  import { saveOrUpdateStocktake, queryStocktakeById, refreshStocktakeItems } from './stocktake.api';
  import { queryInventoryList } from '/@/views/project/mes/basic/inventory/inventory.api';
  import { queryMaterialsByIds } from '/@/views/project/mes/basic/material/material.api';
  import { getNextCode } from '/@/views/project/mes/basic/codeRule/codeRule.api';
  import { MES_BIZ_CODE } from '/@/views/project/mes/basic/codeRule/bizCodeMap';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const takeType = ref('1');
  const snapshotTime = ref('');
  const items = ref<any[]>([]);
  const materialMap = ref<Record<string, any>>({});
  const currentWarehouseId = ref('');
  const currentDocId = ref('');
  const refreshing = ref(false);
  const itemColumns = [
    { title: '物料', dataIndex: 'materialId', slots: { customRender: 'materialId' }, width: 240 },
    { title: '账面数（快照）', dataIndex: 'bookQty', slots: { customRender: 'bookQty' }, width: 110 },
    { title: '实盘数（填这里）', dataIndex: 'actualQty', slots: { customRender: 'actualQty' }, width: 130 },
    { title: '差异', dataIndex: 'diffQty', slots: { customRender: 'diffQty' }, width: 90 },
    { title: '成本单价', dataIndex: 'unitCost', slots: { customRender: 'unitCost' }, width: 120 },
    { title: '差异金额', dataIndex: 'diffAmount', slots: { customRender: 'diffAmount' }, width: 100 },
    { title: '操作', slots: { customRender: 'action' }, width: 70 },
  ];

  const [registerForm, { resetFields, setFieldsValue, validate, getFieldsValue }] = useForm({ schemas: formSchema, showActionButtonGroup: false, labelWidth: 100 });
  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    items.value = [];
    snapshotTime.value = '';
    materialMap.value = {};
    currentDocId.value = '';
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    if (!unref(isUpdate)) {
      try { const nextCode = await getNextCode(MES_BIZ_CODE.STOCKTAKE); if (nextCode) await setFieldsValue({ code: nextCode }); } catch (e) { /* 手工输入 */ }
      takeType.value = '1';
    }
    if (unref(isUpdate) && data.record) {
      try {
        const o = await queryStocktakeById({ id: data.record.id });
        if (o) {
          await setFieldsValue(o);
          takeType.value = o.takeType || '1';
          snapshotTime.value = o.snapshotTime || '';
          currentWarehouseId.value = o.warehouseId || '';
          currentDocId.value = o.id;
          items.value = o.items || [];
          await loadMaterialMap();
        }
      } catch (e) {}
    }
  });
  const getTitle = computed(() => (unref(isUpdate) ? '编辑盘点单（录入实盘）' : '新增盘点单'));
  // 新建+全盘：禁用添加物料按钮（避免手工输入被快照覆盖，引导保存后到「录入实盘」填数）
  const isFullCreate = computed(() => !unref(isUpdate) && createTakeType.value === '1');

  function materialText(record: any) {
    const m = materialMap.value[record.materialId];
    if (m) return `${m.code} — ${m.name}`;
    return record.materialId_dictText || record.materialId || '-';
  }
  async function loadMaterialMap() {
    const ids = [...new Set(items.value.map((i) => i.materialId).filter(Boolean))] as string[];
    const materials = ids.length ? await queryMaterialsByIds(ids).catch(() => []) : [];
    const map: Record<string, any> = {};
    (materials || []).forEach((m: any) => { if (m?.id) map[m.id] = m; });
    materialMap.value = map;
  }

  async function handleRefresh() {
    if (!currentDocId.value) return;
    refreshing.value = true;
    try {
      await refreshStocktakeItems({ id: currentDocId.value });
      const o = await queryStocktakeById({ id: currentDocId.value });
      items.value = o.items || [];
      snapshotTime.value = o.snapshotTime || '';
      await loadMaterialMap();
      message.success('账面数已刷新为当前库存');
    } finally { refreshing.value = false; }
  }

  function updateItem(i: number, f: string, v: any) { items.value[i] = { ...items.value[i], [f]: v }; }
  function addLine() {
    const wh = getFieldsValue().warehouseId || currentWarehouseId.value;
    if (!wh) { message.warning('请先选择仓库'); return; }
    currentWarehouseId.value = wh;
    items.value.push({ materialId: '', bookQty: 0, actualQty: null, unitCost: 0 });
  }
  function removeLine(i: number) { items.value.splice(i, 1); }
  function calcDiff(r: any) {
    if (r.actualQty == null) return '-';
    return (Number(r.actualQty) - Number(r.bookQty)).toFixed(2).replace(/\.00$/, '');
  }
  function calcDiffAmount(r: any) {
    if (r.actualQty == null) return '-';
    return ((Number(r.actualQty) - Number(r.bookQty)) * (Number(r.unitCost) || 0)).toFixed(2);
  }

  // 选物料：预填移动平均成本 + 拉当前账面库存（抽盘/编辑加行时）
  async function onMaterialChange(i: number, v: any) {
    updateItem(i, 'materialId', v?.value ?? v);
    const cost = v?.record?.movingAvgCost;
    if (cost != null) updateItem(i, 'unitCost', cost);
    const wh = getFieldsValue().warehouseId || currentWarehouseId.value;
    const matId = v?.value;
    if (wh && matId) {
      try {
        const res: any = await queryInventoryList({ materialId: matId, warehouseId: wh, pageNo: 1, pageSize: 1 });
        const row = res?.records?.[0];
        updateItem(i, 'bookQty', row ? Number(row.current_qty) : 0);
      } catch (e) { updateItem(i, 'bookQty', 0); }
    }
  }

  // 模式 6：批量添加物料（一次拉全仓库存，客户端按物料过滤——避免 N+1 且杜绝参数被忽略）
  const batchVisible = ref(false);
  async function onBatchMaterials(materials: any[]) {
    const wh = getFieldsValue().warehouseId || currentWarehouseId.value;
    if (!wh) { message.warning('请先选择仓库'); return; }
    currentWarehouseId.value = wh;
    // 一次拉全仓库存建 map（/debug 修复：逐料调用被后端忽略 materialId 参数时全部拿到第一行）
    const invMap: Record<string, number> = {};
    try {
      const res: any = await queryInventoryList({ warehouseId: wh, pageNo: 1, pageSize: 500 });
      (res?.records || []).forEach((r: any) => { invMap[r.material_id] = Number(r.current_qty) || 0; });
    } catch (e) { /* 全为0 */ }
    for (const m of materials) {
      items.value.push({ materialId: m.id, bookQty: invMap[m.id] ?? 0, actualQty: null, unitCost: m.movingAvgCost ?? 0 });
      materialMap.value[m.id] = m;
    }
  }

  async function handleSubmit() {
    const v = await validate();
    takeType.value = v.takeType || '1';
    const payload: any = { ...v };
    if (unref(isUpdate) || takeType.value !== '1') {
      if (!items.value.length) { message.warning('请添加盘点明细行'); return; }
      for (const it of items.value) {
        if (!it.materialId) { message.warning('存在未选物料的行'); return; }
      }
      payload.items = items.value;
    }
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateStocktake(payload, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally { setDrawerProps({ confirmLoading: false }); }
  }
</script>
