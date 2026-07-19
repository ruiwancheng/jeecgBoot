import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '订单编码', dataIndex: 'code', width: 130 },
  { title: '客户', dataIndex: 'customerId_dictText', width: 150 },
  { title: '订单日期', dataIndex: 'orderDate', width: 110 },
  { title: '交货日期', dataIndex: 'deliveryDate', width: 110 },
  { title: '订单状态', dataIndex: 'status_dictText', width: 80 },
  { title: '总金额', dataIndex: 'totalAmount', width: 100 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '订单编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'customerId', label: '客户', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '订单状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_order_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '订单编码', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50, placeholder: 'SO-YYYYMMDD-001' } },
  { field: 'customerId', label: '客户', component: 'JSearchSelect', required: true, colProps: { span: 8 }, componentProps: { dict: 'c_mes_customer,name,id' } },
  { field: 'orderDate', label: '订单日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'deliveryDate', label: '交货日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'status', label: '订单状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_order_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
