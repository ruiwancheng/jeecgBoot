# formSchema 自定义组件必须 emit primitive（useUseRuleFormItem 模式）(2026-08-07)

## 现象

BOM / 生产订单 / 完工单 / 销售价格 页面表单提交后报错：

```
JSON parse error: Cannot deserialize value of type `java.lang.String`
from Object value (token `JsonToken.START_OBJECT`)
```

## 根因

`JMaterialSelect` 是为表格单元格（`v-model:modelValue`）写的自定义组件，emit：

```ts
emit('update:modelValue', record.id);                              // primitive ✓
emit('change', { value: record.id, label: record.name, record }); // Object ✗
```

被放进 `formSchema` 后，BasicForm 通过 `useRuleFormItem(props, 'value', 'change', emitData)` 监听 `change` 事件——拿到的是 Object。

`validate()` 返回整个表单 values，`productId` 变成 Object。POST 到后端 Jackson 反序列化 `String productId` → 报错。

## 触发条件

写自定义组件并被 `formSchema` 引用（特别是 searchFormSchema / formSchema / 表单 schema 数组里），但组件 emit 的 `change` 事件值不是 primitive（ID 字符串）。

## 正确模式（JeecgBoot 标准）

参考 `JTreeDict.vue:40, 130-131` / `JRangeTime.vue:21, 42-43` / `JCodeEditor.vue:76, 84, 206-207`：

```ts
// 1. props 默认用 value（不是 modelValue）
const props = defineProps<{ value?: string; modelValue?: string }>();

// 2. emit 同时声明 change + update:value + update:modelValue（多模式兼容）
const emit = defineEmits(['update:modelValue', 'update:value', 'change']);

// 3. 用 useRuleFormItem 接管，自动 emit('change', primitive)
const [state] = useRuleFormItem(props, 'value', 'change', undefined);

// 4. 设置时走 state.value，触发 formItemContext.onFieldChange() + emit('change', value)
function handleSelect(record) {
  state.value = record.id;              // ← 关键，state 是 WritableComputedRef
  emit('update:modelValue', record.id); // 兼容表格 v-model:modelValue
}
```

## 检测方法

1. `grep -rn 'emit(.change.' src/components/jeecg/components/` 看标准组件怎么 emit
2. `grep -rn 'component:.*<YourCustom>' src/views/**/data.ts` 看哪些 formSchema 引用
3. curl 1:1 复现：手发 Object payload → code=500 JSON parse；发 String payload → 200

## 1:1 复现 + 验证（curl）

```
POST /mes/manufacturing/bom/add
  body: {"productId":{"value":"<id>","label":"...","record":{}}, ...} ← 旧组件行为
  响应: code=500  "JSON parse error: Cannot deserialize value of type
         String from Object value (token JsonToken.START_OBJECT)"  ❌

  body: {"productId":"<id>", ...}                                     ← 修复后
  响应: code=200  "添加成功"                                          ✓
```

## 影响面（本次一次性修复）

`JMaterialSelect` 在以下 4 个 formSchema 中被引用，全部受同一根因影响：

| 页面 | formSchema 字段 |
|------|----------------|
| BOM管理 (`bom.data.ts`) | `productId` |
| 生产订单 (`order.data.ts`) | `productId` |
| 完工单 (`completion.data.ts`) | `productId` |
| 销售价格 (`price.data.ts`) | `materialId` |

改一个共享组件 → 4 个页面同步修复。

## 关联修复

commit `f964463` — `fix(JMaterialSelect): emit change with primitive ID (BasicForm 反序列化修复)`

## ⚠️ 同类陷阱

写自定义 form 组件前必查 `useRuleFormItem` 是否已在用。表格场景可用 `v-model:modelValue`，表单场景必须 `v-model:value` + emit primitive。