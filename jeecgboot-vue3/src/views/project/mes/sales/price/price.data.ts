import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryCustomerSelect } from '/@/views/project/mes/basic/customer/customer.api';

export const columns: BasicColumn[] = [
  { title: '价格编码', dataIndex: 'code', width: 120 },
  { title: '物料名称', dataIndex: 'materialId_dictText', width: 150 },
  { title: '客户', dataIndex: 'customerId_dictText', width: 120 },
  { title: '价格', dataIndex: 'price', width: 100 },
  { title: '价格类型', dataIndex: 'type_dictText', width: 100 },
  { title: '生效日期', dataIndex: 'beginDate', width: 110 },
  { title: '失效日期', dataIndex: 'endDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '价格编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'type', label: '价格类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_price_type' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '价格编码', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  //update-begin---author:ruiwancheng---date:2026-07-14---for: 审计修复-物料+客户用JSearchSelect表字典搜索-----------
  { field: 'materialId', label: '物料', component: 'JMaterialSelect', required: true, colProps: { span: 8 }, componentProps: {} },
  { field: 'type', label: '价格类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_price_type' }, required: true, defaultValue: '1' },
  { field: 'customerId', label: '客户', component: 'ApiSelect', colProps: { span: 8 }, componentProps: { api: queryCustomerSelect } },
  //update-end---author:ruiwancheng---date:2026-07-14---for: 审计修复-物料+客户用JSearchSelect表字典搜索-----------
  { field: 'price', label: '价格', component: 'InputNumber', required: true, colProps: { span: 8 }, componentProps: { min: 0, precision: 2 } },
  { field: 'beginDate', label: '生效日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'endDate', label: '失效日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'yn', stringToNumber: true }, defaultValue: 1 },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
