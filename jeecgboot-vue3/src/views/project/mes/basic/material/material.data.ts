import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '物料编码', dataIndex: 'code', width: 120 },
  { title: '物料名称', dataIndex: 'name', width: 150 },
  { title: '物料类型', dataIndex: 'type_dictText', width: 100 },
  { title: '规格型号', dataIndex: 'spec', width: 150 },
  { title: '单位', dataIndex: 'unit_dictText', width: 80 },
  { title: '标准售价', dataIndex: 'standardPrice', width: 100 },
  { title: '移动平均成本', dataIndex: 'movingAvgCost', width: 110 },
  { title: '最近采购价', dataIndex: 'lastPurchasePrice', width: 100 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '物料编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '物料名称', component: 'Input', colProps: { span: 6 } },
  { field: 'type', label: '物料类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_material_type' } },
  { field: 'spec', label: '规格型号', component: 'Input', colProps: { span: 6 } },
  { field: 'unit', label: '单位', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_material_unit' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '物料编码', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '物料名称', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 100 } },
  { field: 'type', label: '物料类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_material_type' }, required: true },
  { field: 'spec', label: '规格型号', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 100 } },
  { field: 'unit', label: '单位', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_material_unit' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'yn', stringToNumber: true }, defaultValue: 1 },
  { field: 'safetyStock', label: '安全库存', component: 'InputNumber', colProps: { span: 12 }, componentProps: { min: 0 } },
  { field: 'maxStock', label: '最高库存', component: 'InputNumber', colProps: { span: 12 }, componentProps: { min: 0 } },
  { field: 'standardPrice', label: '标准售价', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, precision: 2 } },
  { field: 'movingAvgCost', label: '移动平均成本', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, precision: 4, disabled: true }, ifShow: ({ model }: any) => !!model.id },
  { field: 'lastPurchasePrice', label: '最近采购价', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, precision: 4, disabled: true }, ifShow: ({ model }: any) => !!model.id },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
