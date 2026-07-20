# 默认值表达式（Default Value Expressions）

表单控件支持通过 `advancedSetting.defaultValue` 配置高级默认值，包括静态值、字段引用组合、函数计算、自定义 JS 函数、查询工作表等多种方式。

## advancedSetting.defaultValue 结构

```json
{
  "advancedSetting": {
    "defaultValue": {
      "type": "compose",
      "value": "",
      "format": "string",
      "allowFunc": true,
      "valueSplit": "",
      "customConfig": false
    }
  }
}
```

### 属性说明

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `type` | string | `"compose"` | 默认值类型，见下方类型说明 |
| `value` | string | `""` | 默认值表达式内容 |
| `format` | string | `"string"` | 值格式化方式：`string`/`number`/`boolean` |
| `allowFunc` | boolean | `true` | 是否允许使用函数计算 |
| `valueSplit` | string | `""` | 数据分割符（如 `,`），非空时将多值 join 为分割字符串 |
| `customConfig` | boolean | `false` | 为 `true` 时使用自定义配置面板（如 link-record、sub-table-design） |

### type 类型说明

| 类型 | 说明 | 示例 |
|------|------|------|
| `compose` | 静态值 + 字段引用组合 | `"订单-$input_model$"` |
| `function` | 函数计算（使用内置函数库） | `"SUM($field1$,$field2$)"` |
| `javascript` | 自定义 JavaScript 函数 | 自定义 JS 代码体 |
| `linkage` | 查询工作表（从其他表单查数据） | 编码后的查询配置 |

## compose 类型 — 静态值 + 字段引用

最常用的默认值类型，支持纯静态文本和 `$fieldModel$` 字段引用的混合组合。

### 纯静态值

```json
{
  "type": "compose",
  "value": "默认文本",
  "format": "string"
}
```

### 字段引用

使用 `$fieldModel$` 语法引用其他字段的值（注意是 model 名，不是字段显示名）：

```json
{
  "type": "compose",
  "value": "部门：$select_depart_model$ - 姓名：$input_name_model$",
  "format": "string"
}
```

**引用规则：**
- 字段引用格式：`$model名$`（前后各一个 `$` 符号）
- 支持引用主表字段和关联记录字段
- 被引用字段值变化时，默认值自动重新计算
- 如果引用的字段为空，替换为空字符串

## function 类型 — 函数计算

使用内置函数库计算默认值，函数内可引用字段值。

```json
{
  "type": "function",
  "value": "SUM($price_model$,$tax_model$)",
  "format": "number"
}
```

> **注意：** function 类型与 formula 控件不同。formula 是独立的公式控件，function 类型是任意控件的默认值计算。

**可用函数详见 `desform-formula-function.md`。**

## javascript 类型 — 自定义 JS 函数

通过自定义 JavaScript 代码计算默认值。函数体必须返回一个值。

```json
{
  "type": "javascript",
  "value": "var price = $price_model$; var qty = $qty_model$; return price * qty * 1.13;",
  "format": "number"
}
```

**执行特点：**
- 代码中的 `$model$` 会被替换为字段实际值
- 字符串类型的值会被包装为引号字符串
- 函数异步执行，不阻塞 UI
- 必须通过 `return` 返回计算结果

## 特殊控件的内置默认值行为

部分控件有内置的特殊默认值逻辑（不通过 advancedSetting 配置）：

### select-user — 默认当前登录用户

```json
{
  "type": "select-user",
  "options": {
    "defaultLogin": true,
    "customReturnField": "username"
  }
}
```

- `defaultLogin: true` — 新增时自动填充当前登录用户
- 仅在 add/preview 操作时生效，edit 操作不自动填充
- Python: `USER('申请人', default_login=True)`

### select-depart — 默认当前部门

```json
{
  "type": "select-depart",
  "options": {
    "defaultLogin": true
  }
}
```

- 同上，自动填充当前用户所属部门
- Python: `DEPART('部门', default_login=True)` — 注意 desform_utils.py 的 DEPART 函数已支持 `default_login` 参数

### date — 默认值类型

date 控件通过 `defaultValueType` 控制默认值行为：

```json
{
  "type": "date",
  "options": {
    "defaultValueType": 1
  }
}
```

- `defaultValueType: 1` — 选择值（通过日期选择器手动选择，可预设固定默认值）
- `defaultValueType: 2` — 输入值（手动输入日期文本）
- `defaultValueType: 3` — 默认为当前系统时间（日期选择器禁用，新增时自动填充当前日期）

> 注意：`defaultValueType: 3` 仅在 add/preview 操作时生效，edit 时不自动填充。

### time — 允许手动输入

```json
{
  "type": "time",
  "options": {
    "inputDefVal": false
  }
}
```

- `inputDefVal: true` — 允许用户手动输入时间值

### auto-number — 新增时自动生成

```json
{
  "type": "auto-number",
  "options": {
    "generateOnAdd": true
  }
}
```

- `generateOnAdd: true` — 新增记录时自动生成编号

## valueSplit 分割符

当控件支持多值（如 checkbox、多选 select）时，`valueSplit` 将多个值拼接为单个字符串：

```json
{
  "type": "compose",
  "value": "$checkbox_model$",
  "valueSplit": ","
}
```

例如 checkbox 选中了 `["A", "B", "C"]`，结果为 `"A,B,C"`。

## customConfig 自定义配置

当 `customConfig: true` 时，控件使用独立的默认值配置面板而非通用面板：

- `link-record` — 使用关联记录专用配置
- `sub-table-design` — 使用子表默认值配置（支持固定值和查询工作表两种模式）

## 默认值执行流程

1. 表单加载时，遍历所有控件的 `advancedSetting.defaultValue`
2. **纯静态值**（compose 类型且不含 `$field$` 引用）：直接返回，按 `format` 格式化
3. **动态值**（含 `$field$` 引用）：
   - 解析表达式中的字段引用
   - 建立 Vue watcher 监听被引用字段的变化
   - 字段变化时自动重新计算默认值
4. **function/javascript 类型**：通过表达式求值引擎计算
5. **linkage 类型**：向后端发起查询请求获取数据

## 注意事项

1. 默认值仅在新增（add）操作时生效，编辑（edit）时使用已保存的数据
2. 字段引用使用 `model` 名（如 `input_1234567_123456`），不是字段显示名
3. `format: "number"` 会将结果转为数字类型，适用于数字/金额字段
4. compose 类型的字段引用值为 `null/undefined` 时替换为空字符串
5. function/javascript 类型的字段引用值为字符串时会自动加引号包裹
