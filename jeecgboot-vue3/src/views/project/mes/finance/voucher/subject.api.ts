import { defHttp } from '/@/utils/http/axios';

/** 科目下拉（ApiSelect专用） */
export async function querySubjectSelect(params?: any) {
  const res = await defHttp.get({ url: '/mes/finance/subject/selectPage', params });
  return res || [];
}
