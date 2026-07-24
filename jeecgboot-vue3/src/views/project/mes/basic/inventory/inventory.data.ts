import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '物料编码', dataIndex: 'material_code', width: 120 },
  { title: '物料名称', dataIndex: 'material_name', width: 150 },
  { title: '仓库', dataIndex: 'warehouse_name', width: 120 },
  { title: '当前库存', dataIndex: 'current_qty', width: 100 },
  { title: '移动平均成本', dataIndex: 'moving_avg_cost', width: 110 },
  { title: '库存金额', dataIndex: 'inventory_amount', width: 110 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'keyword', label: '物料编码/名称', component: 'Input', colProps: { span: 8 } },
  { field: 'warehouseId', label: '仓库', component: 'Input', colProps: { span: 8 } },
];
