import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';

export const columns: BasicColumn[] = [
  { title: '入库单号', dataIndex: 'code', width: 130 },
  { title: '生产订单', dataIndex: 'productionOrderId', width: 130 },
  { title: '产品', dataIndex: 'productId_dictText', width: 150 },
  { title: '仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '入库日期', dataIndex: 'receiptDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '入库单号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'productionOrderId', label: '生产订单', component: 'Input', colProps: { span: 6 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_completion_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '入库单号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50 } },
  { field: 'productionOrderId', label: '生产订单', component: 'Input', required: true, colProps: { span: 8 } },
  { field: 'productId', label: '产品', component: 'JMaterialSelect', required: true, colProps: { span: 8 }, componentProps: {} },
  { field: 'warehouseId', label: '仓库', component: 'ApiSelect', required: true, colProps: { span: 8 }, componentProps: { api: queryWarehouseSelect } },
  { field: 'receiptDate', label: '入库日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_completion_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
