<template>
  <div>
    <BasicTable @register="registerTable">
      <template #bodyCell="{ column, record }">
        <template v-if="column.dataIndex === 'switchValue'">
          <a-switch
            :checked="record.switchValue === 1"
            :loading="loadingKeys.has(record.switchKey)"
            @change="(val) => onSwitchChange(record, val)"
          />
        </template>
      </template>
    </BasicTable>
  </div>
</template>

<script lang="ts" setup>
  //update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】通用设置页面（开关 + 关闭前置检查 + 二次确认）-----------
  import { ref } from 'vue';
  import { BasicTable, useTable } from '/@/components/Table';
  import { useMessage } from '/@/hooks/web/useMessage';
  import { Modal } from 'ant-design-vue';
  import type { CloseCheckError, MesGlobalSwitch } from '/@/api/project/mes/system/model/commonSettingModel';
  import { columns } from './commonSetting.data';
  import {
    listAll,
    saveCommonSetting,
    closeCheck,
    closeBatchSwitch,
  } from '/@/api/project/mes/system/commonSetting.api';
  import { useMesGlobalSwitchStore } from '/@/store/modules/mesGlobalSwitch';

  defineOptions({ name: 'MesBasicCommonSetting' });

  const { createMessage } = useMessage();
  const mesGlobalSwitchStore = useMesGlobalSwitchStore();
  /** 记录每个开关当前是否在请求中（避免并发触发） */
  const loadingKeys = ref<Set<string>>(new Set());

  const [registerTable, { reload }] = useTable({
    api: listAll,
    columns,
    useSearchForm: false,
    showTableSetting: false,
    showIndexColumn: false,
    pagination: false,
    afterFetch: (records: MesGlobalSwitch[]) => {
      (records || []).forEach((s) => {
        mesGlobalSwitchStore.set(s.switchKey, s.switchValue === 1);
      });
      mesGlobalSwitchStore.loaded = true;
    },
  });

  function formatErrors(errors: CloseCheckError[]): string {
    return errors.map((e) => `• [${e.layer}] ${e.title}：${e.detail}`).join('\n');
  }

  function setLoading(key: string, on: boolean) {
    const set = new Set(loadingKeys.value);
    if (on) set.add(key);
    else set.delete(key);
    loadingKeys.value = set;
  }

  /**
   * 开关切换处理
   * - 开启（关→开）：直接调 save
   * - 关闭（开→关）：先调 closeCheck 检查 → 弹窗显示错误清单 / 二次确认后调 closeBatchSwitch
   */
  async function onSwitchChange(record: MesGlobalSwitch, val: boolean | string | number) {
    const checked = !!val;
    const key = record.switchKey;
    setLoading(key, true);
    try {
      if (checked) {
        await saveCommonSetting({
          id: record.id,
          switchKey: record.switchKey,
          switchValue: 1,
          switchName: record.switchName,
          description: record.description,
        });
        mesGlobalSwitchStore.set(key, true);
        createMessage.success('已开启');
        await reload();
      } else {
        await handleCloseFlow(record);
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      createMessage.error(msg || '操作失败');
      await reload();
    } finally {
      setLoading(key, false);
    }
  }

  async function handleCloseFlow(record: MesGlobalSwitch) {
    const key = record.switchKey;
    // 1. 前置检查
    const check = await closeCheck({ switchKey: key });
    if (check?.errors?.length > 0) {
      createMessage.warning('无法关闭，请先处理以下数据：\n' + formatErrors(check.errors), 8);
      await reload();
      return;
    }
    // 2. 二次确认（直接用 antd Modal.confirm，返回 Promise 可 await）
    const confirmed = await new Promise<boolean>((resolve) => {
      Modal.confirm({
        title: '确认关闭生产批次管理？',
        content: '关闭后将清空所有物料的批次启用状态，且不再创建/扣减批次库存。',
        okText: '确认关闭',
        cancelText: '取消',
        centered: true,
        onOk: () => resolve(true),
        onCancel: () => resolve(false),
      });
    });
    if (!confirmed) {
      await reload();
      return;
    }
    // 3. 真正执行关闭
    const result = await closeBatchSwitch();
    if (result?.errors?.length > 0) {
      createMessage.error('关闭失败：\n' + formatErrors(result.errors), 8);
      await reload();
      return;
    }
    mesGlobalSwitchStore.set(key, false);
    createMessage.success('已关闭');
    await reload();
  }
  //update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】通用设置页面-----------
</script>