import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '供应商编码', dataIndex: 'code', width: 120 },
  { title: '供应商名称', dataIndex: 'name', width: 150 },
  { title: '供应商类型', dataIndex: 'type_dictText', width: 100 },
  { title: '供应商状态', dataIndex: 'status_dictText', width: 100 },
  { title: '供应商等级', dataIndex: 'grade_dictText', width: 100 },
  { title: '黑名单', dataIndex: 'blacklistFlag_dictText', width: 80 },
  { title: '联系人', dataIndex: 'contact', width: 80 },
  { title: '联系电话', dataIndex: 'phone', width: 130 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '供应商编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '供应商名称', component: 'Input', colProps: { span: 6 } },
  { field: 'type', label: '供应商类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_supplier_type' } },
  { field: 'status', label: '供应商状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_supplier_status' } },
  { field: 'grade', label: '供应商等级', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_supplier_grade' } },
  { field: 'blacklistFlag', label: '黑名单', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  // ---- 基础信息 ----
  { field: 'code', label: '供应商编码', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '供应商名称', component: 'Input', required: true, colProps: { span: 8 } },
  { field: 'type', label: '供应商类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_supplier_type' }, required: true },
  { field: 'status', label: '供应商状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_supplier_status' }, defaultValue: '1' },
  { field: 'grade', label: '供应商等级', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_supplier_grade' } },
  { field: 'blacklistFlag', label: '黑名单', component: 'Switch', colProps: { span: 8 }, componentProps: { checkedValue: 1, unCheckedValue: 0 }, defaultValue: 0 },
  // ---- 联系信息 ----
  { field: 'contact', label: '联系人', component: 'Input', colProps: { span: 8 } },
  { field: 'phone', label: '联系电话', component: 'Input', colProps: { span: 8 } },
  { field: 'address', label: '地址', component: 'Input', colProps: { span: 24 } },
  // ---- 财务信息 ----
  { field: 'invoiceTitle', label: '发票抬头', component: 'Input', colProps: { span: 12 } },
  { field: 'taxNo', label: '税号', component: 'Input', colProps: { span: 12 } },
  { field: 'bankName', label: '开户银行', component: 'Input', colProps: { span: 12 } },
  { field: 'bankAccount', label: '银行账号', component: 'Input', colProps: { span: 12 } },
  // ---- 备注 ----
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
