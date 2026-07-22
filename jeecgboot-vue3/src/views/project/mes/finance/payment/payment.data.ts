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
