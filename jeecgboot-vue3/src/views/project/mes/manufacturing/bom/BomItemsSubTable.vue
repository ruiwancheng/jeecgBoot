<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<!-- 模式 3：主子表展开行 — 列表行展开后展示 BOM 子项明细（用量/损耗率/替代料） -->
<!-- 物料列走物料表 batch 查询（消 N+1），显示物料编码 -->
<template>
  <div style="padding: 4px 16px 8px 48px; background: #fafafa">
    <a-spin :spinning="loading">
      <a-table :dataSource="items" :columns="cols" :pagination="false" size="small" rowKey="lineNo">
        <template #bodyCell="{ column, record }">
          <template v-if="column.dataIndex === 'material'">
            <span>{{ materialCode(record) }}</span>
          </template>
          <template v-else-if="column.dataIndex === 'lossRate'">
            <!--update-begin---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】损耗率>50%红标高亮（模式9）----------->
            <span :style="(Number(record.lossRate) || 0) > 50 ? { color: '#ff4d4f', fontWeight: 'bold' } : {}">
              {{ record.lossRate ?? 0 }}%
            </span>
            <!--update-end---author:ruiwancheng---date:20260807---for:【vue-migrate黄金模板】损耗率>50%红标高亮----------->
          </template>
          <template v-else-if="column.dataIndex === 'isAlternative'">
            <a-tag :color="record.isAlternative === 1 ? 'blue' : 'default'" style="margin: 0">
              {{ record.isAlternative === 1 ? '是' : '否' }}
            </a-tag>
          </template>
        </template>
      </a-table>
      <div v-if="!loading && !items.length" style="color: #999; padding: 8px">该BOM暂无明细</div>
    </a-spin>
  </div>
</template>

<script lang="ts" setup>
  import { ref, onMounted } from 'vue';
  import { queryBomById } from './bom.api';
  //update-begin---author:ruiwancheng---date:20260808---for:【物料列编码显示】批量查物料表消 N+1-----------
  import { queryMaterialsByIds } from '../../basic/material/material.api';
  //update-end---author:ruiwancheng---date:20260808---for:【物料列编码显示】批量查物料表消 N+1-----------

  const props = defineProps<{ bomId: string }>();

  const loading = ref(false);
  const items = ref<any[]>([]);
  //update-begin---author:ruiwancheng---date:20260808---for:【物料列编码显示】materialMap 缓存（id → material 对象）-----------
  const materialMap = ref<Record<string, any>>({});
  //update-end---author:ruiwancheng---date:20260808---for:【物料列编码显示】materialMap 缓存-----------

  const cols = [
    { title: '行号', dataIndex: 'lineNo', width: 60 },
    { title: '物料', dataIndex: 'material', width: 200 },
    { title: '用量', dataIndex: 'quantity', width: 100 },
    { title: '损耗率(%)', dataIndex: 'lossRate', width: 110 },
    { title: '替代料', dataIndex: 'isAlternative', width: 80 },
  ];

  //update-begin---author:ruiwancheng---date:20260808---for:【物料列编码显示】materialCode 渲染函数（按黄金模版）-----------
  // 三级回退：materialMap.code → materialId_dictText → materialId → '-'
  function materialCode(record: any) {
    const m = materialMap.value[record.materialId];
    if (m?.code) return m.code;
    return record.materialId_dictText || record.materialId || '-';
  }
  //update-end---author:ruiwancheng---date:20260808---for:【物料列编码显示】materialCode 渲染函数-----------

  onMounted(async () => {
    loading.value = true;
    try {
      const bom = await queryBomById({ id: props.bomId });
      items.value = bom?.items || [];
      //update-begin---author:ruiwancheng---date:20260808---for:【物料列编码显示】批量拉取物料明细（消 N+1）-----------
      // 收集去重后的 materialId 列表 → 一次接口拉所有物料 → 建 map 供 materialCode() O(1) 查询
      const ids = [...new Set(items.value.map((i) => i.materialId).filter(Boolean))] as string[];
      const materials = ids.length ? await queryMaterialsByIds(ids).catch(() => []) : [];
      const map: Record<string, any> = {};
      (materials || []).forEach((m: any) => { if (m?.id) map[m.id] = m; });
      materialMap.value = map;
      //update-end---author:ruiwancheng---date:20260808---for:【物料列编码显示】批量拉取物料明细-----------
    } catch (e) {
      items.value = [];
    } finally {
      loading.value = false;
    }
  });
</script>