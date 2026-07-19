import { defHttp } from '/@/utils/http/axios'; const B='/mes/finance/salesInvoice';
export const queryInvoiceList=(p:any)=>defHttp.get({url:`${B}/list`,params:p}); export const queryInvoiceById=(p:any)=>defHttp.get({url:`${B}/queryById`,params:p});
export const saveOrUpdateInvoice=(d:any,u:boolean)=>u?defHttp.put({url:`${B}/edit`,data:d}):defHttp.post({url:`${B}/add`,data:d});
export const deleteInvoice=(p:any)=>defHttp.delete({url:`${B}/delete`,params:p},{joinParamsToUrl:true}); export const getExportUrl=()=>`${B}/exportXls`;
