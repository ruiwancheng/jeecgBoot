import { BasicColumn, FormSchema } from '/@/components/Table';

export const columns: BasicColumn[] = [
  { title: '科目编码', dataIndex: 'code', width: 120, sorter: true },
  { title: '科目名称', dataIndex: 'name', width: 200 },
  { title: '科目类别', dataIndex: 'category', width: 100, dictCode: 'mes_subject_category' },
  { title: '级别', dataIndex: 'level', width: 60 },
  { title: '余额方向', dataIndex: 'balanceDirection', width: 80, dictCode: 'mes_balance_direction' },
  { title: '状态', dataIndex: 'status', width: 80, dictCode: 'yn' },
  { title: '备注', dataIndex: 'remark', width: 200 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '科目编码', component: 'Input', colProps: { span: 6 } },
  { field: 'name', label: '科目名称', component: 'Input', colProps: { span: 6 } },
  { field: 'category', label: '科目类别', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_subject_category' }, colProps: { span: 6 } },
];

export const formSchema: FormSchema[] = [
  { field: 'code', label: '科目编码', component: 'Input', required: true, colProps: { span: 24 } },
  { field: 'name', label: '科目名称', component: 'Input', required: true, colProps: { span: 24 } },
  { field: 'category', label: '科目类别', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_subject_category' }, required: true, colProps: { span: 12 } },
  { field: 'level', label: '级别', component: 'InputNumber', defaultValue: 1, colProps: { span: 12 } },
  { field: 'balanceDirection', label: '余额方向', component: 'JDictSelectTag', componentProps: { dictCode: 'mes_balance_direction' }, colProps: { span: 12 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', componentProps: { dictCode: 'yn' }, defaultValue: '1', colProps: { span: 12 } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
