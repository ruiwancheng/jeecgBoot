//update-begin---author:ruiwancheng---date:20260731---for:【生产批次总开关】通用设置列定义-----------
import type { BasicColumn } from '/@/components/Table/src/types/table';

export const columns: BasicColumn[] = [
  { title: '开关名称', dataIndex: 'switchName', width: 200 },
  { title: '开关标识', dataIndex: 'switchKey', width: 220 },
  {
    title: '状态',
    dataIndex: 'switchValue',
    width: 120,
    customRender: ({ text }) => (text === 1 ? '已开启' : '已关闭'),
  },
  { title: '说明', dataIndex: 'description', width: 400 },
];
//update-end---author:ruiwancheng---date:20260731---for:【生产批次总开关】通用设置列定义-----------