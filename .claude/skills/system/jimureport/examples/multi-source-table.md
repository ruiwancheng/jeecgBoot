# 多源报表示例

多源报表：报表数据来源包含多个数据集，通过主子表联动（linkType=4）建立关联关系。主表和子表字段在**同一行**，全部使用 `#{}` 列表绑定。

> **与主子表报表（master-sub-table）的区别：**
> - **主子表报表**：主表用 `${}` 单值绑定，子表用 `#{}` 列表绑定，适合"一条主记录 + 多条子记录明细"的套打场景
> - **多源报表**：主表和子表**都用 `#{}`** 列表绑定，字段在同一行，适合"订单列表 + 商品明细"的展开式列表场景

---

## 一、核心规则

### 数据绑定

| 表 | 绑定语法 | 说明 |
|----|---------|------|
| 主表 | `#{主表code.字段}` | 列表绑定，主表字段自动合并相同值 |
| 子表 | `#{子表code.字段}` | 列表绑定，每条子记录展开一行 |

### 关键配置

1. **主表 isPage="1"**，子表 isPage="0"（子表不分页）
2. **子表必须声明参数**（paramList），`searchFlag=0`（不显示查询条件）
3. **linkType="4"**（主子表联动），通过 `/jmreport/link/saveAndEdit` 配置
4. **parameter** 指定主表字段与子表参数的映射关系

### JSON vs SQL 示例对照

| 配置项 | JSON 数据集示例 | SQL 数据集示例 |
|-------|---------------|--------------|
| 主表数据集 | order（dbType=3） | orderMain（dbType=0） |
| 子表数据集 | detail（dbType=3） | orderSub（dbType=0） |
| 主表数据来源 | jsonData（内嵌JSON） | `select id, order_code, order_date, descc from test_order_main` |
| 子表数据来源 | jsonData（内嵌JSON）+ paramList | `where order_fk_id = '${pid}'` |
| 主表关联字段 | id | id |
| 子表参数 | order_id（searchFlag=0） | pid（searchFlag=0） |
| linkType | 4 | 4 |
| 绑定方式 | `#{order.field}` + `#{detail.field}` | `#{orderMain.field}` + `#{orderSub.field}` |

---

## 二、完整创建流程（JSON 数据集）

### Step 1: 创建空报表

```python
report_id = gen_id()
# save 空报表 → 获取 report_id
```

### Step 2: 创建主表 JSON 数据集

```python
main_json = json.dumps({
    "data": [
        {"id": "1001", "order_no": "ORD-2026-001", "customer": "张三", "phone": "13800001111", "order_date": "2026-03-01", "total_amount": "15680.00", "status": "已完成"},
        {"id": "1002", "order_no": "ORD-2026-002", "customer": "李四", "phone": "13900002222", "order_date": "2026-03-05", "total_amount": "8450.00", "status": "待发货"},
        # ... 更多订单
    ]
}, ensure_ascii=False)

main_db = {
    "izSharedSource": 0, "jimuReportId": report_id,
    "dbCode": "order",          # 主表编码
    "dbChName": "订单主表",
    "dbType": "3",              # 3=JSON
    "dbSource": "",
    "jsonData": main_json,
    "isList": "1",
    "isPage": "1",              # 主表可分页
    "dbDynSql": "",
    "fieldList": [
        {"fieldName": "id", "fieldText": "ID", "widgetType": "String", "orderNum": 0},
        {"fieldName": "order_no", "fieldText": "订单编号", "widgetType": "String", "orderNum": 1},
        {"fieldName": "customer", "fieldText": "客户", "widgetType": "String", "orderNum": 2},
        # ...
    ],
    "paramList": []             # 主表无参数
}
api_request('/jmreport/saveDb', main_db)
```

### Step 3: 创建子表 JSON 数据集

```python
sub_json = json.dumps({
    "data": [
        {"id": "D001", "order_id": "1001", "product": "iPhone 15 Pro", "spec": "256GB 黑色", "price": "8999", "qty": "1", "subtotal": "8999.00"},
        {"id": "D002", "order_id": "1001", "product": "AirPods Pro 2", "spec": "USB-C", "price": "1799", "qty": "1", "subtotal": "1799.00"},
        {"id": "D005", "order_id": "1002", "product": "iPad Air", "spec": "M2/128GB", "price": "4799", "qty": "1", "subtotal": "4799.00"},
        # ... 更多明细，通过 order_id 关联主表
    ]
}, ensure_ascii=False)

sub_db = {
    "izSharedSource": 0, "jimuReportId": report_id,
    "dbCode": "detail",         # 子表编码
    "dbChName": "订单明细",
    "dbType": "3",              # 3=JSON
    "dbSource": "",
    "jsonData": sub_json,
    "isList": "1",
    "isPage": "0",              # 子表不分页！
    "dbDynSql": "",
    "fieldList": [
        {"fieldName": "id", "fieldText": "ID", "widgetType": "String", "orderNum": 0},
        {"fieldName": "order_id", "fieldText": "订单ID", "widgetType": "String", "orderNum": 1},
        {"fieldName": "product", "fieldText": "商品名称", "widgetType": "String", "orderNum": 2},
        # ...
    ],
    # 子表必须声明参数，searchFlag=0（不显示查询条件，由联动自动传值）
    "paramList": [
        {"paramName": "order_id", "paramTxt": "订单ID", "paramValue": "",
         "widgetType": "String", "orderNum": 1, "searchFlag": 0, "searchMode": 1}
    ]
}
api_request('/jmreport/saveDb', sub_db)
```

### Step 4: 配置主子表联动

```python
parameter = json.dumps({
    "main": "order",            # 主表 dbCode
    "sub": "detail",            # 子表 dbCode
    "subReport": [{
        "mainField": "id",      # 主表关联字段名
        "subParam": "order_id", # 子表参数名（对应子表 paramList 中的 paramName）
        "tableIndex": 1         # 子表序号（从1开始）
    }]
}, ensure_ascii=False)

link_data = {
    "mainReport": "order",      # 主表 dbCode
    "subReport": "detail",      # 子表 dbCode
    "linkName": "订单主子表联动",
    "parameter": parameter,     # JSON 字符串
    "linkType": "4",            # 4=主子表联动
    "reportId": report_id
}
api_request('/jmreport/link/saveAndEdit', link_data)
```

### Step 5: 保存报表设计

```python
rows = {
    # Row 1: 标题
    "1": {
        "cells": {"1": {"text": "订单销售明细表", "style": 5, "merge": [0, 7]}},
        "height": 45
    },
    # Row 2: 空行间距
    "2": {"cells": {}, "height": 15},
    # Row 3: 表头
    "3": {
        "cells": {
            "1": {"text": "订单编号", "style": 4},
            "2": {"text": "客户", "style": 4},
            "3": {"text": "下单日期", "style": 4},
            "4": {"text": "商品名称", "style": 4},
            "5": {"text": "规格", "style": 4},
            "6": {"text": "单价", "style": 4},
            "7": {"text": "数量", "style": 4},
            "8": {"text": "小计", "style": 4},
        },
        "height": 34
    },
    # Row 4: 数据行（主表+子表字段同行，全部 #{} 列表绑定）
    "4": {
        "cells": {
            "1": {"text": "#{order.order_no}", "style": 2},     # 主表字段
            "2": {"text": "#{order.customer}", "style": 2},     # 主表字段
            "3": {"text": "#{order.order_date}", "style": 2},   # 主表字段
            "4": {"text": "#{detail.product}", "style": 2},     # 子表字段
            "5": {"text": "#{detail.spec}", "style": 2},        # 子表字段
            "6": {"text": "#{detail.price}", "style": 2},       # 子表字段
            "7": {"text": "#{detail.qty}", "style": 2},         # 子表字段
            "8": {"text": "#{detail.subtotal}", "style": 2},    # 子表字段
        }
    },
    "len": 200
}

cols = {
    "1": {"width": 130},  "2": {"width": 80},   "3": {"width": 100},
    "4": {"width": 150},  "5": {"width": 120},  "6": {"width": 80},
    "7": {"width": 60},   "8": {"width": 100},  "len": 100
}

merges = ["B2:I2"]  # 标题合并8列
```

---

## 三、联动 API 参考

### 查询联动配置

`GET /jmreport/link/getLinkData?linkType=4&reportId={reportId}`

**返回示例：**
```json
{
  "success": true,
  "result": [{
    "id": "1000296316821393408",
    "reportId": "报表ID",
    "parameter": "{\"main\":\"order\",\"sub\":\"detail\",\"subReport\":[{\"mainField\":\"id\",\"subParam\":\"order_id\",\"tableIndex\":1}]}",
    "linkName": "订单主子表联动",
    "linkType": "4"
  }]
}
```

### 新增/编辑联动

`POST /jmreport/link/saveAndEdit`（不传 id=新增，传 id=编辑）

### 删除联动

`POST /jmreport/link/delete`
```json
{"id": "联动配置ID"}
```

### parameter 结构

```json
{
    "main": "order",            // 主表 dbCode
    "sub": "detail",            // 子表 dbCode
    "subReport": [{
        "mainField": "id",      // 主表关联字段
        "subParam": "order_id", // 子表参数名
        "tableIndex": 1         // 子表序号（从1开始）
    }]
}
```

---

## 四、完整创建流程（SQL 数据集）

使用 `test_order_main`（订单主表）和 `test_order_product`（订单商品表）两张数据库表。

### Step 1: 创建空报表

```python
report_id = gen_id()
# save 空报表 → 获取 report_id
```

### Step 2: 解析主表 SQL 并保存数据集

```python
main_sql = "select id, order_code, order_date, descc from test_order_main"

# 解析 SQL 获取字段
main_parse = api_request('/jmreport/queryFieldBySql', {"sql": main_sql, "dbSource": "", "type": "0"})
main_fields = main_parse['result']['fieldList']

# 保存主表数据集
main_db = {
    "izSharedSource": 0, "jimuReportId": report_id,
    "dbCode": "orderMain",      # 主表编码
    "dbChName": "订单主表",
    "dbType": "0",              # 0=SQL
    "dbSource": "",
    "isList": "1",
    "isPage": "1",              # 主表可分页
    "dbDynSql": main_sql,
    "fieldList": main_fields,
    "paramList": []             # 主表无参数
}
api_request('/jmreport/saveDb', main_db)
```

### Step 3: 解析子表 SQL 并保存数据集

```python
# 子表 SQL 用 ${pid} 参数关联主表
sub_sql = "select id, product_name, price, num, order_fk_id from test_order_product where order_fk_id = '${pid}'"

sub_parse = api_request('/jmreport/queryFieldBySql', {"sql": sub_sql, "dbSource": "", "type": "0"})
sub_fields = sub_parse['result']['fieldList']

sub_db = {
    "izSharedSource": 0, "jimuReportId": report_id,
    "dbCode": "orderSub",       # 子表编码
    "dbChName": "订单商品",
    "dbType": "0",              # 0=SQL
    "dbSource": "",
    "isList": "1",
    "isPage": "0",              # 子表不分页！
    "dbDynSql": sub_sql,
    "fieldList": sub_fields,
    # 子表必须声明参数 pid，searchFlag=0
    "paramList": [
        {"paramName": "pid", "paramTxt": "订单ID", "paramValue": "",
         "widgetType": "String", "orderNum": 1, "searchFlag": 0, "searchMode": 1}
    ]
}
api_request('/jmreport/saveDb', sub_db)
```

### Step 4: 配置主子表联动

```python
parameter = json.dumps({
    "main": "orderMain",
    "sub": "orderSub",
    "subReport": [{
        "mainField": "id",      # 主表关联字段（test_order_main.id）
        "subParam": "pid",      # 子表参数名（对应 SQL 中的 ${pid}）
        "tableIndex": 1
    }]
}, ensure_ascii=False)

link_data = {
    "mainReport": "orderMain",
    "subReport": "orderSub",
    "linkName": "订单主子联动",
    "parameter": parameter,
    "linkType": "4",
    "reportId": report_id
}
api_request('/jmreport/link/saveAndEdit', link_data)
```

### Step 5: 保存报表设计

```python
rows = {
    "1": {
        "cells": {"1": {"text": "订单商品明细表", "style": 5, "merge": [0, 5]}},
        "height": 45
    },
    "2": {"cells": {}, "height": 15},
    "3": {
        "cells": {
            "1": {"text": "订单编号", "style": 4},
            "2": {"text": "下单日期", "style": 4},
            "3": {"text": "描述", "style": 4},
            "4": {"text": "商品名称", "style": 4},
            "5": {"text": "单价", "style": 4},
            "6": {"text": "数量", "style": 4},
        },
        "height": 34
    },
    # 主表+子表同行，全用 #{}
    "4": {
        "cells": {
            "1": {"text": "#{orderMain.order_code}", "style": 2},   # 主表
            "2": {"text": "#{orderMain.order_date}", "style": 2},   # 主表
            "3": {"text": "#{orderMain.descc}", "style": 2},        # 主表
            "4": {"text": "#{orderSub.product_name}", "style": 2},  # 子表
            "5": {"text": "#{orderSub.price}", "style": 2},         # 子表
            "6": {"text": "#{orderSub.num}", "style": 2},           # 子表
        }
    },
    "len": 200
}

cols = {
    "1": {"width": 140}, "2": {"width": 110}, "3": {"width": 160},
    "4": {"width": 160}, "5": {"width": 90},  "6": {"width": 70},
    "len": 100
}

merges = ["B2:G2"]  # 标题合并6列
```

---

## 五、预览效果

```
┌──────────────────────────────────────────────────────────┐
│                   订单销售明细表                            │
│                                                           │
│ 订单编号       │客户│下单日期  │商品名称      │规格       │单价 │数量│小计     │
├───────────────┼───┼────────┼────────────┼─────────┼────┼──┼───────┤
│               │   │        │iPhone 15 Pro│256GB 黑色│8999│1 │8999   │
│ORD-2026-001  │张三│2026-3-1│AirPods Pro 2│USB-C    │1799│1 │1799   │
│               │   │        │手机壳       │MagSafe  │399 │2 │798    │
│               │   │        │充电器       │20W USB-C│149 │2 │298    │
├───────────────┼───┼────────┼────────────┼─────────┼────┼──┼───────┤
│ORD-2026-002  │李四│2026-3-5│iPad Air     │M2/128GB │4799│1 │4799   │
│               │   │        │Apple Pencil │二代     │999 │1 │999    │
│               │   │        │键盘式保护壳  │11寸     │2499│1 │2499   │
├───────────────┼───┼────────┼────────────┼─────────┼────┼──┼───────┤
│ORD-2026-003  │王五│2026-3-10│MacBook Pro │M3 Pro   │14999│1│14999  │
│               │   │        │...         │...      │... │..│...    │
└──────────────────────────────────────────────────────────┘
```

主表字段（订单编号/客户/日期）在同一订单的多行中自动合并显示。

---

## 六、注意事项

1. **多源报表 vs 主子表报表选择**
   - 需要列表展开（如订单列表+明细）→ 多源报表（本示例），主子表都用 `#{}`
   - 需要套打/卡片式（如单张订单详情）→ 主子表报表（master-sub-table），主表用 `${}`

2. **子表必须声明参数且 searchFlag=0**
   - paramList 必须包含关联参数（如 order_id）
   - searchFlag 必须为 0（不显示查询条件，由联动自动传值）

3. **子表不分页**（isPage="0"），否则子数据可能不完整

4. **linkType="4" 是主子表联动**
   - linkType="2" 是图表联动，不要混用
   - parameter 是 JSON **字符串**（不是对象），需要 `json.dumps()`

5. **JSON 数据集的关联**
   - JSON 数据中子表需包含关联字段（如 order_id）
   - 主表的 id 字段值必须与子表的 order_id 字段值对应

6. **数据集类型不限**
   - 主表和子表可以是不同类型（SQL+JSON、API+JavaBean 等混搭）
   - 联动配置方式完全相同

7. **版本要求**：需要 JimuReport v1.7.2-beta 及更高版本