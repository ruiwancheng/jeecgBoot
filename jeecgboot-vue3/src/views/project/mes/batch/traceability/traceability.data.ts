// update-begin---author:ruiwancheng---date:20260803---for: V10.0.3 批次追溯-列表列改为批次级 + 聚合字段-----------
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '批次号', dataIndex: 'batchNo', width: 180, fixed: 'left' },
  { title: '物料', dataIndex: 'materialId_dictText', width: 150 },
  { title: '来源类型', dataIndex: 'originType_dictText', width: 100 },
  { title: '来源单据', dataIndex: 'originBillNo', width: 140 },
  { title: '初始数量', dataIndex: 'qty', width: 100 },
  { title: '累计入库', dataIndex: 'totalInQty', width: 100 },
  { title: '累计出库', dataIndex: 'totalOutQty', width: 100 },
  { title: '流水条数', dataIndex: 'ledgerCount', width: 90 },
  { title: '状态', dataIndex: 'status_dictText', width: 90 },
  { title: '最新发生时间', dataIndex: 'lastOccurTime', width: 150 },
  {
    title: '操作',
    dataIndex: 'action',
    slots: { customRender: 'action' },
    fixed: 'right',
    width: 120,
  },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'batchNo', label: '批次号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'materialId', label: '物料', component: 'Input', colProps: { span: 6 } },
  { field: 'originType', label: '来源类型', component: 'Input', colProps: { span: 6 } },
];
// update-end---author:ruiwancheng---date:20260803---for: V10.0.3 批次追溯-列表列改为批次级 + 聚合字段-----------
