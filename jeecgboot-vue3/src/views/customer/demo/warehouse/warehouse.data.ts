import { BasicColumn, FormSchema } from '/@/components/Table';
export const columns: BasicColumn[] = [
  { title: '仓库编码', dataIndex: 'code', width: 120 },
  { title: '仓库名称', dataIndex: 'name', width: 150 },
  { title: '仓库地址', dataIndex: 'address', width: 200 },
  { title: '负责人', dataIndex: 'manager', width: 100 },
  { title: '联系电话', dataIndex: 'phone', width: 130 },
  { title: '状态', dataIndex: 'status', width: 80 },
];
export const searchFormSchema: FormSchema[] = [
  { label: '仓库编码', field: 'code', component: 'Input' },
  { label: '仓库名称', field: 'name', component: 'Input' },
  { label: '状态', field: 'status', component: 'JDictSelectTag', componentProps: { dictCode: 'yn' } },
];
export const formSchema: FormSchema[] = [
  { label: '仓库编码', field: 'code', component: 'Input', required: true },
  { label: '仓库名称', field: 'name', component: 'Input', required: true },
  { label: '仓库地址', field: 'address', component: 'InputTextArea' },
  { label: '负责人', field: 'manager', component: 'Input' },
  { label: '联系电话', field: 'phone', component: 'Input' },
  { label: '状态', field: 'status', component: 'JDictSelectTag', componentProps: { dictCode: 'yn' }, defaultValue: 1 },
];
