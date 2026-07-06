import { BasicColumn, FormSchema } from '/@/components/Table';
export const columns: BasicColumn[] = [
  { title: '库位编码', dataIndex: 'code', width: 180 },
  { title: '库位类型', dataIndex: 'locationType', width: 100 },
  { title: '容量', dataIndex: 'capacity', width: 80 },
  { title: '状态', dataIndex: 'status', width: 80 },
];
export const searchFormSchema: FormSchema[] = [{ label: '库位编码', field: 'code', component: 'Input' }];
export const formSchema: FormSchema[] = [
  { label: '所属仓库', field: 'warehouseId', component: 'Input', required: true },
  { label: '库位编码', field: 'code', component: 'Input', required: true },
  { label: '库位类型', field: 'locationType', component: 'JDictSelectTag', componentProps: { dictCode: 'demo_location_type' } },
  { label: '容量', field: 'capacity', component: 'InputNumber' },
  { label: '状态', field: 'status', component: 'JDictSelectTag', componentProps: { dictCode: 'yn' }, defaultValue: 1 },
];
