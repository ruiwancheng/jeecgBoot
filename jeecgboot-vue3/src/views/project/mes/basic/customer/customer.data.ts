import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '客户编码', dataIndex: 'code', width: 120 },
  { title: '客户名称', dataIndex: 'name', width: 150 },
  { title: '客户类型', dataIndex: 'type_dictText', width: 100 },
  { title: '联系人', dataIndex: 'contact', width: 100 },
  { title: '联系电话', dataIndex: 'phone', width: 130 },
  { title: '地址', dataIndex: 'address', width: 200 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 200 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '客户编码', component: 'Input', colProps: { span: 6 } },
  { field: 'name', label: '客户名称', component: 'Input', colProps: { span: 6 } },
  { field: 'type', label: '客户类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_type' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '客户编码', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'name', label: '客户名称', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'type', label: '客户类型', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'mes_customer_type' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'yn', type: 'radioButton', stringToNumber: true }, defaultValue: 1 },
  { field: 'contact', label: '联系人', component: 'Input', colProps: { span: 12 } },
  { field: 'phone', label: '联系电话', component: 'Input', colProps: { span: 12 } },
  { field: 'address', label: '地址', component: 'Input', colProps: { span: 24 } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
