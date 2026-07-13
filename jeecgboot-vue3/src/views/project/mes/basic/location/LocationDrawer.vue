<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="700px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <div style="margin-bottom: 16px; display: flex; gap: 12px; flex-wrap: wrap; align-items: center">
      <span>所属仓库：</span>
      <a-select
        v-model:value="cascWarehouseId"
        placeholder="选择仓库"
        style="width: 170px"
        :options="warehouseOptions"
        :field-names="{ label: 'name', value: 'id' }"
        @change="onWhChange"
      />
      <span>所属库区：</span>
      <a-select
        v-model:value="cascZoneId"
        placeholder="选择库区"
        style="width: 170px"
        :options="zoneOptions"
        :field-names="{ label: 'name', value: 'id' }"
        :disabled="!cascWarehouseId"
        @change="onZoneChange"
      />
      <span>所属货架：</span>
      <a-select
        v-model:value="cascShelfId"
        placeholder="选择货架"
        style="width: 170px"
        :options="shelfOptions"
        :field-names="{ label: 'name', value: 'id' }"
        :disabled="!cascZoneId"
        @change="onShelfChange"
      />
    </div>
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './location.data';
  import { saveOrUpdateLocation, queryZoneTree, queryShelfTree } from './location.api';
  import { queryAllWarehouse } from '../warehouse/warehouse.api';

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);

  const cascWarehouseId = ref('');
  const cascZoneId = ref('');
  const cascShelfId = ref('');
  const warehouseOptions = ref<any[]>([]);
  const zoneOptions = ref<any[]>([]);
  const shelfOptions = ref<any[]>([]);

  const [registerForm, { resetFields, setFieldsValue, validate }] = useForm({
    schemas: formSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    isUpdate.value = !!data?.isUpdate;
    cascWarehouseId.value = '';
    cascZoneId.value = '';
    cascShelfId.value = '';
    warehouseOptions.value = [];
    zoneOptions.value = [];
    shelfOptions.value = [];

    setDrawerProps({ confirmLoading: false });

    const res = await queryAllWarehouse();
    warehouseOptions.value = (res as any)?.result || (res as any)?.records || res || [];

    if (unref(isUpdate) && data.record) {
      await setFieldsValue({ ...data.record });
      if (data.record.shelfId) cascShelfId.value = data.record.shelfId;
      if (data.record.zoneId) cascZoneId.value = data.record.zoneId;
      if (data.record.warehouseId) {
        cascWarehouseId.value = data.record.warehouseId;
        await onWhChange(data.record.warehouseId);
      }
    } else if (data?.shelfId) {
      cascShelfId.value = data.shelfId;
      cascZoneId.value = data.zoneId || '';
      cascWarehouseId.value = data.warehouseId || '';
      await setFieldsValue({ shelfId: data.shelfId, zoneId: data.zoneId, warehouseId: data.warehouseId });
      if (data.warehouseId) await onWhChange(data.warehouseId);
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑库位' : '新增库位'));

  async function onWhChange(value: string) {
    cascZoneId.value = '';
    cascShelfId.value = '';
    zoneOptions.value = [];
    shelfOptions.value = [];
    if (!value) return;
    await setFieldsValue({ warehouseId: value, zoneId: '', shelfId: '' });
    const res = await queryZoneTree(value);
    zoneOptions.value = (res as any)?.result || (res as any)?.records || res || [];
  }

  async function onZoneChange(value: string) {
    cascShelfId.value = '';
    shelfOptions.value = [];
    if (!value) return;
    await setFieldsValue({ zoneId: value, shelfId: '' });
    const res = await queryShelfTree(value);
    shelfOptions.value = (res as any)?.result || (res as any)?.records || res || [];
  }

  function onShelfChange(value: string) {
    setFieldsValue({ shelfId: value });
  }

  async function handleSubmit() {
    const values = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      await saveOrUpdateLocation(values, unref(isUpdate));
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
