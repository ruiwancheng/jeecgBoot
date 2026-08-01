//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】Pinia store：跨页面共享总开关状态-----------
import { defineStore } from 'pinia';
import { listAll } from '/@/api/project/mes/system/commonSetting.api';

interface MesGlobalSwitchState {
  /** switchKey → switchValue (boolean) */
  switches: Record<string, boolean>;
  /** 最后加载时间戳，避免频繁请求 */
  loaded: boolean;
}

/**
 * MES 全局开关 Pinia store
 * - commonSetting 页修改开关 → 调用 set(key, val) 同步到 store
 * - material 页读 store.switches['mes_batch_enabled'] 决定 batchEnabled 字段的 disabled
 */
export const useMesGlobalSwitchStore = defineStore('mesGlobalSwitch', {
  state: (): MesGlobalSwitchState => ({
    switches: {},
    loaded: false,
  }),

  getters: {
    isBatchEnabled: (state) => !!state.switches['mes_batch_enabled'],
  },

  actions: {
    /** 加载所有总开关（页面 onMounted 时调用） */
    async load(force = false) {
      if (this.loaded && !force) return;
      const list = await listAll();
      const map: Record<string, boolean> = {};
      (list || []).forEach((s: any) => {
        map[s.switchKey] = s.switchValue === 1;
      });
      this.switches = map;
      this.loaded = true;
    },

    /** 设置某个开关的状态（修改后立即同步到 store，避免切页面重新拉取） */
    set(switchKey: string, value: boolean) {
      this.switches[switchKey] = value;
    },

    /** 重置（用于"全部开关已关闭"等场景） */
    reset() {
      this.switches = {};
      this.loaded = false;
    },
  },
});
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】Pinia store：跨页面共享总开关状态-----------