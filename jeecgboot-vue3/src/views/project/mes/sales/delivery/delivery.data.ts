import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '发货单编码', dataIndex: 'code', width: 130 },
  { title: '销售订单', dataIndex: 'salesOrderId_dictText', width: 130 },
  { title: '发货仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '发货日期', dataIndex: 'deliveryDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '物流公司', dataIndex: 'logisticsCompany', width: 120 },
  { title: '运单号', dataIndex: 'trackingNo', width: 150 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '发货单编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'salesOrderId', label: '销售订单', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_delivery_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '发货单编码', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'salesOrderId', label: '销售订单', component: 'JSearchSelect', required: true, colProps: { span: 8 }, componentProps: { dict: 'c_mes_sales_order,code,id' } },
  { field: 'warehouseId', label: '发货仓库', component: 'JSearchSelect', required: true, colProps: { span: 8 }, componentProps: { dict: 'c_mes_warehouse,name,id' } },
  { field: 'deliveryDate', label: '发货日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'logisticsCompany', label: '物流公司', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 100 } },
  { field: 'trackingNo', label: '运单号', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 100 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_delivery_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
