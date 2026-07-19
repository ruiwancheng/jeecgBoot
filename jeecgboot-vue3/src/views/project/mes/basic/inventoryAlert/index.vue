<template>
  <div>
    <a-alert message="库存预警" description="以下物料当前库存低于安全库存，请及时补货" type="warning" show-icon style="margin-bottom:16px" />
    <a-table :dataSource="data" :columns="columns" :pagination="false" rowKey="materialId" :loading="loading" size="small" bordered>
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'shortage'">
          <a-tag color="red">{{ record.shortage }}</a-tag>
        </template>
      </template>
    </a-table>
  </div>
</template>
<script lang="ts" setup>
  import { ref, onMounted } from 'vue'; import { queryInventoryAlerts } from './inventoryAlert.api';
  defineOptions({ name: 'MesInventoryAlert' });
  const columns = [
    { title: '物料编码', dataIndex: 'materialCode', width: 120 }, { title: '物料名称', dataIndex: 'materialName', width: 200 },
    { title: '当前库存', dataIndex: 'currentQty', width: 100 }, { title: '安全库存', dataIndex: 'safetyStock', width: 100 },
    { title: '最高库存', dataIndex: 'maxStock', width: 100 }, { title: '缺口', dataIndex: 'shortage', width: 100 },
  ];
  const data = ref([]); const loading = ref(false);
  onMounted(async () => { loading.value = true; const res = await queryInventoryAlerts(); data.value = res || []; loading.value = false; });
</script>
