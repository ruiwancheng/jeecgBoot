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

enum ZoneApi {
  list = '/mes/basic/zone/list',
  add = '/mes/basic/zone/add',
  edit = '/mes/basic/zone/edit',
  delete = '/mes/basic/zone/delete',
  tree = '/mes/basic/zone/tree',
}

enum ShelfApi {
  list = '/mes/basic/shelf/list',
  add = '/mes/basic/shelf/add',
  edit = '/mes/basic/shelf/edit',
  delete = '/mes/basic/shelf/delete',
  tree = '/mes/basic/shelf/tree',
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

export const queryZoneList = (params: Recordable) => defHttp.get({ url: ZoneApi.list, params });
export const queryZoneTree = (warehouseId: string) => defHttp.get({ url: ZoneApi.tree, params: { warehouseId } });
export const addZone = (params: Recordable) => defHttp.post({ url: ZoneApi.add, params });
export const editZone = (params: Recordable) => defHttp.put({ url: ZoneApi.edit, params });
export const deleteZone = (params: Recordable) => defHttp.delete({ url: ZoneApi.delete, params }, { joinParamsToUrl: true });
export const saveOrUpdateZone = (params: Recordable, isUpdate: boolean) => {
  return isUpdate ? editZone(params) : addZone(params);
};

export const queryShelfList = (params: Recordable) => defHttp.get({ url: ShelfApi.list, params });
export const queryShelfTree = (zoneId: string) => defHttp.get({ url: ShelfApi.tree, params: { zoneId } });
export const addShelf = (params: Recordable) => defHttp.post({ url: ShelfApi.add, params });
export const editShelf = (params: Recordable) => defHttp.put({ url: ShelfApi.edit, params });
export const deleteShelf = (params: Recordable) => defHttp.delete({ url: ShelfApi.delete, params }, { joinParamsToUrl: true });
export const saveOrUpdateShelf = (params: Recordable, isUpdate: boolean) => {
  return isUpdate ? editShelf(params) : addShelf(params);
};
