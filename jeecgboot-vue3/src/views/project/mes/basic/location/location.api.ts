import { defHttp } from '/@/utils/http/axios';

enum Api {
  list = '/mes/basic/location/list',
  add = '/mes/basic/location/add',
  edit = '/mes/basic/location/edit',
  delete = '/mes/basic/location/delete',
  deleteBatch = '/mes/basic/location/deleteBatch',
  generate = '/mes/basic/location/generate',
  exportXls = '/mes/basic/location/exportXls',
  importExcel = '/mes/basic/location/importExcel',
}

export const getExportUrl = Api.exportXls;
export const getImportUrl = Api.importExcel;

export const queryLocationList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addLocation = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editLocation = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deleteLocation = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchLocation = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const generateLocations = (params: Recordable) => defHttp.post({ url: Api.generate, params });
export const saveOrUpdateLocation = (params: Recordable, isUpdate: boolean) => {
  return isUpdate ? editLocation(params) : addLocation(params);
};
