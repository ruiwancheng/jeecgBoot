import { BasicColumn, FormSchema } from '/@/components/Table';

export const columns: BasicColumn[] = [
  { title: '应付单号', dataIndex: 'code', width: 180 },
  { title: '供应商', dataIndex: 'supplierId', width: 150, dictTable: 'c_mes_supplier', dictText: 'name', dictCode: 'id' },
  { title: '来源单据号', dataIndex: 'sourceBillNo', width: 150 },
  { title: '应付金额', dataIndex: 'amount', width: 120 },
  { title: '税额', dataIndex: 'taxAmount', width: 100 },
  { title: '已付金额', dataIndex: 'paidAmount', width: 120 },
  { title: '未付金额', dataIndex: 'unsettledAmount', width: 120 },
  { title: '到期日', dataIndex: 'dueDate', width: 120 },
  { title: '状态', dataIndex: 'status', width: 100, dictCode: 'mes_payable_status' },
  { title: '来源类型', dataIndex: 'sourceType', width: 100 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '应付单号', component: 'Input', colProps: { span: 6 } },
  { field: 'sourceBillNo', label: '来源单据号', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_payable_status' }, colProps: { span: 6 } },
];
