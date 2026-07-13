import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '库位编码', dataIndex: 'code', width: 180 },
  { title: '库位名称', dataIndex: 'name', width: 150 },
  { title: '所属仓库', dataIndex: 'warehouseId', width: 120 },
  { title: '最大容量', dataIndex: 'maxCapacity', width: 100 },
  { title: '承重(kg)', dataIndex: 'loadCapacity', width: 100 },
  { title: '存放限制', dataIndex: 'storageLimit', width: 150 },
  { title: '长(cm)', dataIndex: 'length', width: 80 },
  { title: '宽(cm)', dataIndex: 'width', width: 80 },
  { title: '高(cm)', dataIndex: 'height', width: 80 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '库位编码', component: 'Input', colProps: { span: 6 } },
  { field: 'zoneId', label: '库区ID', component: 'Input', show: false },
  { field: 'shelfId', label: '货架ID', component: 'Input', show: false },
  { field: 'warehouseId', label: '仓库ID', component: 'Input', show: false },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'warehouseId', label: '所属仓库', component: 'Input', show: false },
  { field: 'zoneId', label: '所属库区', component: 'Input', show: false },
  { field: 'shelfId', label: '所属货架', component: 'Input', show: false },
  { field: 'code', label: '库位编码', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '库位名称', component: 'Input', colProps: { span: 12 }, componentProps: { maxlength: 100 } },
  { field: 'maxCapacity', label: '最大容量', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  { field: 'loadCapacity', label: '承重(kg)', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  { field: 'storageLimit', label: '存放限制', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 255 } },
  { field: 'length', label: '长(cm)', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  { field: 'width', label: '宽(cm)', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  { field: 'height', label: '高(cm)', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'yn', type: 'radioButton', stringToNumber: true }, defaultValue: 1 },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];

export const generateFormSchema: FormSchema[] = [
  { field: 'shelfId', label: '所属货架', component: 'Input', show: false },
  { field: 'rows', label: '行数', component: 'InputNumber', required: true, colProps: { span: 12 }, defaultValue: 1, componentProps: { min: 1 } },
  { field: 'cols', label: '列数', component: 'InputNumber', required: true, colProps: { span: 12 }, defaultValue: 1, componentProps: { min: 1 } },
];

export const zoneFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'warehouseId', label: '所属仓库', component: 'Input', show: false },
  { field: 'code', label: '库区编码', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '库区名称', component: 'Input', colProps: { span: 12 }, componentProps: { maxlength: 100 } },
  { field: 'sortNo', label: '排序号', component: 'InputNumber', colProps: { span: 12 }, defaultValue: 0, componentProps: { min: 0 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'yn', type: 'radioButton', stringToNumber: true }, defaultValue: 1 },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];

export const shelfFormSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'zoneId', label: '所属库区', component: 'Input', show: false },
  { field: 'warehouseId', label: '所属仓库', component: 'Input', show: false },
  { field: 'code', label: '货架编码', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '货架名称', component: 'Input', colProps: { span: 12 }, componentProps: { maxlength: 100 } },
  { field: 'sortNo', label: '排序号', component: 'InputNumber', colProps: { span: 12 }, defaultValue: 0, componentProps: { min: 0 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'yn', type: 'radioButton', stringToNumber: true }, defaultValue: 1 },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
