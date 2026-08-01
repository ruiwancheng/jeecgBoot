// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryMaterialSelect } from '../../basic/material/material.api';

export const columns: BasicColumn[] = [
  { title: '批次号', dataIndex: 'batchNo', width: 180 },
  { title: '物料', dataIndex: 'materialId_dictText', width: 150 },
  { title: '来源类型', dataIndex: 'originType_dictText', width: 100 },
  { title: '来源单据', dataIndex: 'originBillNo', width: 140 },
  { title: '初始数量', dataIndex: 'qty', width: 100 },
  { title: '批次成本', dataIndex: 'unitCost', width: 100 },
  { title: '生产日期', dataIndex: 'productionDate', width: 110 },
  //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次列表"有效期"改名+增加保质期列-----------
  { title: '保质期(天)', dataIndex: 'shelfLife', width: 100 },
  { title: '有效期至', dataIndex: 'expiryDate', width: 110 },
  //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次列表"有效期"改名+增加保质期列-----------
  //update-begin---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】status列走statusTag槽位-----------
  // 状态列走 statusTag 槽位
  { title: '状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  //update-end---author:ruiwancheng---date:20260731---for:【批次链路黄金模板对齐】status列走statusTag槽位-----------
];

export const searchFormSchema: FormSchema[] = [
  { field: 'batchNo', label: '批次号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'materialId', label: '物料', component: 'ApiSelect', colProps: { span: 6 }, componentProps: { api: queryMaterialSelect } },
  {
    field: 'originType',
    label: '来源类型',
    component: 'JDictSelectTag',
    colProps: { span: 6 },
    componentProps: { dictCode: 'mes_batch_origin_type' },
  },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_batch_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  {
    field: 'batchNo',
    label: '批次号(系统生成)',
    component: 'Input',
    colProps: { span: 12 },
    componentProps: { disabled: true, placeholder: '保存时系统自动生成 BT-{物料编码}-{YYYYMMDD}-{序号}' },
  },
  { field: 'materialId', label: '物料', component: 'ApiSelect', required: true, colProps: { span: 8 }, componentProps: { api: queryMaterialSelect } },
  {
    field: 'originType',
    label: '来源类型',
    component: 'JDictSelectTag',
    required: true,
    colProps: { span: 8 },
    componentProps: { dictCode: 'mes_batch_origin_type' },
  },
  {
    field: 'qty',
    label: '数量',
    component: 'InputNumber',
    required: true,
    colProps: { span: 8 },
    componentProps: { min: 0.0001, step: 1, precision: 4 },
  },
  { field: 'unitCost', label: '批次单位成本', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, step: 0.01, precision: 4 } },
  { field: 'productionDate', label: '生产日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次表单"有效期"改名+增加保质期字段-----------
  { field: 'shelfLife', label: '保质期(天)', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  { field: 'expiryDate', label: '有效期至', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-批次表单"有效期"改名+增加保质期字段-----------
  {
    field: 'status',
    label: '状态',
    component: 'JDictSelectTag',
    colProps: { span: 8 },
    componentProps: { dictCode: 'mes_batch_status' },
    defaultValue: '1',
    show: false,
  },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
