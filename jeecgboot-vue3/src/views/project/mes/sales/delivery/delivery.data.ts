// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';
import { querySalesOrderSelect } from '/@/views/project/mes/sales/order/order.api';

// 列定义：按业务字段调整（保留 code/salesOrderId/status 等骨架列）
export const columns: BasicColumn[] = [
  { title: '发货单编码', dataIndex: 'code', width: 130 },
  { title: '销售订单', dataIndex: 'salesOrderId_dictText', width: 130 },
  { title: '发货仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '发货日期', dataIndex: 'deliveryDate', width: 110 },
  { title: '总金额', dataIndex: 'totalAmount', width: 100 },
  //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】status列走statusTag槽位-----------
  // 状态列走 statusTag 槽位（dataIndex 必须为 status，否则 tag 颜色判定失效）
  { title: '状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】status列走statusTag槽位-----------
  { title: '物流公司', dataIndex: 'logisticsCompany', width: 120 },
  { title: '运单号', dataIndex: 'trackingNo', width: 150 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '发货单编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】发货单搜索补订单下拉（Claude评审#2）-----------
  { field: 'salesOrderId', label: '销售订单', component: 'ApiSelect', colProps: { span: 6 }, componentProps: { api: querySalesOrderSelect } },
  //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】发货单搜索补订单下拉-----------
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_delivery_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  {
    field: 'code',
    label: '发货单编码',
    component: 'Input',
    required: true,
    colProps: { span: 8 },
    componentProps: { maxlength: 50, placeholder: 'DN-YYYYMMDD-001' },
  },
  {
    field: 'salesOrderId',
    label: '销售订单',
    component: 'ApiSelect',
    required: true,
    colProps: { span: 8 },
    componentProps: { api: querySalesOrderSelect },
  },
  {
    field: 'warehouseId',
    label: '发货仓库',
    component: 'ApiSelect',
    required: true,
    colProps: { span: 8 },
    componentProps: { api: queryWarehouseSelect },
  },
  { field: 'deliveryDate', label: '发货日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'logisticsCompany', label: '物流公司', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 100 } },
  { field: 'trackingNo', label: '运单号', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 100 } },
  {
    field: 'status',
    label: '状态',
    component: 'JDictSelectTag',
    colProps: { span: 8 },
    componentProps: { dictCode: 'mes_delivery_status' },
    defaultValue: '1',
    show: false,
  },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
