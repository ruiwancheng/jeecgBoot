// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { querySupplierSelect } from './apply.api';

// 列定义：按业务字段调整（保留 code/supplierId/status 等骨架列）
export const columns: BasicColumn[] = [
  { title: '申请单号', dataIndex: 'code', width: 130 },
  { title: '供应商', dataIndex: 'supplierId_dictText', width: 150 },
  { title: '采购类型', dataIndex: 'purchaseType_dictText', width: 80 },
  { title: '申请部门', dataIndex: 'deptId', width: 120 },
  { title: '申请人', dataIndex: 'applicantId', width: 100 },
  { title: '申请日期', dataIndex: 'applyDate', width: 110 },
  { title: '需求日期', dataIndex: 'requiredDate', width: 110 },
  //update-begin---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】status列走statusTag槽位-----------
  // 状态列走 statusTag 槽位（dataIndex 必须为 status，否则 tag 颜色判定失效）
  { title: '申请状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  //update-end---author:ruiwancheng---date:20260730---for:【采购链路黄金模板对齐】status列走statusTag槽位-----------
  { title: '申请金额', dataIndex: 'totalAmount', width: 100 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '申请单号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'supplierId', label: '供应商', component: 'Input', colProps: { span: 6 } },
  { field: 'applicantId', label: '申请人', component: 'Input', colProps: { span: 6 } },
  {
    field: 'status',
    label: '申请状态',
    component: 'JDictSelectTag',
    colProps: { span: 6 },
    componentProps: { dictCode: 'mes_purchase_apply_status' },
  },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '申请单号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  {
    field: 'supplierId',
    label: '供应商',
    component: 'ApiSelect',
    required: true,
    colProps: { span: 8 },
    componentProps: { api: querySupplierSelect },
  },
  { field: 'purchaseType', label: '采购类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_purchase_type' } },
  { field: 'deptId', label: '申请部门', component: 'Input', colProps: { span: 8 } },
  { field: 'applicantId', label: '申请人', component: 'Input', colProps: { span: 8 } },
  { field: 'applyDate', label: '申请日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'requiredDate', label: '需求日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'budgetSubject', label: '预算科目', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  {
    field: 'status',
    label: '状态',
    component: 'JDictSelectTag',
    colProps: { span: 8 },
    componentProps: { dictCode: 'mes_purchase_apply_status' },
    defaultValue: '1',
    show: false,
  },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
