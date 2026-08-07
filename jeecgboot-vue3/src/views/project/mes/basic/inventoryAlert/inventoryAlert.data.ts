import type { FormSchema } from '/@/components/Form';

//update-begin---author:pi---date:2026-08-07---for:库存预警页面搜索筛选与规则字段定义---
export type AlertLevel = 'high' | 'medium' | 'low';

export interface InventoryAlertRecord {
  materialId: string;
  materialCode: string;
  materialName: string;
  warehouseId?: string;
  warehouseName?: string;
  currentQty: number;
  safetyStock: number;
  maxStock?: number | null;
  shortage: number;
  alertLevel: AlertLevel;
}

export interface InventoryAlertRuleForm {
  materialId?: string;
  safetyStock?: number | null;
  maxStock?: number | null;
  alertLevel: AlertLevel;
}

export const columns = [
  { title: '物料编码', dataIndex: 'materialCode', width: 130 },
  { title: '物料名称', dataIndex: 'materialName', width: 200 },
  { title: '仓库', dataIndex: 'warehouseName', width: 150 },
  { title: '当前库存', dataIndex: 'currentQty', width: 100 },
  { title: '安全库存', dataIndex: 'safetyStock', width: 100 },
  { title: '最高库存', dataIndex: 'maxStock', width: 100 },
  { title: '缺口', dataIndex: 'shortage', width: 100 },
  { title: '预警级别', dataIndex: 'alertLevel', width: 100 },
];

export const alertLevelOptions = [
  { label: '高', value: 'high' },
  { label: '中', value: 'medium' },
  { label: '低', value: 'low' },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'materialCode', label: '物料编码', component: 'Input' },
  { field: 'materialName', label: '物料名称', component: 'Input' },
  { field: 'warehouseId', label: '仓库', component: 'Select' },
  { field: 'alertLevel', label: '预警级别', component: 'Select' },
];

export const ruleFormSchema: FormSchema[] = [
  { field: 'materialId', label: '物料', component: 'ApiSelect', required: true },
  { field: 'safetyStock', label: '安全库存', component: 'InputNumber', required: true },
  { field: 'maxStock', label: '最高库存', component: 'InputNumber' },
  { field: 'alertLevel', label: '预警级别', component: 'Select', required: true },
];
//update-end---author:pi---date:2026-08-07---for:库存预警页面搜索筛选与规则字段定义---
