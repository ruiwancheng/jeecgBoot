import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '客户编码', dataIndex: 'code', width: 120 },
  { title: '客户名称', dataIndex: 'name', width: 150 },
  { title: '客户类型', dataIndex: 'type_dictText', width: 100 },
  { title: '客户等级', dataIndex: 'grade_dictText', width: 100 },
  { title: '信用额度', dataIndex: 'creditLimit', width: 100 },
  { title: '所属业务员', dataIndex: 'salesmanId', width: 100 },
  { title: '行业', dataIndex: 'industry_dictText', width: 100 },
  { title: '区域', dataIndex: 'region_dictText', width: 80 },
  { title: '联系人', dataIndex: 'contact', width: 80 },
  { title: '联系电话', dataIndex: 'phone', width: 130 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '客户编码', component: 'Input', colProps: { span: 6 } },
  { field: 'name', label: '客户名称', component: 'Input', colProps: { span: 6 } },
  { field: 'type', label: '客户类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_type' } },
  { field: 'grade', label: '客户等级', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_grade' } },
  { field: 'salesmanId', label: '业务员', component: 'Input', colProps: { span: 6 } },
  { field: 'industry', label: '行业', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_industry' } },
  { field: 'region', label: '区域', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_customer_region' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  // ---- 基础信息 ----
  { field: 'code', label: '客户编码', component: 'Input', required: true, colProps: { span: 8 } },
  { field: 'name', label: '客户名称', component: 'Input', required: true, colProps: { span: 8 } },
  { field: 'type', label: '客户类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_type' }, required: true },
  { field: 'grade', label: '客户等级', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_grade' } },
  { field: 'creditLimit', label: '信用额度', component: 'InputNumber', colProps: { span: 8 } },
  { field: 'salesmanId', label: '所属业务员', component: 'Input', colProps: { span: 8 } },
  { field: 'industry', label: '行业', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_industry' } },
  { field: 'region', label: '区域', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_region' } },
  { field: 'scale', label: '企业规模', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_customer_scale' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'yn', type: 'radioButton', stringToNumber: true }, defaultValue: 1 },
  // ---- 联系信息 ----
  { field: 'contact', label: '联系人', component: 'Input', colProps: { span: 8 } },
  { field: 'phone', label: '联系电话', component: 'Input', colProps: { span: 8 } },
  { field: 'address', label: '地址', component: 'Input', colProps: { span: 24 } },
  // ---- 财务资料 ----
  { field: 'invoiceTitle', label: '发票抬头', component: 'Input', colProps: { span: 12 } },
  { field: 'taxNo', label: '税号', component: 'Input', colProps: { span: 12 } },
  { field: 'bankName', label: '开户银行', component: 'Input', colProps: { span: 12 } },
  { field: 'bankAccount', label: '银行账号', component: 'Input', colProps: { span: 12 } },
  { field: 'invoiceAddress', label: '开票地址', component: 'Input', colProps: { span: 12 } },
  { field: 'invoicePhone', label: '开票电话', component: 'Input', colProps: { span: 12 } },
  { field: 'invoiceType', label: '发票类型', component: 'JDictSelectTag', colProps: { span: 12 }, componentProps: { dictCode: 'invoice_type' } },
  // ---- 备注 ----
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 } },
];
