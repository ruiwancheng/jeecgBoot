import { BasicColumn, FormSchema } from '/@/components/Table';
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
  { field: 'customerId', label: '客户', component: 'JSearchSelect', componentProps: { dict: 'c_mes_customer,name,id' }, colProps: { span: 6 } },
];
