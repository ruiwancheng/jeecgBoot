// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';

// 列定义：按业务字段调整（保留 code/productionOrderId/status 等骨架列）
export const columns: BasicColumn[] = [
  { title: '入库单号', dataIndex: 'code', width: 130 },
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】生产订单列显示编码（_dictText）-----------
  { title: '生产订单', dataIndex: 'productionOrderId_dictText', width: 130 },
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】生产订单列显示编码-----------
  { title: '产品', dataIndex: 'productId_dictText', width: 150 },
  { title: '仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '入库日期', dataIndex: 'receiptDate', width: 110 },
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】status列走statusTag槽位-----------
  // 状态列走 statusTag 槽位（dataIndex 必须为 status，否则 tag 颜色判定失效）
  { title: '状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】status列走statusTag槽位-----------
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '入库单号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'productionOrderId', label: '生产订单', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_completion_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '入库单号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'productionOrderId', label: '生产订单', component: 'Input', required: true, colProps: { span: 8 } },
  { field: 'productId', label: '产品', component: 'JMaterialSelect', required: true, colProps: { span: 8 }, componentProps: {} },
  {
    field: 'warehouseId',
    label: '仓库',
    component: 'ApiSelect',
    required: true,
    colProps: { span: 8 },
    componentProps: { api: queryWarehouseSelect },
  },
  { field: 'receiptDate', label: '入库日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  {
    field: 'status',
    label: '状态',
    component: 'JDictSelectTag',
    colProps: { span: 8 },
    componentProps: { dictCode: 'mes_completion_status' },
    defaultValue: '1',
    show: false,
  },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
