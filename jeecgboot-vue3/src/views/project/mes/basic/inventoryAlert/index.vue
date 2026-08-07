<template>
  <!--update-begin---author:pi---date:2026-08-07---for:库存预警页面新增搜索导出规则抽屉与级别筛选--->
  <div class="inventory-alert-page">
    <a-alert message="库存预警" description="以下物料当前库存低于安全库存，请及时补货" type="warning" show-icon style="margin-bottom: 16px" />

    <a-form :model="searchForm" layout="inline" class="inventory-alert-search" @submit.prevent="handleSearch">
      <a-form-item :label="searchLabels.materialCode">
        <a-input v-model:value="searchForm.materialCode" placeholder="请输入物料编码" allow-clear @pressEnter="handleSearch" />
      </a-form-item>
      <a-form-item :label="searchLabels.materialName">
        <a-input v-model:value="searchForm.materialName" placeholder="请输入物料名称" allow-clear @pressEnter="handleSearch" />
      </a-form-item>
      <a-form-item :label="searchLabels.warehouseId">
        <a-select
          v-model:value="searchForm.warehouseId"
          allow-clear
          show-search
          option-filter-prop="label"
          placeholder="请选择仓库"
          :options="warehouseOptions"
          style="width: 180px"
        />
      </a-form-item>
      <a-form-item :label="searchLabels.alertLevel">
        <a-select v-model:value="searchForm.alertLevel" allow-clear placeholder="请选择级别" :options="alertLevelOptions" style="width: 120px" />
      </a-form-item>
      <a-form-item>
        <a-space>
          <a-button type="primary" html-type="submit"><span>查询</span></a-button>
          <a-button @click="handleReset"><span>重置</span></a-button>
        </a-space>
      </a-form-item>
    </a-form>

    <div class="inventory-alert-toolbar">
      <a-space>
        <a-button type="primary" preIcon="ant-design:export-outlined" @click="handleExport">导出</a-button>
        <a-button type="primary" preIcon="ant-design:plus-outlined" @click="handleAdd">新增预警规则</a-button>
      </a-space>
    </div>

    <a-table
      :dataSource="filteredData"
      :columns="columns"
      :pagination="{ pageSize: 10, showSizeChanger: true }"
      :loading="loading"
      rowKey="materialId"
      size="small"
      bordered
    >
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'shortage'">
          <a-tag color="red">{{ record.shortage }}</a-tag>
        </template>
        <template v-else-if="column.dataIndex === 'alertLevel'">
          <a-tag :color="getLevelColor(record.alertLevel)">{{ getLevelLabel(record.alertLevel) }}</a-tag>
        </template>
        <template v-else-if="column.dataIndex === 'warehouseName'">
          <span>{{ record.warehouseName || '全部仓库' }}</span>
        </template>
      </template>
    </a-table>

    <a-drawer v-model:open="drawerOpen" title="新增预警规则" width="520" :destroyOnClose="true" @close="handleDrawerClose">
      <a-form :model="ruleForm" layout="vertical">
        <a-form-item :label="ruleLabels.materialId" required>
          <a-select
            v-model:value="ruleForm.materialId"
            show-search
            option-filter-prop="label"
            placeholder="请选择物料"
            :options="materialOptions"
            @change="handleMaterialChange"
          />
        </a-form-item>
        <a-form-item :label="ruleLabels.safetyStock" required>
          <a-input-number v-model:value="ruleForm.safetyStock" :min="0" :precision="4" style="width: 100%" placeholder="请输入安全库存" />
        </a-form-item>
        <a-form-item :label="ruleLabels.maxStock">
          <a-input-number v-model:value="ruleForm.maxStock" :min="0" :precision="4" style="width: 100%" placeholder="可选，需大于等于安全库存" />
        </a-form-item>
        <a-form-item :label="ruleLabels.alertLevel" required>
          <a-select v-model:value="ruleForm.alertLevel" :options="alertLevelOptions" placeholder="请选择预警级别" />
        </a-form-item>
        <a-alert type="info" show-icon message="保存后将同步更新物料的安全库存与最高库存阈值。" />
      </a-form>
      <template #footer>
        <a-space>
          <a-button @click="drawerOpen = false">取消</a-button>
          <a-button type="primary" :loading="savingRule" @click="handleSaveRule">保存</a-button>
        </a-space>
      </template>
    </a-drawer>
  </div>
  <!--update-end---author:pi---date:2026-08-07---for:库存预警页面新增搜索导出规则抽屉与级别筛选--->
</template>

<script lang="ts" setup>
  //update-begin---author:pi---date:2026-08-07---for:库存预警页面新增搜索导出规则抽屉与级别筛选---
  import { computed, onMounted, reactive, ref } from 'vue';
  import { message } from 'ant-design-vue';
  import { editMaterial, queryAllMaterial } from '../material/material.api';
  import { queryAllWarehouse } from '../warehouse/warehouse.api';
  import { queryInventoryAlerts } from './inventoryAlert.api';
  import {
    alertLevelOptions,
    columns,
    ruleFormSchema,
    searchFormSchema,
    type AlertLevel,
    type InventoryAlertRecord,
    type InventoryAlertRuleForm,
  } from './inventoryAlert.data';

  defineOptions({ name: 'MesInventoryAlert' });

  interface AlertSearchForm {
    materialCode: string;
    materialName: string;
    warehouseId?: string;
    alertLevel?: AlertLevel;
  }

  interface MaterialOption {
    id: string;
    code?: string;
    name?: string;
    safetyStock?: number | null;
    maxStock?: number | null;
  }

  interface WarehouseOption {
    id: string;
    code?: string;
    name?: string;
  }

  const RULE_LEVEL_STORAGE_KEY = 'mes:inventory-alert:level-rules';
  const loading = ref(false);
  const savingRule = ref(false);
  const drawerOpen = ref(false);
  const alertData = ref<InventoryAlertRecord[]>([]);
  const materials = ref<MaterialOption[]>([]);
  const warehouses = ref<WarehouseOption[]>([]);
  const ruleLevels = ref<Record<string, AlertLevel>>({});

  const createSearchForm = (): AlertSearchForm => ({ materialCode: '', materialName: '', warehouseId: undefined, alertLevel: undefined });
  const searchForm = reactive<AlertSearchForm>(createSearchForm());
  const appliedSearch = ref<AlertSearchForm>(createSearchForm());
  const ruleForm = reactive<InventoryAlertRuleForm>({ materialId: undefined, safetyStock: null, maxStock: null, alertLevel: 'medium' });

  function getSchemaLabel(schemas: any[], field: string): string {
    const schema = schemas.find((item) => item.field === field);
    return String(schema?.label || field);
  }

  const searchLabels = {
    materialCode: getSchemaLabel(searchFormSchema, 'materialCode'),
    materialName: getSchemaLabel(searchFormSchema, 'materialName'),
    warehouseId: getSchemaLabel(searchFormSchema, 'warehouseId'),
    alertLevel: getSchemaLabel(searchFormSchema, 'alertLevel'),
  };
  const ruleLabels = {
    materialId: getSchemaLabel(ruleFormSchema, 'materialId'),
    safetyStock: getSchemaLabel(ruleFormSchema, 'safetyStock'),
    maxStock: getSchemaLabel(ruleFormSchema, 'maxStock'),
    alertLevel: getSchemaLabel(ruleFormSchema, 'alertLevel'),
  };

  const warehouseOptions = computed(() =>
    warehouses.value.map((warehouse) => ({
      label: `${warehouse.code || ''}${warehouse.code ? ' - ' : ''}${warehouse.name || warehouse.id}`,
      value: warehouse.id,
    }))
  );

  const materialOptions = computed(() =>
    materials.value
      .filter((material) => material.id)
      .map((material) => ({
        label: `${material.code || material.id}${material.name ? ` - ${material.name}` : ''}`,
        value: material.id,
      }))
  );

  const filteredData = computed(() => {
    const filter = appliedSearch.value;
    return alertData.value.filter((record) => {
      const codeMatched = contains(record.materialCode, filter.materialCode);
      const nameMatched = contains(record.materialName, filter.materialName);
      const warehouseMatched = !filter.warehouseId || record.warehouseId === filter.warehouseId || record.warehouseName === filter.warehouseId;
      const levelMatched = !filter.alertLevel || record.alertLevel === filter.alertLevel;
      return codeMatched && nameMatched && warehouseMatched && levelMatched;
    });
  });

  function contains(value: unknown, keyword: string): boolean {
    return (
      !keyword ||
      String(value ?? '')
        .toLowerCase()
        .includes(keyword.toLowerCase())
    );
  }

  function getAlertLevel(record: any): AlertLevel {
    const storedLevel = record?.materialId ? ruleLevels.value[record.materialId] : undefined;
    if (storedLevel) return storedLevel;
    const currentQty = Number(record?.currentQty ?? 0);
    const safetyStock = Number(record?.safetyStock ?? 0);
    if (currentQty <= 0) return 'high';
    if (safetyStock > 0 && currentQty / safetyStock <= 0.5) return 'medium';
    return 'low';
  }

  function normalizeAlerts(result: any): InventoryAlertRecord[] {
    const records = Array.isArray(result) ? result : result?.records;
    if (!Array.isArray(records)) return [];
    return records.map((record: any) => ({
      ...record,
      currentQty: Number(record.currentQty ?? 0),
      safetyStock: Number(record.safetyStock ?? 0),
      maxStock: record.maxStock == null ? null : Number(record.maxStock),
      shortage: Number(record.shortage ?? 0),
      warehouseName: record.warehouseName || record.warehouseId || '全部仓库',
      alertLevel: getAlertLevel(record),
    }));
  }

  async function loadAlerts() {
    loading.value = true;
    try {
      alertData.value = normalizeAlerts(await queryInventoryAlerts());
    } catch {
      alertData.value = [];
      message.error('库存预警加载失败，请稍后重试');
    } finally {
      loading.value = false;
    }
  }

  async function loadMaterials() {
    try {
      const result = await queryAllMaterial();
      materials.value = Array.isArray(result) ? result : [];
    } catch {
      materials.value = [];
    }
  }

  async function loadWarehouses() {
    try {
      const result = await queryAllWarehouse();
      warehouses.value = Array.isArray(result) ? result : [];
    } catch {
      warehouses.value = [];
    }
  }

  function loadRuleLevels() {
    try {
      const saved = JSON.parse(localStorage.getItem(RULE_LEVEL_STORAGE_KEY) || '{}');
      if (saved && typeof saved === 'object') ruleLevels.value = saved;
    } catch {
      ruleLevels.value = {};
    }
  }

  function persistRuleLevels() {
    localStorage.setItem(RULE_LEVEL_STORAGE_KEY, JSON.stringify(ruleLevels.value));
  }

  function handleSearch() {
    appliedSearch.value = { ...searchForm, materialCode: searchForm.materialCode.trim(), materialName: searchForm.materialName.trim() };
  }

  function handleReset() {
    Object.assign(searchForm, createSearchForm());
    handleSearch();
  }

  function handleAdd() {
    Object.assign(ruleForm, { materialId: undefined, safetyStock: null, maxStock: null, alertLevel: 'medium' as AlertLevel });
    drawerOpen.value = true;
  }

  function handleMaterialChange(materialId?: string) {
    const material = materials.value.find((item) => item.id === materialId);
    if (!material) {
      ruleForm.safetyStock = null;
      ruleForm.maxStock = null;
      return;
    }
    ruleForm.safetyStock = material.safetyStock ?? null;
    ruleForm.maxStock = material.maxStock ?? null;
    ruleForm.alertLevel = ruleLevels.value[material.id] || 'medium';
  }

  async function handleSaveRule() {
    const materialId = ruleForm.materialId;
    const safetyStock = Number(ruleForm.safetyStock);
    const maxStock = ruleForm.maxStock == null ? null : Number(ruleForm.maxStock);
    if (!materialId) {
      message.warning('请选择物料');
      return;
    }
    if (!Number.isFinite(safetyStock) || safetyStock <= 0) {
      message.warning('安全库存必须大于 0');
      return;
    }
    if (maxStock !== null && (!Number.isFinite(maxStock) || maxStock < safetyStock)) {
      message.warning('最高库存必须大于等于安全库存');
      return;
    }

    savingRule.value = true;
    try {
      await editMaterial({ id: materialId, safetyStock, maxStock });
      ruleLevels.value = { ...ruleLevels.value, [materialId]: ruleForm.alertLevel };
      persistRuleLevels();
      await Promise.all([loadAlerts(), loadMaterials()]);
      drawerOpen.value = false;
      message.success('预警规则保存成功');
    } catch {
      message.error('预警规则保存失败，请稍后重试');
    } finally {
      savingRule.value = false;
    }
  }

  function handleDrawerClose() {
    Object.assign(ruleForm, { materialId: undefined, safetyStock: null, maxStock: null, alertLevel: 'medium' as AlertLevel });
  }

  function getLevelLabel(level: AlertLevel): string {
    return alertLevelOptions.find((item) => item.value === level)?.label || '低';
  }

  function getLevelColor(level: AlertLevel): string {
    if (level === 'high') return 'red';
    if (level === 'medium') return 'orange';
    return 'blue';
  }

  function escapeHtml(value: unknown): string {
    return String(value ?? '')
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function handleExport() {
    const headers = ['物料编码', '物料名称', '仓库', '当前库存', '安全库存', '最高库存', '缺口', '预警级别'];
    const rows = filteredData.value.map((record) => [
      record.materialCode,
      record.materialName,
      record.warehouseName || '全部仓库',
      record.currentQty,
      record.safetyStock,
      record.maxStock ?? '',
      record.shortage,
      getLevelLabel(record.alertLevel),
    ]);
    const table = `<table><thead><tr>${headers.map((header) => `<th>${escapeHtml(header)}</th>`).join('')}</tr></thead><tbody>${rows
      .map((row) => `<tr>${row.map((cell) => `<td>${escapeHtml(cell)}</td>`).join('')}</tr>`)
      .join('')}</tbody></table>`;
    const blob = new Blob([`\ufeff<html><meta charset="utf-8" />${table}</html>`], { type: 'application/vnd.ms-excel;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `库存预警-${new Date().toISOString().slice(0, 10)}.xls`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    window.setTimeout(() => URL.revokeObjectURL(url), 0);
    message.success(`已导出 ${rows.length} 条预警明细`);
  }

  onMounted(async () => {
    loadRuleLevels();
    await Promise.all([loadAlerts(), loadMaterials(), loadWarehouses()]);
  });
  //update-end---author:pi---date:2026-08-07---for:库存预警页面新增搜索导出规则抽屉与级别筛选---
</script>
