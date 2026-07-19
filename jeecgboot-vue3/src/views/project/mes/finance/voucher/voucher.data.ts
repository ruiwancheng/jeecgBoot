import { BasicColumn, FormSchema } from '/@/components/Table';

export const columns: BasicColumn[] = [
  { title: '凭证号', dataIndex: 'voucherNo', width: 150 },
  { title: '凭证日期', dataIndex: 'voucherDate', width: 120 },
  { title: '借方合计', dataIndex: 'totalDebit', width: 120 },
  { title: '贷方合计', dataIndex: 'totalCredit', width: 120 },
  { title: '来源类型', dataIndex: 'sourceType', width: 100, dictCode: 'mes_voucher_source' },
  { title: '状态', dataIndex: 'status', width: 100, dictCode: 'mes_voucher_status' },
  { title: '摘要', dataIndex: 'remark', width: 200 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'voucherNo', label: '凭证号', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_voucher_status' }, colProps: { span: 6 } },
];

export const formSchema: FormSchema[] = [
  { field: 'voucherNo', label: '凭证号', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'voucherDate', label: '凭证日期', component: 'DatePicker', componentProps: { valueFormat: 'YYYY-MM-DD' }, required: true, colProps: { span: 12 } },
  { field: 'sourceType', label: '来源类型', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_voucher_source' }, defaultValue: '1', colProps: { span: 12 } },
  { field: 'remark', label: '摘要', component: 'InputTextArea', colProps: { span: 24 } },
];
