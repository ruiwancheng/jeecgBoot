import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '仓库编码', dataIndex: 'code', width: 120 },
  { title: '仓库名称', dataIndex: 'name', width: 150 },
  { title: '仓库类型', dataIndex: 'type_dictText', width: 100 },
  { title: '仓库地址', dataIndex: 'address', width: 200 },
  { title: '负责人', dataIndex: 'manager', width: 100 },
  { title: '联系电话', dataIndex: 'phone', width: 120 },
  { title: '所属工厂', dataIndex: 'factory', width: 120 },
  { title: '所属车间', dataIndex: 'workshop', width: 120 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 200 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '仓库编码', component: 'Input', colProps: { span: 6 } },
  { field: 'name', label: '仓库名称', component: 'Input', colProps: { span: 6 } },
  { field: 'type', label: '仓库类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_warehouse_type' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '仓库编码', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '仓库名称', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 100 } },
  { field: 'type', label: '仓库类型', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'mes_warehouse_type' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'yn', type: 'radioButton', stringToNumber: true }, defaultValue: 1 },
  { field: 'address', label: '仓库地址', component: 'Input', colProps: { span: 24 }, componentProps: { maxlength: 300 } },
  { field: 'manager', label: '负责人', component: 'Input', colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'phone', label: '联系电话', component: 'Input', colProps: { span: 12 }, componentProps: { maxlength: 20 } },
  { field: 'factory', label: '所属工厂', component: 'Input', colProps: { span: 12 } },
  { field: 'workshop', label: '所属车间', component: 'Input', colProps: { span: 12 } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
