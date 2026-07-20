import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '规则编码', dataIndex: 'ruleCode', width: 100 },
  { title: '规则名称', dataIndex: 'ruleName', width: 150 },
  { title: '前缀', dataIndex: 'prefix', width: 80 },
  { title: '日期格式', dataIndex: 'dateFormat', width: 100 },
  { title: '流水号位数', dataIndex: 'seqLength', width: 100 },
  { title: '重置周期', dataIndex: 'resetCycle_dictText', width: 100 },
  { title: '当前流水号', dataIndex: 'currentSeq', width: 100 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'ruleCode', label: '规则编码', component: 'Input', colProps: { span: 6 } },
  { field: 'ruleName', label: '规则名称', component: 'Input', colProps: { span: 6 } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'ruleCode', label: '规则编码', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 30, placeholder: '如 SO/PO/MO' } },
  { field: 'ruleName', label: '规则名称', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'prefix', label: '前缀', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 20 } },
  { field: 'dateFormat', label: '日期格式', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_date_format' }, defaultValue: 'yyyyMMdd' },
  { field: 'seqLength', label: '流水号位数', component: 'InputNumber', required: true, colProps: { span: 8 }, componentProps: { min: 2, max: 10 }, defaultValue: 4 },
  { field: 'resetCycle', label: '重置周期', component: 'JDictSelectTag', required: true, colProps: { span: 8 }, componentProps: { dictCode: 'mes_reset_cycle' }, defaultValue: 'DAILY' },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
