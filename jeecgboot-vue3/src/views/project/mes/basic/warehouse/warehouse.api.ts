import { defHttp } from '/@/utils/http/axios';

enum Api {
  list = '/mes/basic/warehouse/list',
  add = '/mes/basic/warehouse/add',
  edit = '/mes/basic/warehouse/edit',
  delete = '/mes/basic/warehouse/delete',
  deleteBatch = '/mes/basic/warehouse/deleteBatch',
  queryAll = '/mes/basic/warehouse/queryAll',
  deactivate = '/mes/basic/warehouse/deactivate',
  activate = '/mes/basic/warehouse/activate',
  exportXls = '/mes/basic/warehouse/exportXls',
  importExcel = '/mes/basic/warehouse/importExcel',
}

export const getExportUrl = Api.exportXls;
export const getImportUrl = Api.importExcel;

export const queryWarehouseList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addWarehouse = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editWarehouse = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deleteWarehouse = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchWarehouse = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const queryAllWarehouse = () => defHttp.get({ url: Api.queryAll });
export const deactivateWarehouse = (params: Recordable) => defHttp.put({ url: Api.deactivate, params }, { joinParamsToUrl: true });
export const activateWarehouse = (params: Recordable) => defHttp.put({ url: Api.activate, params }, { joinParamsToUrl: true });
export const saveOrUpdateWarehouse = (params: Recordable, isUpdate: boolean) => {
  return isUpdate ? editWarehouse(params) : addWarehouse(params);
};

/** 下拉选择（ApiSelect专用，替代平台字典 c_mes_warehouse） */
export async function queryWarehouseSelect(params?: any) {
  const res = await defHttp.get({ url: '/mes/warehouse/selectPage', params });
  return res || [];
}
