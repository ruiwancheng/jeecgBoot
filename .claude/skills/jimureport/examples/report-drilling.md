# 报表钻取示例

在一个报表中同时配置三种钻取：报表钻取报表、图表钻取报表、报表钻取网络。

---

## 一、整体架构

```
主报表（销售汇总 + 柱状图）
  ├── 钻取1: 点击「类别」列 → 跳转明细子报表（报表钻取报表，linkType=0）
  ├── 钻取2: 点击柱状图柱子 → 跳转同一个明细子报表（图表钻取报表，linkType=0）
  └── 钻取3: 点击「搜索」列 → 跳转百度搜索（报表钻取网络，linkType=1）
```

---

## 二、核心规则（易错点）

### 单元格钻取绑定

```python
# linkIds 必须是逗号分隔的字符串（不是数组！）
# 必须加 display: "link"
"1": {
    "text": "#{sales.name}",
    "style": 2,
    "linkIds": "1197391714543296512",     # 字符串！不是 ["id"]
    "display": "link"                      # 必须有！否则不生效
}
```

### 图表钻取绑定

```python
# linkIds 放在 extData 内部（不是 chartList 顶层！）
# 前端 view.js 通过 data.extData.linkIds 读取
chart_list = [{
    "row": 15, "col": 1,
    "width": "540", "height": "350",
    "config": json.dumps(echarts_config),
    "extData": {
        "chartType": "bar.simple",
        "dataType": "sql",
        "dataId": "数据集ID",
        "dbCode": "sales",
        "axisX": "name", "axisY": "value", "series": "type",
        "linkIds": "link_id_here"          # 放这里！不是 chartList 顶层
    },
    # ...
}]
```

### 图表钻取 paramValue 专用值

| paramValue | 含义 | 说明 |
|-----------|------|------|
| `name` | X轴分类值 | 点击的柱子/扇区对应的分类名 |
| `value` | Y轴数值 | 点击的柱子/扇区对应的数值 |
| `seriesName` | 系列名 | 多系列图表中的系列名称 |

---

## 三、完整创建流程

### Step 1: 创建明细子报表（钻取目标）

```python
detail_id = gen_id()
# save 空报表 → 获取 detail_id

# SQL 用 ${category} 接收钻取传参
detail_sql = """select product_name, category, brand, unit_price, quantity, total_amount, sale_date
from biz_product_sales where 1=1
<#if isNotEmpty(category)> and category = '${category}'</#if>"""

# 数据集 paramList 声明参数（searchFlag=1 显示查询条件）
detail_db = {
    "jimuReportId": detail_id,
    "dbCode": "detail", "dbChName": "销售明细",
    "dbType": "0", "isPage": "1",
    "dbDynSql": detail_sql,
    "fieldList": [...],
    "paramList": [
        {"paramName": "category", "paramTxt": "类别", "paramValue": "",
         "widgetType": "String", "orderNum": 1, "searchFlag": 1, "searchMode": 1}
    ]
}
```

### Step 2: 创建主报表 + 数据集

```python
main_id = gen_id()
# save 空报表

# SQL 字段必须 AS name/value/type（图表要求）
main_sql = """select category as name, sum(total_amount) as value, '' as type
from biz_product_sales group by category order by value desc"""

main_db = {
    "jimuReportId": main_id,
    "dbCode": "sales", "dbChName": "销售汇总",
    "dbType": "0", "isPage": "0",    # 汇总不分页
    "dbDynSql": main_sql,
    "fieldList": [...],
    "paramList": []
}
main_db_result = api_request('/jmreport/saveDb', main_db)
main_db_id = main_db_result['result']['id']  # 图表需要 dataId
```

### Step 3: 创建3种钻取配置

```python
# 钻取1: 报表钻取报表（点击类别列 → 明细子报表）
link1 = api_request('/jmreport/link/saveAndEdit', {
    "linkName": "报表钻取报表",
    "linkType": "0",                    # 报表钻取
    "reportId": detail_id,              # 目标子报表ID
    "ejectType": "0",                   # 新窗口
    "apiUrl": "", "apiMethod": "", "requirement": "",
    "parameter": json.dumps([{
        "paramName": "category",        # 子报表 SQL 中的 ${category}
        "paramValue": "name",           # 当前行 name 字段值
        "tableIndex": 0,
        "dbCode": "sales",
        "fieldName": "category"
    }], ensure_ascii=False)
})
link1_id = link1['result']

# 钻取2: 图表钻取报表（点击柱状图 → 同一个明细子报表）
link2 = api_request('/jmreport/link/saveAndEdit', {
    "linkName": "图表钻取报表",
    "linkType": "0",                    # 报表钻取（图表钻取也用 linkType=0）
    "reportId": detail_id,              # 同一个目标子报表
    "ejectType": "0",
    "apiUrl": "", "apiMethod": "", "requirement": "",
    "parameter": json.dumps([{
        "paramName": "category",
        "paramValue": "name",           # 图表X轴分类值（不是字段名！）
        "tableIndex": 0,
        "dbCode": "sales",
        "fieldName": ""                 # 图表钻取 fieldName 为空
    }], ensure_ascii=False)
})
link2_id = link2['result']

# 钻取3: 报表钻取网络（点击搜索列 → 百度搜索）
link3 = api_request('/jmreport/link/saveAndEdit', {
    "linkName": "网络钻取",
    "linkType": "1",                    # 网络链接
    "reportId": main_id,               # 当前报表ID（linkType=1 时）
    "ejectType": "0",
    "apiUrl": "https://www.baidu.com/s", # 外部URL
    "apiMethod": "", "requirement": "",
    "parameter": json.dumps([{
        "paramName": "wd",              # URL参数名（百度搜索关键词）
        "paramValue": "name",           # 当前行 name 字段值
        "paramCell": "",
        "tableIndex": 0,
        "dbCode": "sales",
        "fieldName": "name"
    }], ensure_ascii=False)
})
link3_id = link3['result']
```

### Step 4: 保存报表设计（表格 + 图表 + linkIds）

```python
page_size = 10
chart_start = 4 + page_size + 1  # 15

rows = {
    # Row 1: 标题
    "1": {
        "cells": {"1": {"text": "销售汇总报表（钻取演示）", "style": 5, "merge": [0, 2]}},
        "height": 45
    },
    # Row 2: 空行
    "2": {"cells": {}, "height": 15},
    # Row 3: 表头
    "3": {
        "cells": {
            "1": {"text": "商品类别", "style": 4},
            "2": {"text": "销售总额", "style": 4},
            "3": {"text": "搜索(网络钻取)", "style": 4},
        },
        "height": 34
    },
    # Row 4: 数据行（绑定钻取）
    "4": {
        "cells": {
            "1": {
                "text": "#{sales.name}", "style": 2,
                "linkIds": link1_id,         # 报表钻取报表（字符串！）
                "display": "link"            # 必须有！
            },
            "2": {"text": "#{sales.value}", "style": 2},
            "3": {
                "text": "#{sales.name}", "style": 2,
                "linkIds": link3_id,         # 网络钻取（字符串！）
                "display": "link"            # 必须有！
            },
        }
    },
    # 图表虚拟单元格锚点
    str(chart_start): {"cells": {"1": {"text": "   "}}},
    "len": 200
}

# 图表配置
echarts_config = {
    "title": {"show": True, "text": "各类别销售总额（点击柱子钻取明细）",
              "left": "center", "top": "5",
              "textStyle": {"fontSize": 16, "fontWeight": "bolder", "color": "#333"}},
    "grid": {"left": 80, "top": 60, "right": 40, "bottom": 60},
    "tooltip": {"show": True, "trigger": "axis"},
    "xAxis": {"show": True, "data": []},
    "yAxis": {"show": True},
    "series": [{"name": "销售总额", "type": "bar", "data": [], "barWidth": 40,
                "itemStyle": {"barBorderRadius": [4, 4, 0, 0], "color": "#01b0f1"}}]
}

chart_vcr = [[chart_start - 1, c] for c in range(3)]  # 0-based

chart_list = [{
    "row": chart_start, "col": 1, "colspan": 0, "rowspan": 0,
    "width": "540", "height": "350",
    "config": json.dumps(echarts_config, ensure_ascii=False),
    "url": "",
    "extData": {
        "chartType": "bar.simple",
        "dataType": "sql",
        "dataId": main_db_id,
        "dbCode": "sales",
        "axisX": "name", "axisY": "value", "series": "type",
        "xText": "", "yText": "",
        "apiStatus": "1",
        "chartId": chart_layer_id,       # 必须等于 layer_id
        "id": chart_layer_id,            # 必须等于 layer_id
        "linkIds": link2_id              # 图表钻取放在 extData 内部！
    },
    "layer_id": chart_layer_id,
    "offsetX": 0, "offsetY": 0,
    "backgroud": {"enabled": False, "color": "#fff", "image": ""},
    "virtualCellRange": chart_vcr
}]
```

---

## 四、parameter 对比

| 钻取类型 | paramValue | fieldName | 说明 |
|---------|-----------|-----------|------|
| 报表钻取报表 | `"name"` | `"category"` | 字段名，从数据集下拉选择 |
| 图表钻取报表 | `"name"` | `""` | X轴分类值（name/value/seriesName），fieldName 为空 |
| 报表钻取网络 | `"name"` | `"name"` | 字段名，自动拼接到 URL 参数 |

---

## 五、预览效果

```
┌─────────────────────────────────────┐
│   销售汇总报表（钻取演示）              │
│                                      │
│ 商品类别(钻取1) │ 销售总额 │ 搜索(钻取3)│
│ 电脑  ←点击跳转  │30156700 │ 电脑 ←百度 │
│ 手机            │18598560 │ 手机      │
│ 平板            │11664300 │ 平板      │
│ ...             │ ...     │ ...      │
│                                      │
│ ┌──────────────────────────────┐     │
│ │  各类别销售总额               │     │
│ │  ██                   ←点击  │     │  钻取2: 图表→子报表
│ │  ██  ██                      │     │
│ │  ██  ██  ██  ██              │     │
│ └──────────────────────────────┘     │
└─────────────────────────────────────┘
         │                    │
         ▼                    ▼
  ┌─────────────┐   ┌──────────────────┐
  │ 明细子报表    │   │ https://baidu.com│
  │ ?category=电脑│   │ /s?wd=电脑       │
  └─────────────┘   └──────────────────┘
```

---

## 六、注意事项

1. **linkIds 是字符串不是数组**：前端用 `this.linkIds + "," + linkId` 拼接，必须是 `"id1"` 或 `"id1,id2"`
2. **单元格必须加 `display: "link"`**：否则前端不识别为超链接
3. **图表 linkIds 放在 extData 内部**：`chartList[].extData.linkIds`，前端通过 `data.extData.linkIds` 读取
4. **图表钻取 paramValue 用专用值**：`name`（X轴）、`value`（Y轴）、`seriesName`（系列），不是数据集字段名
5. **图表钻取 fieldName 为空字符串**：与报表钻取不同
6. **图表 SQL 必须 AS name/value/type**：图表数据绑定使用固定字段名
7. **parameter 是 JSON 字符串**：`json.dumps([...])` 转字符串，不是原始数组
8. **linkType=0 时 reportId 是目标报表ID**：linkType=1 时 reportId 是当前报表ID
9. **子报表用 FreeMarker 动态条件**：`<#if isNotEmpty(category)>` 确保无参数时不过滤
10. **报表钻取和图表钻取可以指向同一个子报表**：用不同的 linkId 但 reportId 相同