<template>
  <div style="display: flex; gap: 4px; align-items: center">
    <a-input
      :value="displayText"
      placeholder="点击选择采购订单"
      readonly
      style="flex: 1; cursor: pointer"
      @click="openModal"
    />
    <a-button size="small" preIcon="ant-design:search-outlined" @click="openModal" />
    <a-button v-if="modelValue" size="small" danger preIcon="ant-design:close-outlined" @click="handleClear" />
    <PurchaseOrderSelectModal
      :visible="modalVisible"
      :status="status"
      @update:visible="modalVisible = $event"
      @select="handleSelect"
    />
  </div>
</template>

<script lang="ts" setup>
  import { ref, watch } from 'vue';
  import { queryOrderById } from './order.api';
  import PurchaseOrderSelectModal from './PurchaseOrderSelectModal.vue';

  const props = defineProps<{
    modelValue?: string;
    /** 过滤状态，如传 '3' 只查已确认的采购单 */
    status?: string;
  }>();

  const emit = defineEmits(['update:modelValue', 'change']);

  const modalVisible = ref(false);
  const displayText = ref('');

  async function loadDisplayText() {
    const id = props.modelValue;
    if (!id || id === '') {
      displayText.value = '';
      return;
    }
    try {
      const order = await queryOrderById({ id });
      if (order && order.code) {
        displayText.value = `${order.code} — ${order.supplierId_dictText || ''}`;
      }
    } catch {
      displayText.value = id;
    }
  }

  function openModal() {
    modalVisible.value = true;
  }

  function handleSelect(record: any) {
    displayText.value = `${record.code} — ${record.supplierId_dictText || ''}`;
    emit('update:modelValue', record.id);
    emit('change', { value: record.id, label: record.code, record });
  }

  function handleClear() {
    displayText.value = '';
    emit('update:modelValue', '');
    emit('change', { value: '', label: '' });
  }

  watch(() => props.modelValue, () => {
    loadDisplayText();
  }, { immediate: true });
</script>
