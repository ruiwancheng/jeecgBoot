# 选项数据源配置（radio / checkbox / select）

单选框、多选框、下拉选择支持四种选项数据源。

## 一、数据源决策流程

```
需要选项数据源
    ↓
选项是否固定不变？
  ├─ 是 → 选项是否通用（多表单共用）？
  │      ├─ 是 → 系统字典（search_dict → 有则用，无则创建）
  │      └─ 否 → 静态选项
  └─ 否 → 选项来自哪里？
         ├─ 来自其他表单字段 → 关联表单（linkForm）
         └─ 来自自定义接口 → 远程函数
```

**AI 使用系统字典的决策流程**：
1. `search_dict(关键词)` 搜索系统内是否已有合适的字典
2. 有匹配 → `query_dict(dictCode)` 获取字典项 → 直接使用
3. 无匹配 → 选项会被多个表单复用 → 创建新字典；仅此表单使用 → 使用静态选项

## 二、静态选项（remote: false）

```json
{
  "options": {
    "remote": false,
    "options": [
      { "value": "1", "label": "选项一", "itemColor": "#2196F3" },
      { "value": "2", "label": "选项二", "itemColor": "#08C9C9" }
    ]
  }
}
```

适用场景：选项固定不变、数量少。

Python 用法：
```python
RADIO('是否同意', [
    {'value': 'Y', 'label': '同意'},
    {'value': 'N', 'label': '不同意'}
])
SELECT('职位', ['教授', '副教授', '讲师'])  # 字符串列表自动转 value=label
```

## 三、系统字典（remote: "dict"）— 推荐

```json
{
  "options": {
    "remote": "dict",
    "dictCode": "sex",
    "options": []
  },
  "dictOptions": [
    { "value": "1", "label": "男" },
    { "value": "2", "label": "女" }
  ]
}
```

运行时调用 `GET /sys/dict/getDictItems/{dictCode}` 加载选项。

### 常用系统字典编码

| dictCode | 名称 | 值 |
|----------|------|-----|
| `sex` | 性别 | 1=男, 2=女 |
| `priority` | 优先级 | L=低, M=中, H=高 |
| `valid_status` | 有效状态 | 0=无效, 1=有效 |
| `yn` | 是否 | Y=是, N=否 |
| `msg_category` | 消息类型 | 1=通知, 2=系统 |
| `send_status` | 发送状态 | 0=未发送, 1=已发送 |

### Python 用法

```python
# 先搜索是否有合适的字典
results = search_dict('性别')  # → [{'dictCode': 'sex', ...}]

# 查询字典项
sex_items = query_dict('sex')  # → [{'value': '1', 'text': '男'}, ...]

# 使用字典创建控件
RADIO('性别', sex_items, dict_code='sex')
SELECT('优先级', query_dict('priority'), dict_code='priority')
```

**关键规则**：
- `dict_code` 参数对应系统字典编码
- `options` 位置参数必填，传 `[{value, label}]` 列表
- 底层自动设置 `remote="dict"` 和 `dictOptions`

### 创建新字典

当系统内没有合适的字典时：

**Step 1：创建字典主表**
```
POST /sys/dict/add
{"dictCode": "leave_type", "dictName": "请假类型", "description": "请假类型选项", "type": 0}
```

**Step 2：逐条添加字典项**
```
POST /sys/dictItem/add
{"dictId": "{字典ID}", "itemText": "事假", "itemValue": "1", "sortOrder": 1, "status": 1}
```

**Python 工具函数**（desform_utils.py 提供）：
```python
# 创建字典（自动创建主表+字典项）
dict_id = create_dict('leave_type', '请假类型', [
    {'value': '1', 'label': '事假'},
    {'value': '2', 'label': '病假'},
    {'value': '3', 'label': '年假'},
])

# 查询或创建（优先查询已有字典，避免重复）
dict_id, items = query_or_create_dict('leave_type', '请假类型', [...])
```

## 四、关联表单（remote: "linkForm"）

```json
{
  "options": {
    "remote": "linkForm",
    "linkFormCode": "product_form",
    "linkFormField": "product_name"
  }
}
```

选项来自其他工作表指定字段的所有去重值。

## 五、远程函数（remote: true）

```json
{
  "options": {
    "remote": true,
    "remoteFunc": "getStatusList"
  }
}
```

需要在前端全局注册对应的函数。适用于自定义接口加载选项。

#### 远程函数注册机制

远程函数通过 `GenerateForm.vue` 的 `remote` prop 传入：

```javascript
// 父组件中
<generate-form :remote="remoteFunctions" />

// remoteFunctions 对象
{
  functionName(resolve) {
    // 异步获取选项数据
    api.get('/your/endpoint').then(res => {
      resolve(res.data.map(item => ({ value: item.id, label: item.name })))
    })
  }
}
```

在控件配置中设置 `remote: true` 和 `remoteFunc: 'functionName'`，表单渲染时自动调用对应函数填充选项。

> **注意：** 远程函数仅在 iframe 内的 Vue2 表单渲染器中生效。通过 Python 工具创建表单时，如需使用远程函数，需在表单的 JS 增强中实现数据加载逻辑。

## 六、对比总结

| 数据源 | remote 值 | 必填参数 | API 调用 | 适用场景 |
|--------|----------|---------|---------|---------|
| 静态选项 | `false` | options[] | 无 | 固定少量选项 |
| 系统字典 | `"dict"` | dictCode, dictOptions | GET /sys/dict/getDictItems | 通用复用选项 |
| 关联表单 | `"linkForm"` | linkFormCode, linkFormField | 间接查询 | 动态表单字段值 |
| 远程函数 | `true` | remoteFunc | 自定义 | 自定义接口 |
