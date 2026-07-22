import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';
import { querySalesOrderSelect } from '/@/views/project/mes/sales/order/order.api';
import { queryDeliverySelect } from '/@/views/project/mes/sales/delivery/delivery.api';

export const columns: BasicColumn[] = [
  { title: '出库单编码', dataIndex: 'code', width: 130 },
  { title: '发货单', dataIndex: 'deliveryNoteId_dictText', width: 130 },
  { title: '销售订单', dataIndex: 'salesOrderId_dictText', width: 130 },
  { title: '出库仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '出库日期', dataIndex: 'outboundDate', width: 110 },
  { title: '总金额', dataIndex: 'totalAmount', width: 100 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_outbound_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '出库单编码', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50, placeholder: 'OB-YYYYMMDD-001' } },
  { field: 'deliveryNoteId', label: '发货单', component: 'ApiSelect', colProps: { span: 8 }, componentProps: { api: queryDeliverySelect } },
  { field: 'salesOrderId', label: '销售订单', component: 'ApiSelect', colProps: { span: 8 }, componentProps: { api: querySalesOrderSelect } },
  { field: 'warehouseId', label: '出库仓库', component: 'ApiSelect', required: true, colProps: { span: 8 }, componentProps: { api: queryWarehouseSelect } },
  { field: 'outboundDate', label: '出库日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_outbound_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
