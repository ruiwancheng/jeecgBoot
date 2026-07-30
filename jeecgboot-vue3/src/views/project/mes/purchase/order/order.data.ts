// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { querySupplierSelect } from './order.api';

// 列定义：按业务字段调整（保留 code/purchaseApplyId/status 等骨架列）
export const columns: BasicColumn[] = [
  { title: '订单编号', dataIndex: 'code', width: 130 },
  //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】Claude评审#1 @Dict 后自动带编码-----------
  { title: '申请单号', dataIndex: 'purchaseApplyId_dictText', width: 130 },
  //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】申请单号显示编码-----------
  { title: '供应商', dataIndex: 'supplierId_dictText', width: 150 },
  { title: '采购类型', dataIndex: 'purchaseType_dictText', width: 80 },
  { title: '订单日期', dataIndex: 'orderDate', width: 110 },
  { title: '交货日期', dataIndex: 'deliveryDate', width: 110 },
  { title: '不含税金额', dataIndex: 'totalAmount', width: 100 },
  { title: '税额', dataIndex: 'taxAmount', width: 100 },
  { title: '含税总额', dataIndex: 'totalWithTax', width: 100 },
  //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】status列走statusTag槽位-----------
  // 状态列走 statusTag 槽位（dataIndex 必须为 status，否则 tag 颜色判定失效）
  { title: '状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】status列走statusTag槽位-----------
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '订单编号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'purchaseApplyId', label: '申请单号', component: 'Input', colProps: { span: 6 } },
  { field: 'supplierId', label: '供应商', component: 'Input', colProps: { span: 6 } },
  {
    field: 'status',
    label: '订单状态',
    component: 'JDictSelectTag',
    colProps: { span: 6 },
    componentProps: { dictCode: 'mes_purchase_order_status' },
  },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  {
    field: 'code',
    label: '订单编号',
    component: 'Input',
    required: true,
    colProps: { span: 8 },
    componentProps: { maxlength: 50, placeholder: 'PO-YYYYMMDD-001' },
  },
  {
    field: 'supplierId',
    label: '供应商',
    component: 'ApiSelect',
    required: true,
    colProps: { span: 8 },
    componentProps: { api: querySupplierSelect },
  },
  { field: 'purchaseType', label: '采购类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_purchase_type' } },
  { field: 'orderDate', label: '订单日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'deliveryDate', label: '交货日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'paymentTerms', label: '付款条款', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  {
    field: 'status',
    label: '状态',
    component: 'JDictSelectTag',
    colProps: { span: 8 },
    componentProps: { dictCode: 'mes_purchase_order_status' },
    defaultValue: '1',
    show: false,
  },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
