import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/batch/inventory';

export function queryInventoryList(params: any) {
  return defHttp.get({ url: `${BASE}/list`, params });
}

export function queryInventoryById(params: any) {
  return defHttp.get({ url: `${BASE}/queryById`, params });
}

//update-begin---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次库存导出函数-----------
export function getExportUrl() {
  return '/mes/batch/inventory/exportXls';
}
//update-end---author:ruiwancheng---date:2026-07-31---for: P0-4 铁拳团-批次库存导出函数-----------
