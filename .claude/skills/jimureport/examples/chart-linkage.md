# 图表联动示例

在一个报表中同时配置两种联动：表格联动图表、图表联动图表。联动不跳转页面，点击后当前报表内目标图表刷新。

---

## 一、整体架构

```
表格（类别汇总，不分页）
  └── 联动1(linkType=2): 点击「类别」列 → 图表A 按品牌刷新
图表A（品牌柱状图，参数 category，默认值"手机"）
  └── 联动2(linkType=2): 点击柱子 → 图表B 按月度刷新
图表B（月度折线图，参数 brand，默认值"苹果"）
```

---

## 二、核心规则（易错点汇总）

### ⚠️ API 数据集联动：apiUrl 必须拼参数占位符

API 数据集是联动目标时，`apiUrl` **必须**在末尾加 `?paramName=${paramName}`，否则联动触发后接口收不到参数，图表不刷新。

```python
# ❌ 错误：有 paramList 但 URL 没带占位符
save_db(session, report_id, "schoolChart", "...", "", fields,
    [{"paramName": "leibie", "paramValue": "初中", ...}],
    db_type="1", api_url="https://xxx/byschool")          # ← 联动无效

# ✅ 正确：URL 末尾拼占位符
save_db(session, report_id, "schoolChart", "...", "", fields,
    [{"paramName": "leibie", "paramValue": "初中", ...}],
    db_type="1", api_url="https://xxx/byschool?leibie=${leibie}")  # ← 正确
```

> 写完 `save_db` 后必须目视检查 `api_url` 字符串包含 `${paramName}`，多参数用 `&` 连接。

---

### 联动统一用 linkType=2

```
linkType=0 → 钻取（跳转报表）
linkType=1 → 钻取（跳转网络URL）
linkType=2 → 联动（刷新当前报表内的图表）  ← 联动只用这个！
```

### 两种联动的 parameter 差异

| 联动类型 | parameter 结构 |
|---------|---------------|
| 表格联动图表 | `{paramName, paramValue, tableIndex, dbCode, fieldName}` |
| 图表联动图表 | `{paramName, paramValue, index}` |

### extData 必须有 chartId 和 id

```python
"extData": {
    "chartId": layer_id,   # 必须等于 layer_id！否则联动参数下拉框为空
    "id": layer_id,        # 必须等于 layer_id！
    # ...
}
```

### 图表位置计算（避免重叠）

```python
# 数据集不分页时，数据会全部展开
data_rows = 8              # 实际数据条数
data_start = 4             # 数据绑定行号
chartA_row = data_start + data_rows + 1          # 数据展开完后
chartB_row = chartA_row + (chartA_height // 25) + 2  # 图表A高度占行数 + 间距
pagination_row = chartB_row + 15                  # 底部分页符确保滚动
```

### 联动目标图表数据集必须有参数和默认值

```python
# 目标图表的数据集参数需设默认值，确保初始页面有数据
paramList = [{"paramName": "category", "paramValue": "手机",  # 默认值！
              "widgetType": "String", "orderNum": 1, "searchFlag": 0}]
```

---

## 三、完整创建流程

### Step 1: 创建空报表 + 3个数据集

```python
# DS1: 表格 - 类别汇总（不分页，全部展开）
sql1 = "select category, count(*) as cnt, sum(total_amount) as total from biz_product_sales group by category order by total desc"
db1 = {"dbCode": "catSum", "isPage": "0", "paramList": []}

# DS2: 图表A - 按品牌（需参数 category，默认"手机"）
sql2 = "select brand as name, sum(total_amount) as value, '' as type from biz_product_sales where category='${category}' group by brand order by value desc"
db2 = {"dbCode": "brandChart", "isPage": "0",
       "paramList": [{"paramName": "category", "paramValue": "手机", "searchFlag": 0}]}
db2_id = result['id']  # 保存数据集ID，图表需要

# DS3: 图表B - 按月（需参数 brand，默认"苹果"）
sql3 = "select DATE_FORMAT(sale_date,'%Y-%m') as name, sum(total_amount) as value, '' as type from biz_product_sales where brand='${brand}' group by name order by name"
db3 = {"dbCode": "monthChart", "isPage": "0",
       "paramList": [{"paramName": "brand", "paramValue": "苹果", "searchFlag": 0}]}
db3_id = result['id']
```

### Step 2: 创建两个联动配置

```python
# 联动1: 表格联动图表A（点击类别列 → 图表A刷新）
link1 = api('/jmreport/link/saveAndEdit', {
    "linkName": "按类别联动品牌图",
    "linkType": "2",                     # 联动统一用 2！
    "reportId": report_id,               # 当前报表ID
    "linkChartId": chartA_layer,         # 目标图表A的 layer_id
    "requirement": "",
    "parameter": json.dumps([{
        "paramName": "category",         # 图表A数据集的参数名
        "paramValue": "category",        # 当前行的字段名
        "tableIndex": 0,
        "dbCode": "catSum",
        "fieldName": "category"
    }], ensure_ascii=False)
})
link1_id = link1['result']

# 联动2: 图表A联动图表B（点击柱子 → 图表B刷新）
link2 = api('/jmreport/link/saveAndEdit', {
    "linkName": "按品牌联动月度图",
    "linkType": "2",                     # 联动统一用 2！
    "reportId": report_id,               # 当前报表ID
    "linkChartId": chartB_layer,         # 目标图表B的 layer_id
    "requirement": "",
    "parameter": json.dumps([{
        "paramName": "brand",            # 图表B数据集的参数名
        "paramValue": "name",            # 图表A的X轴分类值
        "index": 1
    }], ensure_ascii=False)
})
link2_id = link2['result']
```

### Step 3: 保存报表设计（表格 + 图表A + 图表B + linkIds）

```python
# 布局计算
data_rows = 8  # 类别数
data_start = 4  # 数据绑定行
chartA_row = data_start + data_rows + 1  # 13
chartB_row = chartA_row + 14             # 27

rows = {
    "1": {"cells": {"1": {"text": "联动演示", "style": 5, "merge": [0, 3]}}, "height": 45},
    "2": {"cells": {}, "height": 15},
    "3": {"cells": {
        "1": {"text": "商品类别", "style": 4},
        "2": {"text": "销售笔数", "style": 4},
        "3": {"text": "销售总额", "style": 4},
        "4": {"text": "操作提示", "style": 4},
    }, "height": 34},
    "4": {"cells": {
        "1": {"text": "#{catSum.category}", "style": 2,
              "linkIds": link1_id, "display": "link"},  # 绑定联动1
        "2": {"text": "#{catSum.cnt}", "style": 2},
        "3": {"text": "#{catSum.total}", "style": 2},
        "4": {"text": "点击左侧类别联动→", "style": 2},
    }},
    str(chartA_row): {"cells": {"1": {"text": "   "}}},  # 图表A锚点
    str(chartB_row): {"cells": {"1": {"text": "   "}}},  # 图表B锚点
    str(chartB_row + 15): {"cells": {"1": {"text": "   "}}},  # 分页符
    "len": 200
}

# 图表A: 品牌柱状图
chartA_layer = f"chartA_{int(time.time()*1000)}"
chart_a = {
    "row": chartA_row, "col": 1, "colspan": 0, "rowspan": 0,
    "width": "530", "height": "300",
    "config": json.dumps(echarts_bar_config, ensure_ascii=False),
    "url": "",
    "extData": {
        "chartType": "bar.simple",
        "dataType": "sql",
        "dataId": db2_id,
        "dbCode": "brandChart",
        "axisX": "name", "axisY": "value", "series": "type",
        "xText": "", "yText": "", "apiStatus": "1",
        "chartId": chartA_layer,       # 必须等于 layer_id！
        "id": chartA_layer,            # 必须等于 layer_id！
        "linkIds": link2_id            # 图表A绑定联动2（放extData内部）
    },
    "layer_id": chartA_layer,
    "offsetX": 0, "offsetY": 0,
    "backgroud": {"enabled": False, "color": "#fff", "image": ""},
    "virtualCellRange": [[chartA_row - 1, c] for c in range(4)]
}

# 图表B: 月度折线图（被联动目标，无 linkIds）
chartB_layer = f"chartB_{int(time.time()*1000)}"
chart_b = {
    "row": chartB_row, "col": 1, "colspan": 0, "rowspan": 0,
    "width": "530", "height": "300",
    "config": json.dumps(echarts_line_config, ensure_ascii=False),
    "url": "",
    "extData": {
        "chartType": "line.simple",
        "dataType": "sql",
        "dataId": db3_id,
        "dbCode": "monthChart",
        "axisX": "name", "axisY": "value", "series": "type",
        "xText": "", "yText": "", "apiStatus": "1",
        "chartId": chartB_layer,       # 必须等于 layer_id！
        "id": chartB_layer             # 必须等于 layer_id！
    },
    "layer_id": chartB_layer,
    "offsetX": 0, "offsetY": 0,
    "backgroud": {"enabled": False, "color": "#fff", "image": ""},
    "virtualCellRange": [[chartB_row - 1, c] for c in range(4)]
}

# save 请求体
save_data = {
    # ... 标准字段 ...
    "chartList": [chart_a, chart_b],
    "area": False,           # 自动计算滚动高度
    # ...
}
```

---

## 四、预览效果

```
┌───────────────────────────────────┐
│    联动演示（表格→图表A→图表B）      │
│                                    │
│ 类别  │笔数│销售总额 │操作提示      │
│ 电脑← │ 29│31239106│点击联动→     │  ← 点击"电脑"
│ 手机  │ 27│19245334│             │
│ ...   │...│...     │             │
│                                    │  8条数据全部展开
│ ┌─ 图表A：品牌柱状图 ─────┐        │
│ │  ██ 苹果               │        │  ← 刷新为电脑品牌
│ │  ██ ██ 联想             │        │
│ │  ██ ██ ██ 华为  ←点击   │        │  ← 点击"华为"柱子
│ └────────────────────────┘        │
│                                    │
│ ┌─ 图表B：月度折线图 ─────┐        │
│ │  ╱╲    ╱╲              │        │  ← 刷新为华为月度数据
│ │ ╱  ╲╱╱  ╲             │        │
│ └────────────────────────┘        │
└───────────────────────────────────┘
```

---

## 五、注意事项

1. **联动统一用 linkType=2**：linkType=0 永远是钻取（跳转），不是联动
2. **linkChartId 必填**：指向目标图表的 layer_id（不能是自身）
3. **extData 必须有 chartId 和 id**：值等于 layer_id，否则设计器联动参数下拉框为空
4. **目标图表数据集参数需设默认值**：确保初始页面有数据展示
5. **图表位置要在数据展开区之后**：`chartA_row = data_start + data_rows + 1`，不分页数据集会全部展开
6. **area=False**：让系统自动计算滚动高度，避免手动设置 area 被设计器覆盖导致滚动失效
7. **底部添加分页符行**：在图表B下方添加空行确保滚动条正常
8. **表格联动图表 parameter**：`{paramName, paramValue, tableIndex, dbCode, fieldName}`（与钻取结构一致）
9. **图表联动图表 parameter**：`{paramName, paramValue, index}`（简化结构，paramValue 用 name/value/seriesName）
10. **单元格绑定联动**：`linkIds` 是逗号分隔字符串 + `display: "link"`
11. **图表绑定联动**：`linkIds` 放在 `extData` 内部（不是 chartList 顶层）