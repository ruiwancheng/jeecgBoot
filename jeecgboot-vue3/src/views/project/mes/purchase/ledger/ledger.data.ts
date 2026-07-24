import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '物料', dataIndex: 'materialId_dictText', width: 150 },
  { title: '仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '期初数量', dataIndex: 'beginningQty', width: 100 },
  { title: '本期入库', dataIndex: 'inQty', width: 100 },
  { title: '本期出库', dataIndex: 'outQty', width: 100 },
  { title: '期末数量', dataIndex: 'endingQty', width: 100 },
  { title: '单位成本', dataIndex: 'unitCost', width: 100 },
  { title: '入库金额', dataIndex: 'inAmount', width: 100 },
  { title: '出库金额', dataIndex: 'outAmount', width: 100 },
  { title: '记录日期', dataIndex: 'recordDate', width: 110 },
  { title: '业务类型', dataIndex: 'bizType', width: 100 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'materialId', label: '物料', component: 'Input', colProps: { span: 6 } },
  { field: 'warehouseId', label: '仓库', component: 'Input', colProps: { span: 6 } },
  { field: 'bizType', label: '业务类型', component: 'Input', colProps: { span: 6 } },
];
