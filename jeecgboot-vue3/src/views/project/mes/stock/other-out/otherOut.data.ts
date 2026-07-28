import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';

export const columns: BasicColumn[] = [
  { title: '出库单号', dataIndex: 'code', width: 150 },
  { title: '出库类型', dataIndex: 'outType_dictText', width: 100 },
  { title: '仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '总金额', dataIndex: 'totalAmount', width: 100 },
  { title: '原因', dataIndex: 'reason', width: 150 },
  { title: '出库日期', dataIndex: 'stockDate', width: 110 },
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 140 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '单号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'outType', label: '出库类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_other_stock_out_type' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_other_stock_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '出库单号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50, placeholder: 'QT-OUT-YYYYMMDD-0001' } },
  { field: 'outType', label: '出库类型', component: 'JDictSelectTag', required: true, colProps: { span: 8 }, componentProps: { dictCode: 'mes_other_stock_out_type' } },
  { field: 'warehouseId', label: '仓库', component: 'ApiSelect', required: true, colProps: { span: 8 }, componentProps: { api: queryWarehouseSelect } },
  { field: 'stockDate', label: '出库日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'reason', label: '原因', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500, placeholder: '手工填写出库原因' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_other_stock_status' }, defaultValue: '1', show: false },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
