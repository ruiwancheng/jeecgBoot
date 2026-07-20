import { defHttp } from '/@/utils/http/axios';

enum Api {
  list = '/mes/basic/codeRule/list',
  add = '/mes/basic/codeRule/add',
  edit = '/mes/basic/codeRule/edit',
  delete = '/mes/basic/codeRule/delete',
  deleteBatch = '/mes/basic/codeRule/deleteBatch',
  queryById = '/mes/basic/codeRule/queryById',
  queryAll = '/mes/basic/codeRule/queryAll',
  nextCode = '/mes/basic/codeRule/nextCode',
}

export const queryCodeRuleList = (params: Recordable) => defHttp.get({ url: Api.list, params });
export const addCodeRule = (params: Recordable) => defHttp.post({ url: Api.add, params });
export const editCodeRule = (params: Recordable) => defHttp.put({ url: Api.edit, params });
export const deleteCodeRule = (params: Recordable) => defHttp.delete({ url: Api.delete, params }, { joinParamsToUrl: true });
export const deleteBatchCodeRule = (params: Recordable) => defHttp.delete({ url: Api.deleteBatch, params }, { joinParamsToUrl: true });
export const queryCodeRuleById = (params: Recordable) => defHttp.get({ url: Api.queryById, params });
export const queryAllCodeRule = () => defHttp.get({ url: Api.queryAll });

/** 获取下一个编码，用于自动生成业务编码 */
export const getNextCode = (ruleCode: string) => defHttp.get({ url: Api.nextCode, params: { ruleCode } });
