// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryCustomerSelect } from '/@/views/project/mes/basic/customer/customer.api';

// 列定义：按业务字段调整（保留 code/customerId/status 等骨架列）
export const columns: BasicColumn[] = [
  { title: '订单编码', dataIndex: 'code', width: 130 },
  { title: '客户', dataIndex: 'customerId_dictText', width: 150 },
  { title: '订单日期', dataIndex: 'orderDate', width: 110 },
  { title: '交货日期', dataIndex: 'deliveryDate', width: 110 },
  //update-begin---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】status列走statusTag槽位-----------
  // 状态列走 statusTag 槽位（dataIndex 必须为 status，否则 tag 颜色判定失效）
  { title: '订单状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  //update-end---author:ruiwancheng---date:20260730---for:【销售链路黄金模板对齐】status列走statusTag槽位-----------
  { title: '总金额', dataIndex: 'totalAmount', width: 100 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '订单编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'customerId', label: '客户', component: 'ApiSelect', colProps: { span: 6 }, componentProps: { api: queryCustomerSelect } },
  { field: 'status', label: '订单状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_order_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  {
    field: 'code',
    label: '订单编码',
    component: 'Input',
    required: true,
    colProps: { span: 8 },
    componentProps: { maxlength: 50, placeholder: 'SO-YYYYMMDD-001' },
  },
  { field: 'customerId', label: '客户', component: 'ApiSelect', required: true, colProps: { span: 8 }, componentProps: { api: queryCustomerSelect } },
  { field: 'orderDate', label: '订单日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'deliveryDate', label: '交货日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  {
    field: 'status',
    label: '订单状态',
    component: 'JDictSelectTag',
    colProps: { span: 8 },
    componentProps: { dictCode: 'mes_order_status' },
    defaultValue: '1',
    show: false,
  },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
