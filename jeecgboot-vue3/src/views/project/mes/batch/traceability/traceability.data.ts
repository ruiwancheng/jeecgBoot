// @generated-from: harness/templates/mes-doc-page/master-detail @version: 1.0.0
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '批次号', dataIndex: 'batchNo', width: 180 },
  { title: '物料', dataIndex: 'materialId_dictText', width: 150 },
  { title: '业务类型', dataIndex: 'bizType', width: 100 },
  { title: '业务单据', dataIndex: 'bizNo', width: 140 },
  { title: '入库数量', dataIndex: 'inQty', width: 100 },
  { title: '出库数量', dataIndex: 'outQty', width: 100 },
  { title: '批次成本', dataIndex: 'unitCost', width: 100 },
  { title: '发生时间', dataIndex: 'occurTime', width: 150 },
  { title: '备注', dataIndex: 'remark', width: 200 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'batchNo', label: '批次号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'bizType', label: '业务类型', component: 'Input', colProps: { span: 6 } },
];
