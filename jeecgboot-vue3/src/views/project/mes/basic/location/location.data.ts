import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '库位编码', dataIndex: 'code', width: 180 },
  { title: '库位名称', dataIndex: 'name', width: 150 },
  { title: '库位类型', dataIndex: 'type_dictText', width: 100 },
  { title: '最大容量', dataIndex: 'maxCapacity', width: 100 },
  { title: '承重(kg)', dataIndex: 'loadCapacity', width: 100 },
  { title: '存放限制', dataIndex: 'storageLimit', width: 150 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 200 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '库位编码', component: 'Input', colProps: { span: 6 } },
  { field: 'warehouseId', label: '仓库ID', component: 'Input', show: false },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'warehouseId', label: '所属仓库', component: 'Input', show: false },
  { field: 'code', label: '库位编码', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '库位名称', component: 'Input', colProps: { span: 12 }, componentProps: { maxlength: 100 } },
  { field: 'maxCapacity', label: '最大容量', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  { field: 'loadCapacity', label: '承重(kg)', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  { field: 'storageLimit', label: '存放限制', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 255 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'yn', type: 'radioButton', stringToNumber: true }, defaultValue: 1 },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];

export const generateFormSchema: FormSchema[] = [
  { field: 'warehouseId', label: '仓库ID', component: 'Input', show: false },
  { field: 'count', label: '生成数量', component: 'InputNumber', required: true, colProps: { span: 24 }, defaultValue: 10, componentProps: { min: 1, max: 1000 } },
];
