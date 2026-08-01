//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】物料页联动：列表加 batchEnabled 列、表单加 batchEnabled 字段、disabled 由总开关状态决定-----------
import type { BasicColumn } from '/@/components/Table/src/types/table';
import type { FormSchema } from '/@/components/Form';

export const columns: BasicColumn[] = [
  { title: '物料编码', dataIndex: 'code', width: 120 },
  { title: '物料名称', dataIndex: 'name', width: 150 },
  { title: '物料类型', dataIndex: 'type_dictText', width: 100 },
  { title: '规格型号', dataIndex: 'spec', width: 150 },
  { title: '单位', dataIndex: 'unit_dictText', width: 80 },
  { title: '标准售价', dataIndex: 'standardPrice', width: 100, edit: true, editComponent: 'InputNumber', editComponentProps: { min: 0, precision: 2 } },
  { title: '移动平均成本', dataIndex: 'movingAvgCost', width: 110 },
  { title: '最近采购价', dataIndex: 'lastPurchasePrice', width: 100 },
  { title: '启用批次', dataIndex: 'batchEnabled', width: 90, customRender: ({ text }) => (Number(text) === 1 ? '已启用' : '未启用') },
  //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-物料列表增加保质期列-----------
  { title: '保质期(天)', dataIndex: 'shelfLife', width: 100 },
  //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-物料列表增加保质期列-----------
  { title: '状态', dataIndex: 'status_dictText', width: 80 },
  { title: '备注', dataIndex: 'remark', width: 150 },
];

export const searchFormSchema: FormSchema[] = [
  { field: 'code', label: '物料编码', component: 'Input', colProps: { span: 6 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '物料名称', component: 'Input', colProps: { span: 6 } },
  { field: 'type', label: '物料类型', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_material_type' } },
  { field: 'spec', label: '规格型号', component: 'Input', colProps: { span: 6 } },
  { field: 'unit', label: '单位', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'mes_material_unit' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 6 }, componentProps: { dictCode: 'yn' } },
];

export const formSchema: FormSchema[] = [
  { field: 'id', label: 'id', component: 'Input', show: false },
  { field: 'code', label: '物料编码', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 50 } },
  { field: 'name', label: '物料名称', component: 'Input', required: true, colProps: { span: 12 }, componentProps: { maxlength: 100 } },
  { field: 'type', label: '物料类型', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_material_type' }, required: true },
  { field: 'spec', label: '规格型号', component: 'Input', colProps: { span: 8 }, componentProps: { maxlength: 100 } },
  { field: 'unit', label: '单位', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'mes_material_unit' } },
  { field: 'status', label: '状态', component: 'JDictSelectTag', colProps: { span: 8 }, componentProps: { dictCode: 'yn', stringToNumber: true }, defaultValue: 1 },
  { field: 'safetyStock', label: '安全库存', component: 'InputNumber', colProps: { span: 12 }, componentProps: { min: 0 } },
  { field: 'maxStock', label: '最高库存', component: 'InputNumber', colProps: { span: 12 }, componentProps: { min: 0 } },
  { field: 'batchEnabled', label: '启用批次', component: 'JSwitch', colProps: { span: 8 },
    componentProps: {
      // JSwitch 内部按 props.options 数组 emit value，不读 checkedValue/unCheckedValue
      // options 默认 ['Y','N']，需传 '1'/'0' 字符串才能匹配后端 Integer
      options: ['1', '0'],
      labelOptions: ['是', '否'],
      // 物料级开关在总开关关闭时禁用——由 MaterialDrawer onMounted 时 watch store 动态写入 reactive
      disabled: false,
    },
    helpMessage: '由总开关控制：通用设置→生产批次管理 总开关关闭时，物料级开关自动禁用并强制归零', },
  //update-begin---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-物料表单增加保质期字段-----------
  { field: 'shelfLife', label: '保质期(天)', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0 } },
  //update-end---author:ruiwancheng---date:20260802---for: V10.0.0 物料/批次/采购入库-物料表单增加保质期字段-----------
  { field: 'standardPrice', label: '标准售价', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, precision: 2 } },
  { field: 'movingAvgCost', label: '移动平均成本', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, precision: 4, disabled: true }, ifShow: ({ model }: any) => !!model.id },
  { field: 'lastPurchasePrice', label: '最近采购价', component: 'InputNumber', colProps: { span: 8 }, componentProps: { min: 0, precision: 4, disabled: true }, ifShow: ({ model }: any) => !!model.id },
  { field: 'remark', label: '备注', component: 'InputTextArea', colProps: { span: 24 }, componentProps: { maxlength: 500 } },
];
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】物料页联动-----------
