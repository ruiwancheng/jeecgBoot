<template>
  <div style="display: flex; gap: 4px; align-items: center">
    <a-input
      :value="displayText"
      placeholder="点此选择物料"
      readonly
      style="flex: 1; cursor: pointer"
      @click="openModal"
    />
    <a-tooltip title="选择物料">
      <a-button size="small" @click="openModal">
        <template #icon><SearchOutlined /></template>
        选择
      </a-button>
    </a-tooltip>
    <a-tooltip v-if="modelValue" title="清除已选物料">
      <a-button size="small" danger @click="handleClear">
        <template #icon><CloseOutlined /></template>
        清除
      </a-button>
    </a-tooltip>
    <MaterialSelectModal
      :visible="modalVisible"
      @update:visible="modalVisible = $event"
      @select="handleSelect"
    />
  </div>
</template>

<script lang="ts" setup>
  import { ref, watch } from 'vue';
  import { SearchOutlined, CloseOutlined } from '@ant-design/icons-vue';
  import { Tooltip as ATooltip } from 'ant-design-vue';
  import { queryMaterialById } from './material.api';
  import MaterialSelectModal from './MaterialSelectModal.vue';

  const props = defineProps<{
    modelValue?: string;
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
      const material = await queryMaterialById({ id });
      if (material && material.code) {
        displayText.value = `${material.code} — ${material.name}`;
      }
    } catch {
      displayText.value = id;
    }
  }

  function openModal() {
    modalVisible.value = true;
  }

  function handleSelect(record: any) {
    displayText.value = `${record.code} — ${record.name}`;
    emit('update:modelValue', record.id);
    emit('change', { value: record.id, label: record.name });
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
