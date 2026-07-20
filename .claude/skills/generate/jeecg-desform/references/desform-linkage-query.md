# 查询工作表（linkage 类型默认值）

## 一、概述

查询工作表是控件默认值的高级配置，通过 `advancedSetting.defaultValue.type = "linkage"` 启用。根据条件自动从其他工作表查询数据，将结果回填到当前字段。

### 与 link-record + link-field 的区别

| 特性 | link-record + link-field | 查询工作表（linkage） |
|------|------------------------|-------------------|
| 交互方式 | 用户手动选择 | 自动根据条件查询 |
| 触发时机 | 用户操作 | 表单加载 + 依赖字段变化 |
| 绑定位置 | 独立控件 | 任意控件的默认值配置 |
| 存储方式 | 存储关联记录 ID | 存储查询结果值 |

## 二、配置格式

```json
{
  "advancedSetting": {
    "defaultValue": {
      "type": "linkage",
      "value": "{编码后的配置对象}"
    }
  }
}
```

### 配置对象（编码前）

```json
{
  "appId": "",
  "desformCode": "",         // 目标工作表 code（必填）
  "matchType": "AND",        // "AND" / "OR"
  "operation": "FIRST",      // 聚合操作
  "rules": [],               // 查询条件（至少一条）
  "linkages": [],            // 字段映射（COUNT 时可空）
  "sorts": [],               // 排序（CUSTOM_SORT 时需要）
  "isMultiple": false,
  "maxRecordCount": 200
}
```

## 三、operation 聚合操作

| 值 | 说明 | 需要 linkages |
|----|------|:---:|
| `FIRST` | 最新一条（create_time desc） | 是 |
| `LAST` | 最老一条（create_time asc） | 是 |
| `CUSTOM_SORT` | 自定义排序后取第一条 | 是 |
| `IGNORE` | 多条时返回空 | 是 |
| `COUNT` | 计数 | 否 |
| `MAX` | 最大值 | 是 |
| `MIN` | 最小值 | 是 |
| `AVG` | 平均值 | 是 |
| `SUM` | 求和 | 是 |

## 四、rules 查询条件

```json
{
  "model": "target_field_model",
  "rule": "eq",
  "valueType": "field",
  "value": ["current_field_model"],
  "sqParam": { "type": "text", "rule": {"value": "eq"} }
}
```

- `valueType: "field"` — 引用本表字段值
- `valueType: "fixed"` — 固定值
- `valueType: "system"` — 系统变量

支持的 rule：eq, ne, gt, lt, gte, lte, like, left_like, right_like, in, not_in, range, is_null, is_not_null

## 五、linkages 字段映射

```json
{
  "model": "current_field_model",
  "linkModel": "target_field_model",
  "linkName": "显示名"
}
```

一次查询可映射多个字段，查询到数据后批量回填。

## 六、sorts 排序

```json
{ "column": "field_model", "order": "desc" }
```

仅 CUSTOM_SORT 时生效，支持多字段排序。

## 七、执行时机

1. **表单加载时**：发现 `type="linkage"` 立即执行查询
2. **依赖字段变化时**：自动 watch rules 中 valueType="field" 引用的字段
3. **防抖**：500ms 防抖 + queryId 去重

## 八、后端 API

```
POST /desform/data/aDefVal/linkaget
```

请求体：
```json
{
  "desformCode": "target_code",
  "operation": "FIRST",
  "superQueryString": "URL编码的高级查询JSON",
  "linkages": [{"model": "...", "linkModel": "..."}],
  "sorts": [{"column": "...", "order": "desc"}],
  "multiple": false,
  "maxRecordCount": 200
}
```

## 九、编码机制

配置对象保存前会压缩编码（缩短 key 名）：
```
appId→aid, desformCode→fCode, matchType→mType, operation→oper, linkModel→lModel, valueType→vType
```

## 十、示例

### 根据订单号自动填充金额

```json
{
  "desformCode": "order_form",
  "matchType": "AND",
  "operation": "FIRST",
  "rules": [{
    "model": "order_no",
    "rule": "eq",
    "valueType": "field",
    "value": ["input_order_no_xxx"]
  }],
  "linkages": [{
    "model": "money_amount_xxx",
    "linkModel": "order_amount"
  }],
  "sorts": [{"column": "create_time", "order": "desc"}]
}
```

### 统计符合条件的记录数

```json
{
  "desformCode": "task_form",
  "matchType": "AND",
  "operation": "COUNT",
  "rules": [
    {"model": "assignee", "rule": "eq", "valueType": "field", "value": ["select_user_xxx"]},
    {"model": "status", "rule": "eq", "valueType": "fixed", "value": ["进行中"]}
  ],
  "linkages": []
}
```

## 十一、常见问题

| 问题 | 原因 | 解决 |
|------|------|------|
| 查询不执行 | rules 为空或依赖字段无值 | 确保至少一条有效 rule |
| 返回空值 | IGNORE 模式下匹配到多条 | 改用 FIRST |
| 字段映射无效 | linkModel 错误 | 核实目标表字段 model |
| 编辑模式不触发 | linkage 默认值仅新增时生效 | 编辑时用 JS 增强 |
