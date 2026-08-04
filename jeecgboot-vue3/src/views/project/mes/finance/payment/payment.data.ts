import { BasicColumn, FormSchema } from '/@/components/Table';
import { querySupplierSelect } from '/@/views/project/mes/purchase/order/order.api';
export const columns: BasicColumn[] = [
  { title: '付款单号', dataIndex: 'code', width: 150 },
  { title: '供应商', dataIndex: 'supplierId', width: 150, dictTable: 'c_mes_supplier', dictText: 'name', dictCode: 'id' },
  { title: '付款金额', dataIndex: 'amount', width: 120 },
  { title: '付款日期', dataIndex: 'paymentDate', width: 120 },
  { title: '付款方式', dataIndex: 'paymentMethod', width: 100, dictCode: 'mes_payment_method' },
  { title: '备注', dataIndex: 'remark', width: 200 },
];
export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '付款单号', component: 'Input', colProps: { span: 6 } },
  { field: 'supplierId', label: '供应商', component: 'ApiSelect', componentProps: { api: querySupplierSelect }, colProps: { span: 6 } },
];
//update-begin---author:pi---date:2026-08-04---for:【TKT-001】付款单 formSchema（修复 #11 抽屉不可用）-----------
export const formSchema: FormSchema[] = [
  { field: 'code', label: '付款单号', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'supplierId', label: '供应商', component: 'ApiSelect', componentProps: { api: querySupplierSelect }, required: true, colProps: { span: 12 } },
  { field: 'amount', label: '付款金额', component: 'InputNumber', required: true, colProps: { span: 12 }, componentProps: { min: 0, step: 0.01, precision: 2 } },
  { field: 'paymentDate', label: '付款日期', component: 'DatePicker', required: true, componentProps: { valueFormat: 'YYYY-MM-DD' }, colProps: { span: 12 } },
  { field: 'paymentMethod', label: '付款方式', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_payment_method' }, defaultValue: '1', colProps: { span: 12 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', componentProps: { dictCode: 'yn' }, defaultValue: '1', colProps: { span: 12 } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
//update-end---author:pi---date:2026-08-04---for:【TKT-001】付款单 formSchema（修复 #11）-----------
