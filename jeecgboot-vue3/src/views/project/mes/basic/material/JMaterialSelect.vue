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
    <a-button v-if="state" size="small" danger preIcon="ant-design:close-outlined" @click="handleClear" />
    <MaterialSelectModal
      :visible="modalVisible"
      @update:visible="modalVisible = $event"
      @select="handleSelect"
    />
  </div>
</template>

<script lang="ts" setup>
  import { ref, watch } from 'vue';
  import { useRuleFormItem } from '/@/hooks/component/useFormItem';
  import { queryMaterialById } from './material.api';
  import MaterialSelectModal from './MaterialSelectModal.vue';

  // P0 修复：原 prop=modelValue +  emit change with Object → BasicForm 拿到 Object，
  // 反序列化到 String 字段报 “Cannot deserialize value of type String from Object value”。
  // 改为 JeecgBoot 通用模式：prop=value + emit('change', id) + emit('update:value', id)，
  // 与 JTreeDict/JRangeTime/JCodeEditor 一致（见 componentMap.ts）。
  const props = defineProps<{
    value?: string;
    modelValue?: string;  // 兼容旧调用方（v-model:modelValue 表格场景）
  }>();

  const emit = defineEmits(['update:modelValue', 'update:value', 'change']);

  const [state] = useRuleFormItem(props, 'value', 'change', undefined);

  const modalVisible = ref(false);
  const displayText = ref('');

  // 从 props.modelValue / props.value 取 id（向后兼容表格的 v-model:modelValue 写法）
  const currentId = () => props.value ?? props.modelValue ?? '';

  async function loadDisplayText() {
    const id = currentId();
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
    const id = record.id;
    state.value = id; // useRuleFormItem 会同时触发 emit('change', id) + formItemContext.onFieldChange()
    // 额外发出 update:modelValue 兼容表格 v-model:modelValue
    emit('update:modelValue', id);
  }

  function handleClear() {
    displayText.value = '';
    state.value = '';
    emit('update:modelValue', '');
  }

  watch(() => currentId(), () => {
    loadDisplayText();
  }, { immediate: true });
</script>
