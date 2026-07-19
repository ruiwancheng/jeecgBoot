import { BasicColumn, FormSchema } from '/@/components/Table';

export const columns: BasicColumn[] = [
  { title: '应收单号', dataIndex: 'code', width: 180 },
  { title: '来源单据号', dataIndex: 'sourceBillNo', width: 150 },
  { title: '应收金额', dataIndex: 'amount', width: 120 },
  { title: '已收金额', dataIndex: 'receivedAmount', width: 120 },
  { title: '未结金额', dataIndex: 'unsettledAmount', width: 120 },
  { title: '到期日', dataIndex: 'dueDate', width: 120 },
  { title: '状态', dataIndex: 'status', width: 100, dictCode: 'mes_receivable_status' },
  { title: '来源类型', dataIndex: 'sourceType', width: 100 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '应收单号', component: 'Input', colProps: { span: 6 } },
  { field: 'sourceBillNo', label: '来源单据号', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_receivable_status' }, colProps: { span: 6 } },
];
