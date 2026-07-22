import { defHttp } from '/@/utils/http/axios';

const BASE = '/mes/finance/subject';

export function querySubjectList(params: any) { return defHttp.get({ url: `${BASE}/list`, params }); }
export function querySubjectById(params: any) { return defHttp.get({ url: `${BASE}/queryById`, params }); }
export function querySubjectTree() { return defHttp.get({ url: `${BASE}/tree` }); }
export function saveOrUpdateSubject(data: any, isUpdate: boolean) {
  return isUpdate ? defHttp.put({ url: `${BASE}/edit`, data }) : defHttp.post({ url: `${BASE}/add`, data });
}
export function deleteSubject(params: any) { return defHttp.delete({ url: `${BASE}/delete`, params }, { joinParamsToUrl: true }); }
export function getExportUrl() { return `${BASE}/exportXls`; }

/** 下拉选择（ApiSelect专用，替代平台字典 c_mes_finance/subject） */
export async function querySubjectSelect(params?: any) {
  const res = await defHttp.get({ url: '/mes/finance/subject/selectPage', params });
  return res || [];
}
