// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryWarehouseSelect } from '../../basic/warehouse/warehouse.api';

export const columns: BasicColumn[] = [
  { title: '批次号', dataIndex: 'batchNo', width: 180 },
  { title: '物料', dataIndex: 'materialId_dictText', width: 150 },
  { title: '仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '当前数量', dataIndex: 'qty', width: 100 },
  { title: '批次成本', dataIndex: 'unitCost', width: 100 },
  { title: '创建时间', dataIndex: 'createTime', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'batchNo', label: '批次号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  // 物料搜索改为 Input（与 traceability/ledger.data.ts 保持一致），QueryGenerator 走 material_id 等值匹配
  { field: 'materialId', label: '物料', component: 'Input', colProps: { span: 6 } },
  { field: 'warehouseId', label: '仓库', component: 'ApiSelect', colProps: { span: 6 }, componentProps: { api: queryWarehouseSelect } },
];
