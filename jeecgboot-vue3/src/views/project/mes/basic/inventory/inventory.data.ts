//update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】状态列 + 操作列 + @generated-from 标注----------
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';

// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
export const columns: BasicColumn[] = [
  { title: '物料编码', dataIndex: 'material_code', width: 130, slots: { customRender: 'matText' } },
  { title: '物料名称', dataIndex: 'material_name', width: 150 },
  { title: '仓库', dataIndex: 'warehouse_name', width: 120, slots: { customRender: 'whText' } },
  { title: '当前库存', dataIndex: 'current_qty', width: 100, slots: { customRender: 'qtyTag' } },
  { title: '移动平均成本', dataIndex: 'moving_avg_cost', width: 110 },
  { title: '库存金额', dataIndex: 'inventory_amount', width: 110, slots: { customRender: 'amountText' } },
  //update-begin---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增状态列 + 操作列-----------
  { title: '状态', dataIndex: 'isOrphan', width: 80, slots: { customRender: 'orphanTag' } },
  { title: '操作', dataIndex: 'action', width: 80, slots: { customRender: 'action' }, fixed: 'right' },
  //update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】新增状态列 + 操作列-----------
];

export const searchFormSchema: FormSchema[] = [
  { field: 'keyword', label: '物料编码/名称', component: 'Input', colProps: { span: 8 } },
  // 模式 1：仓库下拉（ApiSelect 真实接口）
  { field: 'warehouseId', label: '仓库', component: 'ApiSelect', colProps: { span: 8 }, componentProps: { api: queryWarehouseSelect } },
];
//update-end---author:ruiwancheng---date:20260807---for:【孤儿行清理】状态列 + 操作列 + @generated-from 标注----------
