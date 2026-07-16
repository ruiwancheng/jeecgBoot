import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '入库单号', dataIndex: 'code', width: 130 },
  { title: '采购订单', dataIndex: 'purchaseOrderId', width: 130 },
  { title: '供应商', dataIndex: 'supplierId_dictText', width: 150 },
  { title: '仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '入库日期', dataIndex: 'receiptDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '入库单号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'purchaseOrderId', label: '采购订单', component: 'Input', colProps: { span: 6 } },
  { field: 'warehouseId', label: '仓库', component: 'Input', colProps: { span: 6 } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '入库单号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'purchaseOrderId', label: '采购订单', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'supplierId', label: '供应商', component: 'JSearchSelect', required: true, colProps: { span: 8 }, componentProps: { dict: 'c_mes_supplier,name,id' } },
  { field: 'warehouseId', label: '仓库', component: 'JSearchSelect', required: true, colProps: { span: 8 }, componentProps: { dict: 'c_mes_warehouse,name,id' } },
  { field: 'receiptDate', label: '入库日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'yn' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
