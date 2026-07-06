# 多级循环表头 — API数据集 & 特殊规则（示例6 + 踩坑）

> 文件拆分索引：
> - `multi-level-header-basic.md` — 示例1-3（基础多级表头）
> - `multi-level-header-advanced.md` — 示例4-5（交叉报表 + 区域销售统计）
> - 本文件：特殊规则 + 示例6（API数据集）+ 踩坑记录

---

## 特殊规则（适用所有示例）

1. **动态列之前的列字段必须设置成纵向分组（group）** — 行头字段不能是普通字段
2. **横向分组下必须有动态列（dynamic）** — groupRight 行下方必须有 dynamic 字段
3. **动态列数据必须设置成动态属性** — 值字段必须用 `dynamic()` 语法
4. **第一条数据必须完整** — 数据集第一条记录必须包含所有横向维度
5. **最多3级动态表头** — groupRight 最多嵌套3层
6. **dynamic 值行样式与数据一致** — 用普通数据样式，不要用表头样式
7. **所有边框颜色保持一致** — 统一用 `#d8d8d8` 浅灰，不要混用 `#000`
8. **groupRight merge 合并列数** — `merge: [0, N-1]`，N = 下方 dynamic/compute 字段数
9. **中文文本 UTF-8** — Python 调用 API 时必须 `json.dumps(data, ensure_ascii=False).encode('utf-8')`，避免斜线表头等中文文本变成乱码

---

## 交叉报表常见踩坑（2026-04-02 补充）

> 以下是创建交叉报表时容易出错的点，务必注意：

**A. rows 索引从 "0" 开始**
- rows 的 key 必须从 `"0"` 开始（不是 `"1"`）
- `rows["0"]` = 第1行（标题），`rows["1"]` = 第2行（表头），以此类推
- merges 中 UI 行号 = code_row + 1

**B. API 数据集字段必须手动定义**
- API 数据集（dbType="1"）不支持 `queryFieldBySql` 解析
- 必须手动构建 fieldList，不能依赖解析接口返回
- 示例：`[{"fieldName": "diqu", "fieldText": "地区", "widgetType": "String", ...}, ...]`

**C. groupField 格式是 "数据集编码.字段名"**
- 不是 `db.字段名`，而是 `groupsub.diqu`（假设数据集编码为 groupsub）
- 如果格式错误，分组不会生效

**D. cols 必须包含 "0" 作为左边距空列**
- `cols = {"0": {"width": 20}, "1": {"width": 80}, ...}`
- A 列（col "0"）是左边距空列，内容从 B 列（col "1"）开始
- 缺少 col "0" 会导致列对齐问题

**E. 纵向分组字段必须设置 aggregate:"group"**
```json
"cells": {
    "1": {"text": "#{groupsub.group(diqu)}", "style": 2, "aggregate": "group"},
    "2": {"text": "#{groupsub.group(class)}", "style": 2, "aggregate": "group"}
}
```

**F. 横向分组字段必须设置 aggregate:"group" 和 direction:"right"**
```json
"cells": {
    "3": {"text": "#{groupsub.groupRight(mouth)}", "style": 3,
          "aggregate": "group", "direction": "right"}
}
```

**G. 动态值字段必须设置 aggregate:"dynamic"**
```json
"cells": {
    "3": {"text": "#{groupsub.dynamic(sales)}", "style": 2, "aggregate": "dynamic"}
}
```

**H. merges 使用 UI 行号格式**
- `merges = ["B1:D1", "B4:C4"]` — 不是 code_row，是 UI 行号
- code_row "0" → UI 行号 1，所以 "B1:D1" 是第1行
- code_row "3" → UI 行号 4，所以 "B4:C4" 是第4行

**I. 总计行 sum 公式的单元格引用**
- `=SUM(D3)` 中 D3 是 UI 单元格引用
- 数据绑定行在 code_row "2"（UI 第3行），所以 sum 引用 D3

---

## 示例6：API 数据集交叉报表（地区→品类纵向 + 月份横向，已验证可用）

**场景：** 地区→品类双层纵向分组，月份横向动态展开，销售额为交叉值。**数据来源为 API 接口（dbType="1"），非 SQL。**
**验证时间：** 2026-04-02，调用 `http://api.jeecg.com/mock/26/groupsub`，2步全部 success=True。

### 效果预览

```
┌──────────────────────────────────────────────────┐
│            区域品类月度销售交叉报表                  │
├──────┬──────┬──────┬──────┬──────┬──────┬──────┤
│ 地区  │ 品类  │  1月  │  2月  │ ...  │ 12月  │  ← groupRight(mouth)
├──────┼──────┼──────┼──────┼──────┼──────┼──────┤
│      │ 饮料  │  840 │   33 │ ...  │  348 │
│ 东部  │ 点心  │  393 │  310 │ ...  │  348 │  ← group(diqu) + group(class)
│      │ ...  │  ... │  ... │ ...  │  ... │     + dynamic(sales)
├──────┼──────┼──────┼──────┼──────┼──────┤
│      总计    │=SUM  │      │ ...  │      │
└──────────────┴──────┴──────┴──────┴──────┘
```

### API 数据集（dbType="1"）关键参数

```python
db_data = {
    "dbType": "1",          # API 数据集，不是 SQL
    "dbDynSql": api_url,    # 与 apiUrl 相同
    "apiUrl": api_url,      # 设计器 UI「Api地址」读取此字段
    "apiMethod": "0",       # "0"=GET, "1"=POST
    "isList": "1",
    "isPage": "0",          # 交叉报表必须不分页
    "fieldList": [          # 手动定义字段（API数据集不能用 queryFieldBySql）
        {"fieldName": "diqu",  "fieldText": "地区",  "widgetType": "String", "orderNum": 1, "tableIndex": 0, "extJson": "", "dictCode": ""},
        {"fieldName": "class", "fieldText": "品类",  "widgetType": "String", "orderNum": 2, "tableIndex": 0, "extJson": "", "dictCode": ""},
        {"fieldName": "year",  "fieldText": "年份",  "widgetType": "String", "orderNum": 3, "tableIndex": 0, "extJson": "", "dictCode": ""},
        {"fieldName": "mouth", "fieldText": "月份",  "widgetType": "String", "orderNum": 4, "tableIndex": 0, "extJson": "", "dictCode": ""},
        {"fieldName": "sales", "fieldText": "销售额", "widgetType": "String", "orderNum": 5, "tableIndex": 0, "extJson": "", "dictCode": ""},
    ],
    "paramList": []
}
```

> **注意：** API 数据集不支持 `queryFieldBySql`，字段必须手动定义。

### rows 布局（rows 从 "0" 开始，code_row N → merge UI行 N+1）

| code_row | 用途 | 关键属性 |
|----------|------|---------|
| "0" | 标题 `merge:[0,2]` → merge `B1:D1` | style 4 |
| "1" | 表头：地区\|品类\|`#{groupsub.groupRight(mouth)}` | `aggregate:"group"`, `direction:"right"` |
| "2" | 数据：`group(diqu)` \| `group(class)` \| `dynamic(sales)` | `aggregate:"group"` / `"dynamic"` |
| "3" | 总计 `merge:[0,1]` → merge `B4:C4` + `=SUM(D3)` | style 5 |

### 完整 rows / cols / merges / styles

```python
styles = [
    # 0 border only
    {"border": {"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]}},
    # 1 border + center
    {"border": {"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]}, "align":"center"},
    # 2 data: border + center + valign
    {"border": {"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]}, "align":"center","valign":"middle"},
    # 3 header: #5b9cd6 blue bg + white
    {"border": {"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]}, "align":"center","valign":"middle","bgcolor":"#5b9cd6","color":"#ffffff"},
    # 4 title: light blue + dark blue + bold 14
    {"border": {"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]}, "align":"center","valign":"middle","bgcolor":"#E6F2FF","color":"#0066CC","font":{"bold":True,"size":14}},
    # 5 total: mid-blue #9cc2e6
    {"border": {"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]}, "align":"center","valign":"middle","bgcolor":"#9cc2e6","color":"#333333"},
]

rows = {
    "0": {
        "cells": {"1": {"text": "区域品类月度销售交叉报表", "style": 4, "merge": [0, 2]}},
        "height": 50
    },
    "1": {
        "cells": {
            "1": {"text": "地区", "style": 3},
            "2": {"text": "品类", "style": 3},
            "3": {"text": "#{groupsub.groupRight(mouth)}", "style": 3,
                  "aggregate": "group", "direction": "right"}
        },
        "height": 34
    },
    "2": {
        "cells": {
            "1": {"text": "#{groupsub.group(diqu)}",   "style": 2, "aggregate": "group"},
            "2": {"text": "#{groupsub.group(class)}",  "style": 2, "aggregate": "group"},
            "3": {"text": "#{groupsub.dynamic(sales)}","style": 2, "aggregate": "dynamic"}
        }
    },
    "3": {
        "cells": {
            "1": {"text": "总计", "style": 5, "merge": [0, 1]},
            "3": {"text": "=SUM(D3)", "style": 5}   # D3 = data行 code_row"2" → UI行3
        },
        "height": 34
    },
    "len": 200
}

cols = {
    "0": {"width": 20},   # A 左边距
    "1": {"width": 80},   # B 地区
    "2": {"width": 80},   # C 品类
    "3": {"width": 70},   # D 月份动态列起始
    "len": 100
}

merges = ["B1:D1", "B4:C4"]
# B1:D1 → code_row"0" 标题（N=0, UI行=1）
# B4:C4 → code_row"3" 总计（N=3, UI行=4）
```

### 报表级分组与打印配置

```python
save_data = {
    # ... 其他字段 ...
    "isGroup": True,
    "groupField": "groupsub.diqu",   # 格式：dbCode.字段名（非 db.字段名）
    "printConfig": {
        "paper": "A3", "width": 297, "height": 420,
        "layout": "landscape",        # 横向，适应月份多列
        "definition": 1, "isBackend": False,
        "marginX": 10, "marginY": 10, "printCallBackUrl": ""
    },
}
```

### 执行步骤（2步，已优化，实测 ~0.5s）

```
Step 0 (本地): gen_id()            客户端生成 report_id，0 HTTP，orphan ID 直接可用
Step 1: POST /jmreport/saveDb     API数据集，isPage="0"，手动定义 fieldList
Step 2: POST /jmreport/save       完整设计，首次创建报表并关联数据集
```

> **原来是 3 步**（先空 /save 取 ID → saveDb → 完整 /save），**用 `gen_id()` 可省掉第一步**。
> 原理：saveDb 接受尚不存在的 orphan report_id，后续 /save 首次创建时自动关联。
> 实测：3 HTTP → 2 HTTP，耗时从 ~3s 压到 ~0.5s（2026-04-22 验证）。

```python
from jimureport_utils import Session, gen_id, make_designer, base_save, save_db

session = Session(BASE_URL, TOKEN)
report_id = gen_id()                          # 0 HTTP

save_db(session, report_id, DB_CODE, "数据集名",
        API_URL, field_list,
        db_type="1", api_url=API_URL, api_method="0",
        is_list="1", is_page="0")             # 1 HTTP

designer = make_designer(report_id, REPORT_NAME)
session.request("/save", base_save(
    report_id, designer,
    rows=rows, cols=cols, styles=styles, merges=merges, chartList=[],
    isGroup=True, groupField=f"{DB_CODE}.region",
    printConfig={"paper":"A3","width":297,"height":420,"layout":"landscape",
                 "definition":1,"isBackend":False,"marginX":10,"marginY":10,"printCallBackUrl":""}
))                                            # 1 HTTP
```

> `/jmreport/save` 不在签名接口列表中，**无需 X-Sign / X-TIMESTAMP**。
> `/jmreport/saveDb` 同样不需要签名。
> 签名只用于 `queryFieldBySql`、`executeSelectApi` 等查询类接口。

### 为已有报表添加查询条件（日期类型，yyyy-MM 年月选择器）

**需求：** 给交叉报表添加按年月筛选的查询条件。

**执行步骤（2步）：**

```
Step 1: POST /jmreport/saveDb    更新 paramList，添加日期查询参数
Step 2: POST /jmreport/save      重建完整报表设计，开启 querySetting.izOpenQueryBar
```

**paramList 日期参数配置：**

```python
param_list = [{
    "paramName": "mouth",         # 与数据字段名一致
    "paramTxt": "年月",            # 查询栏显示标签
    "widgetType": "date",         # 日期控件
    "searchMode": 1,              # paramList 日期类型固定用 1（输入框）
    "searchFlag": 1,              # 启用查询
    "searchFormat": "yyyy-MM",    # 年月选择器（不是 MM，那样只有月份）
    "paramValue": "",             # 无默认值
    "dictCode": "",
    "orderNum": 1
}]
```

> **常见 searchFormat：** `yyyy-MM-dd`(日期) / `yyyy-MM`(年月) / `yyyy`(年) / `MM`(月) / `yyyy-MM-dd HH:mm:ss`(日期时间)

**save 请求体中开启查询栏：**

```python
save_body = {
    # ... 完整报表设计字段 ...
    "querySetting": {"izOpenQueryBar": True, "izDefaultQuery": True},
}
```

### 踩坑记录：编辑报表设计时不要用 `get + spread + save`

**错误做法：**
```python
# ❌ 从 get/{id} 读取 jsonStr，修改 querySetting，再 spread 回 save
report = api_request(f'/jmreport/get/{REPORT_ID}')
design = json.loads(report['result']['jsonStr'])
design['querySetting']['izOpenQueryBar'] = True
save_body = {**design, "designerObj": ...}   # spread 所有字段
api_request('/jmreport/save', save_body)     # ← 可能丢失配置！
```

**问题：** `get/{id}` 返回的 `jsonStr` 可能与 `save` 期望的格式不完全一致，spread 回去后 `querySetting`、`paramList` 等配置会静默丢失。

**正确做法：**
```python
# ✅ 用已知的完整设计重建 save body，不依赖 get 返回值
save_body = {
    "designerObj": json.dumps(designer_obj, ensure_ascii=False),
    "rows": rows,        # 用原始已知的 rows
    "cols": cols,
    "styles": styles,
    "merges": merges,
    "querySetting": {"izOpenQueryBar": True, "izDefaultQuery": True},
    "isGroup": True,
    "groupField": "groupsub.diqu",
    # ... 其他完整字段 ...
}
```

> **原则：编辑报表时，`saveDb` 更新数据集 + `save` 重建完整设计，两步分开，每步用确定的数据。**
