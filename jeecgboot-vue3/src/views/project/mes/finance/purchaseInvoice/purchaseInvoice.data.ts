import { BasicColumn, FormSchema } from '/@/components/Table';
import { querySupplierSelect } from '/@/views/project/mes/purchase/order/order.api';
export const columns: BasicColumn[] = [
  { title: '发票单号', dataIndex: 'code', width: 130 }, { title: '发票号码', dataIndex: 'invoiceNo', width: 130 },
  { title: '供应商', dataIndex: 'supplierId', width: 150, dictTable: 'c_mes_supplier', dictText: 'name', dictCode: 'id' },
  { title: '收票日期', dataIndex: 'invoiceDate', width: 110 }, { title: '不含税金额', dataIndex: 'amount', width: 110 },
  { title: '税额', dataIndex: 'taxAmount', width: 100 }, { title: '价税合计', dataIndex: 'totalWithTax', width: 110 },
  { title: '发票类型', dataIndex: 'invoiceType', width: 100, dictCode: 'mes_invoice_type' },
  { title: '状态', dataIndex: 'status', width: 80, dictCode: 'yn' },
];
export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '发票单号', component: 'Input', colProps: { span: 6 } },
  { field: 'supplierId', label: '供应商', component: 'ApiSelect', componentProps: { api: querySupplierSelect }, colProps: { span: 6 } },
];
export const formSchema: FormSchema[] = [
  { field: 'code', label: '发票单号', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'invoiceNo', label: '发票号码', component: 'Input', colProps: { span: 12 } },
  { field: 'supplierId', label: '供应商', component: 'ApiSelect', componentProps: { api: querySupplierSelect }, required: true, colProps: { span: 12 } },
  { field: 'invoiceDate', label: '收票日期', component: 'DatePicker', componentProps: { valueFormat: 'YYYY-MM-DD' }, colProps: { span: 12 } },
  { field: 'amount', label: '不含税金额', component: 'InputNumber', colProps: { span: 8 } },
  { field: 'taxRate', label: '税率', component: 'InputNumber', defaultValue: 0.13, componentProps: { min: 0, max: 1, step: 0.01 }, colProps: { span: 8 } },
  { field: 'invoiceType', label: '发票类型', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_invoice_type' }, defaultValue: '1', colProps: { span: 8 } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
