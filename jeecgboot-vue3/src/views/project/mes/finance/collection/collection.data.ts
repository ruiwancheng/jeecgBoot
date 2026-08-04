import { BasicColumn, FormSchema } from '/@/components/Table';
import { queryCustomerSelect } from '/@/views/project/mes/basic/customer/customer.api';
export const columns: BasicColumn[] = [
  { title: '收款单号', dataIndex: 'code', width: 150 },
  { title: '客户', dataIndex: 'customerId', width: 150, dictTable: 'c_mes_customer', dictText: 'name', dictCode: 'id' },
  { title: '收款金额', dataIndex: 'amount', width: 120 },
  { title: '收款日期', dataIndex: 'collectionDate', width: 120 },
  { title: '收款方式', dataIndex: 'paymentMethod', width: 100, dictCode: 'mes_payment_method' },
  { title: '备注', dataIndex: 'remark', width: 200 },
];
export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '收款单号', component: 'Input', colProps: { span: 6 } },
  { field: 'customerId', label: '客户', component: 'ApiSelect', componentProps: { api: queryCustomerSelect }, colProps: { span: 6 } },
];
//update-begin---author:pi---date:2026-08-04---for:【TKT-001】收款单 formSchema（修复 #9 抽屉不可用）-----------
export const formSchema: FormSchema[] = [
  { field: 'code', label: '收款单号', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'customerId', label: '客户', component: 'ApiSelect', componentProps: { api: queryCustomerSelect }, required: true, colProps: { span: 12 } },
  { field: 'amount', label: '收款金额', component: 'InputNumber', required: true, colProps: { span: 12 }, componentProps: { min: 0, step: 0.01, precision: 2 } },
  { field: 'collectionDate', label: '收款日期', component: 'DatePicker', required: true, componentProps: { valueFormat: 'YYYY-MM-DD' }, colProps: { span: 12 } },
  { field: 'paymentMethod', label: '收款方式', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_payment_method' }, defaultValue: '1', colProps: { span: 12 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', componentProps: { dictCode: 'yn' }, defaultValue: '1', colProps: { span: 12 } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
//update-end---author:pi---date:2026-08-04---for:【TKT-001】收款单 formSchema（修复 #9）-----------
