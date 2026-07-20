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
export const queryAllMaterial = () => defHttp.get({ url: Api.queryAll });
export const selectMaterialPage = (params: { keyword?: string; pageNo?: number; pageSize?: number }) =>
  defHttp.get({ url: Api.selectPage, params });
export const saveOrUpdateMaterial = (params: Recordable, isUpdate: boolean) =>
  isUpdate ? editMaterial(params) : addMaterial(params);
