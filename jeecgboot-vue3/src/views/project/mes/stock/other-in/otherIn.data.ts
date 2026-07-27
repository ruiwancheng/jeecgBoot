import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '入库单号', dataIndex: 'code', width: 150 },
  { title: '入库类型', dataIndex: 'inType_dictText', width: 100 },
  { title: '原因', dataIndex: 'reason', width: 160 },
  { title: '入库日期', dataIndex: 'stockDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '单号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'inType', label: '入库类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_other_stock_in_type' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_other_stock_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '入库单号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50, placeholder: 'QT-IN-YYYYMMDD-0001' } },
  { field: 'inType', label: '入库类型', component: 'JDictSelectTag', required: true, colProps: { span: 8 }, componentProps: { dictCode: 'mes_other_stock_in_type' } },
  { field: 'stockDate', label: '入库日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'reason', label: '原因', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500, placeholder: '手工填写入库原因' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_other_stock_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
