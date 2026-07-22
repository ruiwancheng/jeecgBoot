import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { querySupplierSelect } from './order.api';

export const columns: BasicColumn[] = [
  { title: '订单编号', dataIndex: 'code', width: 130 },
  { title: '供应商', dataIndex: 'supplierId_dictText', width: 150 },
  { title: '采购类型', dataIndex: 'purchaseType_dictText', width: 80 },
  { title: '订单日期', dataIndex: 'orderDate', width: 110 },
  { title: '交货日期', dataIndex: 'deliveryDate', width: 110 },
  { title: '不含税金额', dataIndex: 'totalAmount', width: 100 },
  { title: '含税总额', dataIndex: 'totalWithTax', width: 100 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '订单编号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'supplierId', label: '供应商', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '订单状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_purchase_order_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '订单编号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50, placeholder: 'PO-YYYYMMDD-001' } },
  { field: 'supplierId', label: '供应商', component: 'ApiSelect', required: true, colProps: { span: 8 }, componentProps: { api: querySupplierSelect } },
  { field: 'purchaseType', label: '采购类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_purchase_type' } },
  { field: 'orderDate', label: '订单日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'deliveryDate', label: '交货日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'paymentTerms', label: '付款条款', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_purchase_order_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
