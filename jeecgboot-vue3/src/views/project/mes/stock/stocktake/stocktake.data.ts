import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';
import { ref } from 'vue';
import { queryWarehouseSelect } from '/@/views/project/mes/basic/warehouse/warehouse.api';

// 新建时盘点类型联动（全盘禁用添加物料按钮，引导保存后到「录入实盘」填数）
export const createTakeType = ref('1');

export const columns: BasicColumn[] = [
  { title: '盘点单号', dataIndex: 'code', width: 150 },
  { title: '仓库', dataIndex: 'warehouseId_dictText', width: 120 },
  { title: '盘点类型', dataIndex: 'takeType_dictText', width: 90 },
  { title: '账面快照时间', dataIndex: 'snapshotTime', width: 150 },
  { title: '差异金额合计', dataIndex: 'totalDiffAmount', width: 110 },
  { title: '盘点日期', dataIndex: 'takeDate', width: 110 },
  { title: '状态', dataIndex: 'status', width: 80, slots: { customRender: 'statusTag' } },
  { title: '备注', dataIndex: 'remark', width: 140 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '单号', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'takeType', label: '盘点类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_stocktake_type' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_other_stock_status' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '盘点单号', component: 'Input', required: true, colProps: { span: 8 }, componentProps: { maxlength: 50, placeholder: 'PD-YYYYMMDD-0001' } },
  { field: 'takeType', label: '盘点类型', component: 'JDictSelectTag', required: true, colProps: { span: 8 }, componentProps: { dictCode: 'mes_stocktake_type', onChange: (v: any) => { createTakeType.value = v?.target?.value ?? v; } }, defaultValue: '1' },
  { field: 'warehouseId', label: '仓库', component: 'ApiSelect', required: true, colProps: { span: 8 }, componentProps: { api: queryWarehouseSelect } },
  { field: 'takeDate', label: '盘点日期', component: 'DatePicker', colProps: { span: 8 }, componentProps: { valueFormat: 'YYYY-MM-DD' } },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_other_stock_status' }, defaultValue: '1', show: false },
];
