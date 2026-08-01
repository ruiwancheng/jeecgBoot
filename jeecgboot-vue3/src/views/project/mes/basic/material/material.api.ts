import { defHttp } from '/@/utils/http/axios';

enum Api {
  list = '/mes/basic/material/list',
  add = '/mes/basic/material/add',
  edit = '/mes/basic/material/edit',
  delete = '/mes/basic/material/delete',
  deleteBatch = '/mes/basic/material/deleteBatch',
  queryById = '/mes/basic/material/queryById',
  queryAll = '/mes/basic/material/queryAll',
  exportXls = '/mes/basic/material/exportXls',
  importExcel = '/mes/basic/material/importExcel',
  selectPage = '/mes/basic/material/selectPage',
}

export const getExportUrl = Api.exportXls;
export const getImportUrl = Api.importExcel;

export const queryMaterialList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addMaterial = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editMaterial = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deleteMaterial = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchMaterial = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const queryMaterialById = (params: Recordable) => defHttp.get({ url: Api.queryById, params });
export const queryMaterialsByIds = (ids: string[]) => defHttp.get({ url: '/mes/basic/material/queryByIds', params: { ids: ids.join(',') } });
export const queryAllMaterial = () => defHttp.get({ url: Api.queryAll });
export const selectMaterialPage = (params: { keyword?: string; pageNo?: number; pageSize?: number }) =>
  defHttp.get({ url: Api.selectPage, params });
//update-begin---author:ruiwancheng---date:20260731---for:【批次主档 ApiSelect 下拉函数补全】补全缺失的 queryMaterialSelect，照搬 customer/warehouse 标准模式-----------
/** 下拉选择（ApiSelect专用，替代平台字典 c_mes_material） */
export async function queryMaterialSelect(params?: any) {
  const res = await defHttp.get({ url: Api.selectPage, params });
  return res || [];
}
//update-end---author:ruiwancheng---date:20260731---for:【批次主档 ApiSelect 下拉函数补全】补全缺失的 queryMaterialSelect，照搬 customer/warehouse 标准模式-----------
export const saveOrUpdateMaterial = (params: Recordable, isUpdate: boolean) =>
  isUpdate ? editMaterial(params) : addMaterial(params);
