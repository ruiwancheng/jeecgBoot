import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const priceColumns: BasicColumn[] = [
  { title: '产品ID', dataIndex: 'productId', width: 150 },
  { title: '协议单价', dataIndex: 'price', width: 120 },
  { title: '生效日期', dataIndex: 'beginDate', width: 150 },
  { title: '失效日期', dataIndex: 'endDate', width: 150 },
  { title: '起订数量', dataIndex: 'minQty', width: 100 },
  { title: '截止数量', dataIndex: 'maxQty', width: 100 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const priceFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'customerId', label: 'customerId', component: 'Input', show: false },
  { field: 'productId', label: '产品ID', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'price', label: '协议单价', component: 'InputNumber', required: true, colProps: { span: 12 } },
  { field: 'beginDate', label: '生效日期', component: 'DatePicker', colProps: { span: 12 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'endDate', label: '失效日期', component: 'DatePicker', colProps: { span: 12 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'minQty', label: '起订数量', component: 'InputNumber', colProps: { span: 12 } },
  { field: 'maxQty', label: '截止数量', component: 'InputNumber', colProps: { span: 12 } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
