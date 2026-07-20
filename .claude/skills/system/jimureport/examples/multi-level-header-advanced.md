# 多级循环表头 — 进阶（示例4-5）

> 文件拆分索引：
> - `multi-level-header-basic.md` — 示例1-3（基础多级表头）
> - 本文件：示例4-5（交叉报表 + 区域销售统计）
> - `multi-level-header-api.md` — 特殊规则 + 示例6（API数据集）+ 踩坑记录

---

## 示例4：交叉报表（年度学生成绩）

**场景：** 年度横向展开，班级+学生纵向分组，考试总成绩为交叉值
**参考文档：** https://help.jimureport.com/datareport/crossReport
**数据集类型：** JSON 数据集（dbType: "3"）

### 效果预览

```
┌─────────────────────────────────────────────┐
│           年度学生成绩交叉报表                  │
├──────┬──────┬────────┬────────┬────────┤
│班级\学生    │ 2022年 │ 2023年 │ 2024年 │ ← groupRight(year)
│  成绩\年度  │        │        │        │   斜线表头
├──────┼──────┼────────┼────────┼────────┤
│      │ 张三 │  580   │  612   │  645   │
│ 一班 │ 李四 │  520   │  558   │  590   │ ← group(class_name) + group(student)
│      │ 王五 │  495   │  530   │  562   │   + dynamic(total_score)
├──────┼──────┼────────┼────────┼────────┤
│ 二班 │ 赵六 │  610   │  635   │  668   │
│      │ ...  │  ...   │  ...   │  ...   │
├──────┴──────┼────────┼────────┼────────┤
│    总计      │=SUM(D3)│        │        │
└─────────────┴────────┴────────┴────────┘
```

### 核心语法

| 行 | 字段 | 语法 | 属性 |
|----|------|------|------|
| Row 1 | year | `#{score.groupRight(year)}年` | `aggregate:"group"`, `direction:"right"` |
| Row 2 | class_name | `#{score.group(class_name)}` | `aggregate:"group"` |
| Row 2 | student | `#{score.group(student)}` | `aggregate:"group"` |
| Row 2 | total_score | `#{score.dynamic(total_score)}` | `aggregate:"dynamic"` |
| Row 3 | 总计 | `=SUM(D3)` | — |

### 完整 JSON

```json
{
    "rows": {
        "0": {
            "cells": {
                "0": {"rendered": "", "text": ""},
                "1": {"merge": [0, 2], "style": 6, "text": "年度学生成绩交叉报表"}
            },
            "height": 70
        },
        "1": {
            "cells": {
                "1": {"rendered": "", "lineStart": "lefttop", "merge": [0, 1], "style": 2,
                      "text": "班级\\学生|成绩|年度"},
                "3": {"style": 8, "text": "#{score.groupRight(year)}年",
                      "aggregate": "group", "direction": "right"}
            },
            "height": 45
        },
        "2": {
            "cells": {
                "1": {"style": 9, "text": "#{score.group(class_name)}", "aggregate": "group"},
                "2": {"style": 9, "text": "#{score.group(student)}", "aggregate": "group"},
                "3": {"decimalPlaces": "0", "rendered": "", "style": 10,
                      "text": "#{score.dynamic(total_score)}", "aggregate": "dynamic"}
            },
            "height": 35
        },
        "3": {
            "cells": {
                "1": {"merge": [0, 1], "style": 11, "text": "总计"},
                "3": {"style": 12, "text": "=SUM(D3)"}
            },
            "height": 35
        },
        "len": 100
    },
    "cols": {"0": {"width": 36}, "1": {"width": 80}, "2": {"width": 80}, "3": {"width": 90}, "len": 100},
    "merges": ["B1:D1", "B2:C2", "B4:C4"],
    "isGroup": true,
    "groupField": "score.class_name",
    "styles": [
        {"bgcolor": "#5b9cd6"},
        {"bgcolor": "#5b9cd6", "color": "#ffffff"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#5b9cd6", "color": "#ffffff"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}},
        {"font": {"size": 16}},
        {"font": {"size": 16, "bold": true}},
        {"align": "center", "font": {"size": 16, "bold": true}},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "align": "center"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#5b9cd6", "color": "#ffffff", "align": "center"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#9cc2e6", "align": "center"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "align": "center", "font": {"size": 9}},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#9cc2e6", "align": "center"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#9cc2e6", "format": "number", "align": "center"}
    ]
}
```

### 关键样式索引

| 索引 | 效果 | 用途 |
|------|------|------|
| 2 | 深蓝底白字+边框 | 斜线表头 |
| 6 | 居中+加粗16号 | 标题行 |
| 8 | 深蓝底白字+居中+边框 | 横向表头（年度） |
| 9 | 浅蓝底+居中+边框 | 纵向分组（班级、学生） |
| 10 | 白底+居中+9号字+边框 | dynamic 数据值 |
| 11/12 | 浅蓝底+居中+边框 | 总计标签/总计值 |

### 与多级循环表头的区别

| 特性 | 交叉报表（本示例） | 多级循环表头（示例1） |
|------|-----------------|-------------------|
| 横向表头层数 | 1层（year） | 2层（year + mouth） |
| 纵向分组 | 有（class_name + student） | 有（diqu + class） |
| 斜线表头 | 2格合并（班级\学生\成绩\年度） | 4格合并（地区\销量\时间） |
| 适用场景 | 简单行列交叉 | 多级动态列头 |

---

## 示例5：区域销售统计（横向分组 + 列标题 + compute 小计）

**场景：** 月份横向展开，区域+省纵向分组，每个月份下有销售/赠送/比例/小计四列
**数据表：** `area_sales_stats`：region(区域), province(省), month(月份), sales(销售额), donation(捐赠), ratio(比例)

### 效果预览

```
┌────────────────────────────────────────────────────────────┐
│                      区域销售统计                             │
├──────┬──────┬──────────────────────┬──────────────────────┤
│  地区        │        1月           │        2月           │ ← groupRight(month) merge[0,3]
│     销售额   ├──────┬──────┬───┬────┼──────┬──────┬───┬────┤
│             │ 销售 │ 赠送 │比例│小计│ 销售 │ 赠送 │比例│小计│ ← 列标题行
├──────┼──────┼──────┼──────┼───┼────┼──────┼──────┼───┼────┤
│ 华南 │ 广东 │85000 │3400  │4.0│88400│92000│3680 │4.0│95680│
│      │ 广西 │45000 │1800  │4.0│46800│52000│2080 │4.0│54080│
│ 华东 │ 江苏 │72000 │2880  │4.0│74880│68000│2720 │4.0│70720│
│      │ 浙江 │65000 │2600  │4.0│67600│71000│2840 │4.0│73840│
└──────┴──────┴──────┴──────┴───┴────┴──────┴──────┴───┴────┘
```

### rows 布局

| 行号 | 用途 | 关键配置 |
|------|------|---------|
| 0 | 标题 | `merge:[0,3]` |
| 1 | 斜线表头 + groupRight(month) | `lineStart:"lefttop"`, `merge:[1,1]`; groupRight `merge:[0,3]` 合并4列 |
| 2 | 列标题（销售/赠送/比例/小计） | 蓝底白字表头样式 |
| 3 | 数据行 | group(region) + group(province) + dynamic(sales) + dynamic(donation) + dynamic(ratio) + compute(sales+donation) |

### 核心配置

**groupRight 合并规则：** 下方有4个字段（sales, donation, ratio, compute），所以 `merge: [0, 3]` 合并4列。

**compute 小计：** `#{area.compute(sales+donation)}` 在每个月份分组内自动计算。

### 完整 JSON

```json
{
    "rows": {
        "0": {
            "cells": {
                "0": {"rendered": "", "text": ""},
                "1": {"merge": [0, 3], "style": 6, "text": "区域销售统计"}
            },
            "height": 70
        },
        "1": {
            "cells": {
                "1": {"rendered": "", "lineStart": "lefttop", "merge": [1, 1], "style": 2,
                      "text": "地区|销售额|时间"},
                "3": {"style": 8, "text": "#{area.groupRight(month)}",
                      "aggregate": "group", "direction": "right", "merge": [0, 3]}
            },
            "height": 40
        },
        "2": {
            "cells": {
                "3": {"style": 8, "text": "销售"},
                "4": {"style": 8, "text": "赠送"},
                "5": {"style": 8, "text": "比例"},
                "6": {"style": 8, "text": "小计"}
            },
            "height": 34
        },
        "3": {
            "cells": {
                "1": {"style": 9, "text": "#{area.group(region)}", "aggregate": "group"},
                "2": {"style": 9, "text": "#{area.group(province)}", "aggregate": "group"},
                "3": {"decimalPlaces": "2", "rendered": "", "style": 10,
                      "text": "#{area.dynamic(sales)}", "aggregate": "dynamic"},
                "4": {"decimalPlaces": "2", "style": 10,
                      "text": "#{area.dynamic(donation)}", "aggregate": "dynamic"},
                "5": {"decimalPlaces": "2", "style": 10,
                      "text": "#{area.dynamic(ratio)}", "aggregate": "dynamic"},
                "6": {"decimalPlaces": "2", "style": 10,
                      "text": "#{area.compute(sales+donation)}"}
            },
            "height": 35
        },
        "len": 100
    },
    "cols": {"0": {"width": 36}, "1": {"width": 80}, "2": {"width": 80}, "3": {"width": 90}, "4": {"width": 90}, "5": {"width": 70}, "6": {"width": 90}, "len": 100},
    "merges": ["B1:E1", "B2:C3"],
    "isGroup": true,
    "groupField": "area.region",
    "styles": [
        {"bgcolor": "#5b9cd6"},
        {"bgcolor": "#5b9cd6", "color": "#ffffff"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#5b9cd6", "color": "#ffffff"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}},
        {"font": {"size": 16}},
        {"font": {"size": 16, "bold": true}},
        {"align": "center", "font": {"size": 16, "bold": true}},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "align": "center"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#5b9cd6", "color": "#ffffff", "align": "center"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#9cc2e6", "align": "center"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "align": "center", "font": {"size": 9}},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#9cc2e6", "align": "center"},
        {"border": {"top": ["thin","#d8d8d8"], "left": ["thin","#d8d8d8"], "bottom": ["thin","#d8d8d8"], "right": ["thin","#d8d8d8"]}, "bgcolor": "#9cc2e6", "format": "number", "align": "center"}
    ]
}
```

### 关键点

1. **groupRight merge 列数 = 下方 dynamic/compute 字段数** — 本例有4个字段（sales, donation, ratio, compute），所以 `merge: [0, 3]`
2. **斜线表头 merge 行数 = 列标题行数 + 1** — 本例列标题占1行，斜线表头 `merge: [1, 1]` 跨2行2列
3. **列标题行跟随 groupRight 循环** — "销售/赠送/比例/小计"会在每个月份下重复
4. **compute 表达式** — `#{area.compute(sales+donation)}` 支持 `+` `-` `*` `/` 四则运算
5. **中文文本需要确保 UTF-8** — Python 写入时用 `ensure_ascii=False` + `.encode('utf-8')`，避免 unicode 转义导致乱码
