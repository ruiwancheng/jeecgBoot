import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '订单编号', dataIndex: 'code', width: 130 },
  { title: '生产产品', dataIndex: 'productId_dictText', width: 150 },
  { title: 'BOM版本', dataIndex: 'bomId', width: 120 },
  { title: '计划数量', dataIndex: 'planQty', width: 100 },
  { title: '已完工', dataIndex: 'completedQty', width: 80 },
  { title: '开工日期', dataIndex: 'startDate', width: 110 },
  { title: '完工日期', dataIndex: 'endDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '订单编号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'productId', label: '生产产品', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_production_order_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '订单编号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'productId', label: '生产产品', component: 'JSearchSelect', required: true, colProps: { span: 8 }, componentProps: { dict: 'c_mes_material,name,id' } },
  { field: 'bomId', label: 'BOM版本', component: 'Input', colProps: { span: 8 } },
  { field: 'planQty', label: '计划数量', component: 'InputNumber', required: true, colProps: { span: 8 }, componentProps: { min: 0.01, step: 1 } },
  { field: 'startDate', label: '开工日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'endDate', label: '完工日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'warehouseId', label: '完工仓库', component: 'JSearchSelect', colProps: { span: 8 }, componentProps: { dict: 'c_mes_warehouse,name,id' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_production_order_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
