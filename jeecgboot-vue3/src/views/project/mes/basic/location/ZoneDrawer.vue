<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="500px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <div style="margin-bottom: 16px" v-if="canChangeWarehouse">
      <span>所属仓库：</span>
      <a-select
        v-model:value="selectedWarehouseId"
        placeholder="选择所属仓库"
        :options="warehouseOptions"
        :field-names="{ label: 'name', value: 'id' }"
        style="width: 100%"
      />
    </div>
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { zoneFormSchema } from './location.data';
  import { saveOrUpdateZone } from './location.api';
  import { queryAllWarehouse } from '../warehouse/warehouse.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const canChangeWarehouse = ref(true);
  const selectedWarehouseId = ref('');
  const warehouseOptions = ref<any[]>([]);

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: zoneFormSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    setDrawerProps({ confirmLoading: false });

    const res = await queryAllWarehouse();
    warehouseOptions.value = (res as any)?.result || (res as any)?.records || res || [];

    isUpdate.value = !!data?.isUpdate;

    if (unref(isUpdate) && data.record) {
      await setFieldsValue({ ...data.record });
      selectedWarehouseId.value = data.record.warehouseId || '';
      canChangeWarehouse.value = false;
    } else if (data?.warehouseId) {
      selectedWarehouseId.value = data.warehouseId;
      canChangeWarehouse.value = true;
      await setFieldsValue({ warehouseId: data.warehouseId });
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑库区' : '新增库区'));

  async function handleSubmit() {
    const values = await validate();
    values.warehouseId = values.warehouseId || unref(selectedWarehouseId);
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateZone(values, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
