<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="500px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <div style="margin-bottom: 16px">
      <a-form layout="inline">
        <a-form-item label="所属仓库" style="margin-bottom: 8px">
          <a-select
            v-model:value="cascWarehouseId"
            placeholder="选择仓库"
            style="width: 200px"
            :options="warehouseOptions"
            :field-names="{ label: 'name', value: 'id' }"
            :disabled="!canChangeParent"
            @change="onWhChange"
          />
        </a-form-item>
        <a-form-item label="所属库区" style="margin-bottom: 8px">
          <a-select
            v-model:value="cascZoneId"
            placeholder="选择库区"
            style="width: 200px"
            :options="zoneOptions"
            :field-names="{ label: 'name', value: 'id' }"
            :disabled="!canChangeParent || !cascWarehouseId"
            @change="onZoneSelect"
          />
        </a-form-item>
      </a-form>
    </div>
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { shelfFormSchema } from './location.data';
  import { saveOrUpdateShelf, queryZoneTree } from './location.api';
  import { queryAllWarehouse } from '../warehouse/warehouse.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  const canChangeParent = ref(true);
  const cascWarehouseId = ref('');
  const cascZoneId = ref('');
  const warehouseOptions = ref<any[]>([]);
  const zoneOptions = ref<any[]>([]);

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: shelfFormSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    setDrawerProps({ confirmLoading: false });
    cascWarehouseId.value = '';
    cascZoneId.value = '';
    zoneOptions.value = [];

    const res = await queryAllWarehouse();
    warehouseOptions.value = (res as any)?.result || (res as any)?.records || res || [];

    isUpdate.value = !!data?.isUpdate;

    if (unref(isUpdate) && data.record) {
      await setFieldsValue({ ...data.record });
      cascZoneId.value = data.record.zoneId || '';
      if (data.record.warehouseId) {
        cascWarehouseId.value = data.record.warehouseId;
        await onWhChange(data.record.warehouseId);
      }
      canChangeParent.value = false;
    } else if (data?.zoneId) {
      cascZoneId.value = data.zoneId;
      cascWarehouseId.value = data.warehouseId || '';
      canChangeParent.value = true;
      await setFieldsValue({ zoneId: data.zoneId, warehouseId: data.warehouseId });
      const res = await queryZoneTree(data.warehouseId || '');
      zoneOptions.value = (res as any)?.result || (res as any)?.records || res || [];
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑货架' : '新增货架'));

  async function onWhChange(value: string) {
    cascZoneId.value = '';
    zoneOptions.value = [];
    if (!value) return;
    const res = await queryZoneTree(value);
    zoneOptions.value = (res as any)?.result || (res as any)?.records || res || [];
  }

  function onZoneSelect(value: string) {
    setFieldsValue({ zoneId: value });
  }

  async function handleSubmit() {
    const values = await validate();
    values.zoneId = values.zoneId || unref(cascZoneId);
    values.warehouseId = values.warehouseId || unref(cascWarehouseId);
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateShelf(values, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
