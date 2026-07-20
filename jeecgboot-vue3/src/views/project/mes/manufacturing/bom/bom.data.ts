import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: 'BOM编号', dataIndex: 'code', width: 130 },
  { title: '父项物料', dataIndex: 'productId_dictText', width: 150 },
  { title: '版本', dataIndex: 'version', width: 80 },
  { title: '生效日期', dataIndex: 'effectiveDate', width: 110 },
  { title: '失效日期', dataIndex: 'expiryDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: 'BOM编号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'productId', label: '父项物料', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_bom_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: 'BOM编号', component: 'Input', required: true, colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'productId', label: '父项物料', component: 'JMaterialSelect', required: true, colProps: { span: 6 }, componentProps: {} },
  { field: 'version', label: '版本号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 20 } },
  { field: 'effectiveDate', label: '生效日期', component: 'DatePicker', colProps: { span: 6 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'expiryDate', label: '失效日期', component: 'DatePicker', colProps: { span: 6 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_bom_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
