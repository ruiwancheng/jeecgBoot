<!-- @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0 -->
<template>
  <BasicDrawer v-bind="$attrs" @register="registerDrawer" :title="getTitle" width="900px" destroyOnClose :showFooter="true" @ok="handleSubmit">
    <BasicForm @register="registerForm" />
    <!--update-begin---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】模式8口径提示Alert----------->
    <a-alert type="info" show-icon style="margin-bottom: 8px" :message="alertText" />
    <!--update-end---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】模式8口径提示Alert----------->
  </BasicDrawer>
</template>

<script lang="ts" setup>
  import { ref, computed, unref } from 'vue';
  import { BasicForm, useForm } from '/@/components/Form/index';
  import { BasicDrawer, useDrawerInner } from '/@/components/Drawer';
  import { formSchema } from './master.data';
  import { addBatch, editBatch, queryBatchById } from './master.api';
  //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档自动带入物料保质期+计算有效期至-----------
  import { queryMaterialById } from '/@/views/project/mes/basic/material/material.api';
  //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档自动带入物料保质期+计算有效期至-----------

  const emit = defineEmits(['success', 'register']);
  const isUpdate = ref(false);
  //update-begin---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】模式8口径提示Alert-----------
  // 批次主档口径提示：状态语义。冻结/过期/已耗尽 都会影响库存可用性。
  const alertText = ref('批次创建后由来源单据自动产生。状态：在用 → 冻结 / 过期 / 已耗尽。冻结或过期的批次不能被出库。');
  //update-end---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】模式8口径提示Alert-----------

  //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档自动带入物料保质期+计算有效期至-----------
  // 程序内部写"有效期至"时的标记位（区分用户改 vs 程序写）
  let isProgramUpdateExpiry = false;
  // 用户是否手工改过"有效期至"——一旦改过不再自动覆盖
  const userTouchedExpiry = ref(false);

  /** 计算有效期至：YYYY-MM-DD + shelfLife 天。无输入返回 undefined。 */
  const calcExpiry = (productionDate: any, shelfLife: any): string | undefined => {
    if (!productionDate || shelfLife == null || Number(shelfLife) <= 0) return undefined;
    const d = new Date(productionDate);
    if (isNaN(d.getTime())) return undefined;
    d.setDate(d.getDate() + Number(shelfLife));
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  };
  //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档自动带入物料保质期+计算有效期至-----------

  const [registerForm, { resetFields, setFieldsValue, getFieldsValue, validate }] = useForm({
    schemas: formSchema,
    showActionButtonGroup: false,
    labelWidth: 100,
    //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档表单字段联动 onValuesChange-----------
    async onValuesChange(changed: Record<string, any>, allValues: Record<string, any>) {
      if (!changed) return;
      // 1) 选物料 → 自动带出物料的保质期（仅新增 + 表单 shelfLife 未填）
      if (changed.materialId !== undefined && !unref(isUpdate)) {
        const current: any = await getFieldsValue();
        if (current.shelfLife == null || current.shelfLife === '') {
          try {
            const mat: any = await queryMaterialById({ id: changed.materialId });
            if (mat?.shelfLife != null) {
              setFieldsValue({ shelfLife: mat.shelfLife });
              // 物料保质期刚被带入，立即按当前生产日期重算有效期至
              const exp = calcExpiry(current.productionDate, mat.shelfLife);
              isProgramUpdateExpiry = true;
              try {
                await setFieldsValue({ expiryDate: exp ?? null });
              } finally {
                isProgramUpdateExpiry = false;
              }
            }
          } catch (e) {
            /* silent：物料读取失败不影响主流程 */
          }
        }
      }
      // 2) productionDate 或 shelfLife 变化 → 重算有效期至（仅程序模式下）
      if (
        (changed.productionDate !== undefined || changed.shelfLife !== undefined) &&
        !userTouchedExpiry.value
      ) {
        const exp = calcExpiry(allValues.productionDate, allValues.shelfLife);
        isProgramUpdateExpiry = true;
        try {
          await setFieldsValue({ expiryDate: exp ?? null });
        } finally {
          isProgramUpdateExpiry = false;
        }
      }
      // 3) 用户手工改有效期至 → 标记为已手工修改，后续程序不再自动覆盖
      if (changed.expiryDate !== undefined && !isProgramUpdateExpiry) {
        userTouchedExpiry.value = true;
      }
    },
    //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档表单字段联动 onValuesChange-----------
  });

  const [registerDrawer, { setDrawerProps, closeDrawer }] = useDrawerInner(async (data) => {
    await resetFields();
    //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档抽屉打开时重置交互标记-----------
    // 每次打开抽屉重置"用户是否手工改过有效期至"标记
    userTouchedExpiry.value = false;
    //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次主档抽屉打开时重置交互标记-----------
    isUpdate.value = !!data?.isUpdate;
    setDrawerProps({ confirmLoading: false });
    if (unref(isUpdate) && data.record) {
      try {
        const rec = await queryBatchById({ id: data.record.id });
        if (rec) {
          //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-编辑模式下程序回填不触发"用户手工改"标记-----------
          isProgramUpdateExpiry = true;
          try {
            await setFieldsValue(rec);
          } finally {
            isProgramUpdateExpiry = false;
          }
          // 编辑模式：先把 initial expiry 视为程序值，不锁住 userTouchedExpiry，用户可继续编辑触发自动计算
          userTouchedExpiry.value = false;
          //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-编辑模式下程序回填不触发"用户手工改"标记-----------
        }
      } catch (e) {
        /* fallback */
      }
    }
  });

  const getTitle = computed(() => (unref(isUpdate) ? '编辑批次' : '新增批次'));

  async function handleSubmit() {
    const v = await validate();
    setDrawerProps({ confirmLoading: true });
    try {
      if (unref(isUpdate)) await editBatch(v, true);
      else await addBatch(v);
      closeDrawer();
      emit('success');
    } finally {
      setDrawerProps({ confirmLoading: false });
    }
  }
</script>
