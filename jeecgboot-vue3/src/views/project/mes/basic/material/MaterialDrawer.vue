<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="700px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
  </BasicDrawer>
</template>

<script lang="ts" setup>
//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】MaterialDrawer：加载 store + 监听总开关变化动态禁用 batchEnabled 字段-----------
import { ref, computed, unref, watch } from 'vue';
import { BasicForm, useForm } from '/@/components/Form/index';
import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
import { formSchema } from './material.data';
import { saveOrUpdateMaterial, queryMaterialById } from './material.api';
import { useMesGlobalSwitchStore } from '/@/store/modules/mesGlobalSwitch';

const emit = defineEmits(['success', 'register']);
const isUpdate = ref(false);
const mesGlobalSwitchStore = useMesGlobalSwitchStore();

const [registerForm, { resetFields, setFieldsValue, validate, updateSchema }] = useForm({
  schemas: formSchema,
  showActionButtonGroup: false,
  labelWidth: 100,
  actionColOptions: { span: 24 },
});

/** 总开关开启时 = false，关闭时 = true（强制禁用） */
const batchFieldDisabled = computed(() => !mesGlobalSwitchStore.isBatchEnabled);

function syncBatchFieldState() {
  // 通过 updateSchema 改 batchEnabled 字段的 componentProps.disabled（动态改 formSchema 中的对象）
  const next = formSchema.map((s) => {
    if (s.field !== 'batchEnabled') return s;
    return {
      ...s,
      componentProps: {
        ...(s.componentProps as Record<string, unknown>),
        disabled: unref(batchFieldDisabled),
      },
    };
  });
  updateSchema(next);
}

const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
  await resetFields();
  isUpdate.value = !!data?.isUpdate;
  setDrawerProps({ confirmLoading: false });

  // 1) 保证总开关已加载（多 Tab 直接打开 material 页面也不会空）
  await mesGlobalSwitchStore.load();

  // 2) 把 store 当前状态推到表单
  syncBatchFieldState();

  // 3) 拉详情后填表
  if (unref(isUpdate) && data.record) {
    const res = await queryMaterialById({ id: data.record.id });
    if (res) {
      // 总开关关闭时强制把 batchEnabled 归零（避免前端绕过 GUI 提交 1）
      if (unref(batchFieldDisabled)) res.batchEnabled = 0;
      await setFieldsValue({ ...res });
    }
  }
});

const getTitle = computed(() => (unref(isUpdate) ? '编辑物料' : '新增物料'));

/** 监听总开关变化：跨 Tab 实时同步（用户在通用设置页切换总开关后立即禁用） */
watch(batchFieldDisabled, () => {
  syncBatchFieldState();
  // 若总开关关闭时表单里残留 1，归零
  if (unref(batchFieldDisabled)) {
    setFieldsValue({ batchEnabled: 0 });
  }
});

async function handleSubmit() {
  const values = await validate();
  // 提交前最后一道兜底：总开关关闭时 batchEnabled 强制 0
  if (unref(batchFieldDisabled)) values.batchEnabled = 0;
  setDrawerProps({ confirmLoading: true });
  try {
    await saveOrUpdateMaterial(values, unref(isUpdate));
    closeDrawer();
    emit('success');
  } finally {
    setDrawerProps({ confirmLoading: false });
  }
}
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】MaterialDrawer：store 联动-----------
</script>
