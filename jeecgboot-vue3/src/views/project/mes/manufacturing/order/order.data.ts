// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';

// 列定义：按业务字段调整（保留 code/productId/status 等骨架列）
export const columns: BasicColumn[] = [
  { title: '订单编号', dataIndex: 'code', width: 130 },
  { title: '生产产品', dataIndex: 'productId_dictText', width: 150 },
  { title: 'BOM版本', dataIndex: 'bomId', width: 120 },
  { title: '计划数量', dataIndex: 'planQty', width: 100 },
  { title: '已完工', dataIndex: 'completedQty', width: 80 },
  { title: '开工日期', dataIndex: 'startDate', width: 110 },
  { title: '完工日期', dataIndex: 'endDate', width: 110 },
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】status列走statusTag槽位-----------
  // 状态列走 statusTag 槽位（dataIndex 必须为 status，否则 tag 颜色判定失效）
  { title: '状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】status列走statusTag槽位-----------
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '订单编号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'productId', label: '生产产品', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_production_order_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  {
    field: 'code',
    label: '订单编号',
    component: 'Input',
    required: true,
    colProps: { span: 8 },
    componentProps: { maxlength: 50, placeholder: 'MO-YYYYMMDD-001' },
  },
  { field: 'productId', label: '生产产品', component: 'JMaterialSelect', required: true, colProps: { span: 8 }, componentProps: {} },
  { field: 'bomId', label: 'BOM版本', component: 'Input', colProps: { span: 8 } },
  { field: 'planQty', label: '计划数量', component: 'InputNumber', required: true, colProps: { span: 8 }, componentProps: { min: 0.01, step: 1 } },
  { field: 'startDate', label: '开工日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'endDate', label: '完工日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'warehouseId', label: '完工仓库', component: 'ApiSelect', colProps: { span: 8 }, componentProps: { api: queryWarehouseSelect } },
  {
    field: 'status',
    label: '状态',
    component: 'JDictSelectTag',
    colProps: { span: 8 },
    componentProps: { dictCode: 'mes_production_order_status' },
    defaultValue: '1',
    show: false,
  },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
