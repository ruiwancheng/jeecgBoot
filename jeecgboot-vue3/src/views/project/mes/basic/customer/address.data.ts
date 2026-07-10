import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const addressColumns: BasicColumn[] = [
  { title: '类型', dataIndex: 'addressType_dictText', width: 100 },
  { title: '联系人', dataIndex: 'contact', width: 100 },
  { title: '电话', dataIndex: 'phone', width: 130 },
  { title: '省/市/区', dataIndex: 'province', width: 200, customRender: ({ record }) => [record.province, record.city, record.district].filter(Boolean).join('/') },
  { title: '详细地址', dataIndex: 'detail', width: 250 },
  { title: '默认', dataIndex: 'isDefault', width: 60, customRender: ({ value }) => (value ? '是' : '') },
];

export const addressFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'customerId', label: 'customerId', component: 'Input', show: false },
  { field: 'addressType', label: '地址类型', component: 'JDictSelectTag', required: true, colProps: { span: 12 }, componentProps: { dictCode: 'address_type' } },
  { field: 'contact', label: '联系人', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'phone', label: '联系电话', component: 'Input', required: true, colProps: { span: 12 } },
  { field: 'province', label: '省', component: 'Input', colProps: { span: 8 } },
  { field: 'city', label: '市', component: 'Input', colProps: { span: 8 } },
  { field: 'district', label: '区', component: 'Input', colProps: { span: 8 } },
  { field: 'detail', label: '详细地址', component: 'InputTextArea', required: true, colProps: { span: 24 } },
  { field: 'isDefault', label: '是否默认', component: 'Switch', colProps: { span: 12 }, defaultValue: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
