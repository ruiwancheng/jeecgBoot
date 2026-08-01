//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】前端通用设置 API 封装-----------
import { defHttp } from '/@/utils/http/axios';
import type { CloseCheckResult, MesGlobalSwitch } from './model/commonSettingModel';

enum Api {
  list = '/mes/system/globalSwitch/list',
  save = '/mes/system/globalSwitch/save',
  closeCheck = '/mes/system/globalSwitch/closeCheck',
  closeBatchSwitch = '/mes/system/globalSwitch/closeBatchSwitch',
}

/** 通用开关列表 */
export const listAll = (params?: Recordable) =>
  defHttp.get<MesGlobalSwitch[]>({ url: Api.list, params });

/** 保存/更新通用开关 */
export const saveCommonSetting = (params: MesGlobalSwitch) =>
  defHttp.post({ url: Api.save, params });

/** 关闭开关前置检查（不执行关闭动作） */
export const closeCheck = (params: { switchKey: string }) =>
  defHttp.get<CloseCheckResult>({ url: Api.closeCheck, params });

/** 关闭生产批次总开关（原子操作：含检查+总开关置0+物料batch_enabled批量置0） */
export const closeBatchSwitch = () =>
  defHttp.post<CloseCheckResult>({ url: Api.closeBatchSwitch });
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】前端通用设置 API 封装-----------