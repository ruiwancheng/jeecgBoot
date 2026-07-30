// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

// 列定义：按业务字段调整（保留 code/productId/status 等骨架列）
export const columns: BasicColumn[] = [
  { title: 'BOM编号', dataIndex: 'code', width: 130 },
  { title: '父项物料', dataIndex: 'productId_dictText', width: 150 },
  { title: '版本', dataIndex: 'version', width: 80 },
  { title: '生效日期', dataIndex: 'effectiveDate', width: 110 },
  { title: '失效日期', dataIndex: 'expiryDate', width: 110 },
  //update-begin---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】status列走statusTag槽位-----------
  // 状态列走 statusTag 槽位（dataIndex 必须为 status，否则 tag 颜色判定失效）
  { title: '状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  //update-end---author:ruiwancheng---date:20260731---for:【制造链路黄金模板对齐】status列走statusTag槽位-----------
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: 'BOM编号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'productId', label: '父项物料', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_bom_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: 'BOM编号', component: 'Input', required: true, colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'productId', label: '父项物料', component: 'JMaterialSelect', required: true, colProps: { span: 6 }, componentProps: {} },
  { field: 'version', label: '版本号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 20 } },
  { field: 'effectiveDate', label: '生效日期', component: 'DatePicker', colProps: { span: 6 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'expiryDate', label: '失效日期', component: 'DatePicker', colProps: { span: 6 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  {
    field: 'status',
    label: '状态',
    component: 'JDictSelectTag',
    colProps: { span: 6 },
    componentProps: { dictCode: 'mes_bom_status' },
    defaultValue: '1',
    show: false,
  },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
