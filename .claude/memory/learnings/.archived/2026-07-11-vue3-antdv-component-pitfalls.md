# Vue3 + Ant Design Vue 前端组件常见坑

**触发条件：** 在 JeecgBoot Vue3 前端开发中遇到以下场景时

**四类高频问题及处理方式：**

| 组件 | 问题 | 正确处理 |
|------|------|----------|
| `Tabs` / `TabPane` | `unplugin-vue-components` 不自动导入 TabPane | 显式 `import { Tabs } from 'ant-design-vue'`，模板用 `<Tabs.TabPane>` |
| `Switch` | 返回 boolean，后端 Integer 字段反序列化失败 | `componentProps: { checkedValue: 1, unCheckedValue: 0 }`，`defaultValue: 0` |
| `DatePicker` | 返回 dayjs 对象，JSON 序列化失败 | `componentProps: { valueFormat: 'YYYY-MM-DD HH:mm:ss' }` |
| `useTable` | `immediate: false` 导致子表 Tab 切换时不加载数据 | 改为 `immediate: true`（配合 `v-if` 判断父组件已传参） |

**日期：** 2026-07-11
