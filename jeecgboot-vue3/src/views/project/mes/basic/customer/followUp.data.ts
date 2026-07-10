import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const followUpColumns: BasicColumn[] = [
  { title: '跟进日期', dataIndex: 'followDate', width: 150 },
  { title: '跟进方式', dataIndex: 'followType_dictText', width: 100 },
  { title: '跟进内容', dataIndex: 'content', width: 250 },
  { title: '跟进人', dataIndex: 'follower', width: 100 },
  { title: '下次跟进', dataIndex: 'nextDate', width: 150 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const followUpFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'customerId', label: 'customerId', component: 'Input', show: false },
  { field: 'followType', label: '跟进方式', component: 'JDictSelectTag', required: true, colProps: { span: 12 }, componentProps: { dictCode: 'follow_type' } },
  { field: 'followDate', label: '跟进日期', component: 'DatePicker', required: true, colProps: { span: 12 }, componentProps: { showTime: true, valueFormat: 'YYYY-MM-DD HH:mm:ss' } },
  { field: 'content', label: '跟进内容', component: 'InputTextArea', required: true, colProps: { span: 24 }, componentProps: { rows: 4 } },
  { field: 'nextDate', label: '下次跟进日期', component: 'DatePicker', colProps: { span: 12 }, componentProps: { showTime: true, valueFormat: 'YYYY-MM-DD HH:mm:ss' } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
