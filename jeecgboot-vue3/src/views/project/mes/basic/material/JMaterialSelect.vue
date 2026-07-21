<template>
  <div style="display: flex; gap: 4px; align-items: center">
    <a-input
      :value="displayText"
      placeholder="点击选择物料"
      readonly
      style="flex: 1; cursor: pointer"
      @click="openModal"
    />
    <a-button size="small" preIcon="ant-design:search-outlined" @click="openModal" />
    <a-button v-if="modelValue" size="small" danger preIcon="ant-design:close-outlined" @click="handleClear" />
    <MaterialSelectModal
      :visible="modalVisible"
      @update:visible="modalVisible = $event"
      @select="handleSelect"
    />
  </div>
</template>

<script lang="ts" setup>
  import { ref, watch } from 'vue';
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
    emit('change', { value: record.id, label: record.name, record });
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
