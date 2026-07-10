import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const contactColumns: BasicColumn[] = [
  { title: '姓名', dataIndex: 'name', width: 100 },
  { title: '职务', dataIndex: 'title', width: 100 },
  { title: '手机', dataIndex: 'phone', width: 130 },
  { title: '邮箱', dataIndex: 'email', width: 180 },
  { title: 'QQ/微信', dataIndex: 'social', width: 120 },
  { title: '默认', dataIndex: 'isDefault', width: 60, customRender: ({ value }) => (value ? '是' : '') },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const contactFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'customerId', label: 'customerId', component: 'Input', show: false },
  { field: 'name', label: '联系人姓名', component: 'Input', required: true, colProps: { span: 24 } },
  { field: 'title', label: '职务', component: 'Input', colProps: { span: 12 } },
  { field: 'phone', label: '手机', component: 'Input', colProps: { span: 12 } },
  { field: 'email', label: '邮箱', component: 'Input', colProps: { span: 12 } },
  { field: 'social', label: 'QQ/微信', component: 'Input', colProps: { span: 12 } },
  { field: 'isDefault', label: '是否默认', component: 'Switch', colProps: { span: 12 }, defaultValue: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
