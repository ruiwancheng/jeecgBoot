import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '出库单编码', dataIndex: 'code', width: 130 },
  { title: '发货单', dataIndex: 'deliveryNoteId_dictText', width: 130 },
  { title: '销售订单', dataIndex: 'salesOrderId_dictText', width: 130 },
  { title: '出库仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '出库日期', dataIndex: 'outboundDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_outbound_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '出库单编码', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'deliveryNoteId', label: '发货单', component: 'JSearchSelect', colProps: { span: 8 }, componentProps: { dict: 'c_mes_delivery_note,code,id' } },
  { field: 'salesOrderId', label: '销售订单', component: 'JSearchSelect', colProps: { span: 8 }, componentProps: { dict: 'c_mes_sales_order,code,id' } },
  { field: 'warehouseId', label: '出库仓库', component: 'JSearchSelect', required: true, colProps: { span: 8 }, componentProps: { dict: 'c_mes_warehouse,name,id' } },
  { field: 'outboundDate', label: '出库日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_outbound_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
