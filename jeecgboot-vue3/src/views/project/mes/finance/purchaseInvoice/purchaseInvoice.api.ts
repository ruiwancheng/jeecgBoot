import { defHttp } from '/@/utils/http/axios'; const B='/mes/finance/purchaseInvoice';
export const queryPurchaseInvoiceList=(p:any)=>defHttp.get({url:`${B}/list`,params:p}); export const queryPurchaseInvoiceById=(p:any)=>defHttp.get({url:`${B}/queryById`,params:p});
export const saveOrUpdatePurchaseInvoice=(d:any,u:boolean)=>u?defHttp.put({url:`${B}/edit`,data:d}):defHttp.post({url:`${B}/add`,data:d});
export const deletePurchaseInvoice=(p:any)=>defHttp.delete({url:`${B}/delete`,params:p},{joinParamsToUrl:true}); export const getExportUrl=()=>`${B}/exportXls`;
