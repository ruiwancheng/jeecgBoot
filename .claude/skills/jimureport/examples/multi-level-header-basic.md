# 多级循环表头 — 基础（示例1-3）

> 文件拆分索引：
> - 本文件：示例1-3（基础多级表头）
> - `multi-level-header-advanced.md` — 示例4-5（交叉报表 + 区域销售统计）
> - `multi-level-header-api.md` — 特殊规则 + 示例6（API数据集）+ 踩坑记录

**类型：** 多级循环表头（交叉表）
**特征：** `groupRight()` 横向展开表头 + `dynamic()` 填充数据 + `group()` 纵向分组
**参考文档：** https://help.jimureport.com/group/directionDynamic

---

## 示例1：各地区商品销售额一栏表（二级横向表头）

year（年份）和 mouth（月份）作为二级横向表头动态展开，diqu（地区）和 class（类别）纵向分组，sales（销售额）为交叉数据。

### 效果预览

```
┌──────────────────────────────────────────────────────┐
│              各地区商品销售额一栏表                       │
├──────┬──────┬───────────────────┬───────────────────┤
│ 地区 ＼时间 │       2019年       │      2020年        │ ← groupRight(year)
│  ＼销量    ├────┬────┬────┬────┼────┬────┬────┬────┤
│            │1月 │2月 │... │12月│6月 │7月 │... │12月│ ← groupRight(mouth)
├──────┬─────┼────┼────┼────┼────┼────┼────┼────┼────┤
│      │调味品│840 │570 │... │271 │128 │213 │... │271 │ ← dynamic(sales)
│ 华北 ├─────┼────┼────┼────┼────┼────┼────┼────┼────┤
│      │肉类  │... │... │... │... │... │... │... │... │
├──────┼─────┼────┼────┼────┼────┼────┼────┼────┼────┤
│ 华东 │...  │... │... │... │... │... │... │... │... │
├──────┴─────┼────┼────┼────┼────┼────┼────┼────┼────┤
│    总计     │=SUM│    │    │    │    │    │    │    │
└────────────┴────┴────┴────┴────┴────┴────┴────┴────┘
```

### 核心语法

| 行 | 字段 | 语法 | 属性 | 说明 |
|----|------|------|------|------|
| Row 1 | year | `#{db.groupRight(year)}年` | `aggregate:"group"`, `direction:"right"` | 一级表头，横向展开 |
| Row 2 | mouth | `#{db.groupRight(mouth)}` | `aggregate:"group"`, `direction:"right"` | 二级表头，嵌套在 year 下 |
| Row 3 | diqu | `#{db.group(diqu)}` | `aggregate:"group"` | 纵向分组，相同值合并 |
| Row 3 | class | `#{db.group(class)}` | `aggregate:"group"` | 纵向分组 |
| Row 3 | sales | `#{db.dynamic(sales)}` | `aggregate:"dynamic"` | 交叉数据填充 |

### 斜线表头

```json
{
    "text": "地区|销量|时间",
    "lineStart": "lefttop",
    "merge": [1, 1],
    "style": 2
}
```
- `lineStart: "lefttop"` — 从左上角画斜线
- `text` 用 `|` 分隔多个标签（左下、中间、右上）

### rows 布局（行号从 0 开始）

| 行号 | 用途 | 关键属性 |
|------|------|---------|
| 0 | 标题（合并3列） | `merge:[0,2]`, style 6 |
| 1 | 一级表头：斜线表头 + year 横向 | `lineStart:"lefttop"`, `groupRight(year)`, `direction:"right"` |
| 2 | 二级表头：mouth 横向 | `groupRight(mouth)`, `direction:"right"` |
| 3 | 数据行：地区分组 + 类别分组 + 销售额动态 | `group(diqu)`, `group(class)`, `dynamic(sales)` |
| 4 | 总计行 | `=SUM(D4)` |

### 顶层分组配置

```json
{
    "isGroup": true,
    "groupField": "db.diqu"
}
```

### merges 合并

```json
["B1:D1", "B2:C3", "B5:C5"]
```
- `B1:D1` — 标题合并
- `B2:C3` — 斜线表头占 2行2列
- `B5:C5` — 总计行合并

### 完整 jsonStr

```json
{"loopBlockList":[],"querySetting":{"izOpenQueryBar":false,"izDefaultQuery":true},"recordSubTableOrCollection":{"group":[],"record":[],"range":[]},"printConfig":{"layout":"landscape","paper":"A3","isBackend":false,"width":297,"definition":1,"marginX":10,"height":420,"marginY":10},"hidden":{"rows":[],"cols":[]},"queryFormSetting":{"useQueryForm":false,"dbKey":"","idField":""},"dbexps":[],"toolPrintSizeObj":{"printType":"A4","widthPx":718,"heightPx":1047},"dicts":[],"fillFormToolbar":{"show":true,"btnList":["save","subTable_add","verify","subTable_del","print","close","first","prev","next","paging","total","last","exportPDF","exportExcel","exportWord"]},"freeze":"A1","dataRectWidth":303,"isViewContentHorizontalCenter":false,"autofilter":{},"validations":[],"cols":{"0":{"width":36},"1":{"width":87},"2":{"width":80},"len":100},"area":{"sri":11,"sci":4,"eri":11,"eci":4,"width":100,"height":25},"pyGroupEngine":false,"submitHandlers":[],"excel_config_id":"报表ID","hiddenCells":[],"zonedEditionList":[],"rows":{"0":{"cells":{"0":{"rendered":"","text":""},"1":{"merge":[0,2],"style":6,"text":"各地区商品销售额一栏表"}},"height":83},"1":{"cells":{"1":{"rendered":"","lineStart":"lefttop","merge":[1,1],"style":2,"text":"地区|销量|时间"},"3":{"style":8,"text":"#{db.groupRight(year)}年","aggregate":"group","direction":"right"}},"height":40},"2":{"cells":{"3":{"style":8,"text":"#{db.groupRight(mouth)}","aggregate":"group","direction":"right"}},"height":34},"3":{"cells":{"1":{"style":28,"text":"#{db.group(diqu)}","aggregate":"group"},"2":{"style":28,"text":"#{db.group(class)}","aggregate":"group"},"3":{"decimalPlaces":"0","rendered":"","style":31,"text":"#{db.dynamic(sales)}","aggregate":"dynamic"}},"height":38},"4":{"cells":{"1":{"merge":[0,1],"style":24,"text":"总计"},"3":{"style":25,"text":"=SUM(D4)"}},"height":37},"len":100},"rpbar":{"show":true,"pageSize":"","btnList":[]},"groupField":"db.diqu","fixedPrintHeadRows":[],"fixedPrintTailRows":[],"displayConfig":{},"fillFormInfo":{"layout":{"direction":"horizontal","width":200,"height":45}},"background":false,"name":"sheet1","styles":[{"bgcolor":"#5b9cd6"},{"bgcolor":"#5b9cd6","color":"#ffffff"},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"bgcolor":"#5b9cd6","color":"#ffffff"},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]}},{"font":{"size":16}},{"font":{"size":16,"bold":true}},{"align":"center","font":{"size":16,"bold":true}},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"align":"center"},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"bgcolor":"#5b9cd6","color":"#ffffff","align":"center"},{"bgcolor":"#9cc2e6"},{"bgcolor":"#9cc2e6","align":"center"},{"align":"center"},{"bgcolor":"#9cc2e6","format":"number"},{"bgcolor":"#9cc2e6","format":"number","align":"center"},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"align":"center","font":{"size":9}},{"border":{"top":["thin","#000"],"left":["thin","#000"],"bottom":["thin","#000"],"right":["thin","#000"]},"bgcolor":"#5b9cd6","color":"#ffffff"},{"bgcolor":"#5b9cd6","color":"#ffffff","align":"center"},{"border":{"top":["thin","#000"],"left":["thin","#000"],"bottom":["thin","#000"],"right":["thin","#000"]},"bgcolor":"#5b9cd6","color":"#ffffff","align":"center"},{"border":{"top":["thin","#000"],"left":["thin","#000"],"bottom":["thin","#000"],"right":["thin","#000"]},"align":"center","font":{"size":9}},{"border":{"top":["thin","#000"],"left":["thin","#000"],"bottom":["thin","#000"],"right":["thin","#000"]},"bgcolor":"#9cc2e6","align":"center"},{"border":{"top":["thin","#000"],"left":["thin","#000"],"bottom":["thin","#000"],"right":["thin","#000"]},"bgcolor":"#9cc2e6","format":"number","align":"center"},{"border":{"top":["thin","#000"],"left":["thin","#000"],"bottom":["thin","#000"],"right":["thin","#000"]},"bgcolor":"#5b9cd6","color":"#fe0000"},{"color":"#fe0000"},{"color":"#ffffff"},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"bgcolor":"#9cc2e6","align":"center"},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"bgcolor":"#9cc2e6","format":"number","align":"center"},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"underline":true,"align":"center","font":{"size":9}},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"underline":false,"align":"center","font":{"size":9}},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"bgcolor":"#d7f2f9","align":"center","font":{"size":9}},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"format":"number","align":"center","font":{"size":9}},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"bgcolor":"#ffff01","format":"number","align":"center","font":{"size":9}},{"border":{"top":["thin","#d8d8d8"],"left":["thin","#d8d8d8"],"bottom":["thin","#d8d8d8"],"right":["thin","#d8d8d8"]},"bgcolor":"#ffffff","format":"number","align":"center","font":{"size":9}}],"fillFormStyle":"default","isGroup":true,"freezeLineColor":"rgb(185, 185, 185)","merges":["B1:D1","B2:C3","B5:C5"]}
```

---

## 示例2：区域省份按月销售统计（纵向+横向组合）

行头纵向分组（区域+省份），列头横向分组（月份），多个动态值字段（销售额+捐赠）。

### 效果预览

```
┌────────┬────────┬──────────────────┬──────────────────┬───
│        │        │       1月        │       2月        │ ← groupRight(month)
│ 区域   │ 省份   ├────────┬─────────┼────────┬─────────┤
│        │        │ 销售额 │ 捐赠    │ 销售额 │ 捐赠    │ ← dynamic(sales), dynamic(gift)
├────────┼────────┼────────┼─────────┼────────┼─────────┤
│ 华南   │ 广东   │ 50000  │ 2000    │ 60000  │ 2500    │ ← group(region) + group(province)
│        │ 广西   │ 35000  │ 1500    │ 42000  │ 1800    │
│ 华东   │ 江苏   │ 45000  │ 1800    │ 55000  │ 2200    │
└────────┴────────┴────────┴─────────┴────────┴─────────┘
```

### 核心语法

| 部分 | 语法 | 说明 |
|------|------|------|
| 行头（纵向分组） | `#{db.group(region)}`, `#{db.group(province)}` | 纵向合并相同值 |
| 列头（横向分组） | `#{db.groupRight(month)}` | 横向展开为动态列 |
| 数据区域（动态值） | `#{db.dynamic(sales)}`, `#{db.dynamic(gift)}` | 填充交叉单元格，每个横向分组值下重复展开 |

### 完整 JSON

```json
{
    "rows": {
        "1": {
            "cells": {"1": {"text": "区域销售统计", "style": 5, "merge": [0, 7]}},
            "height": 45
        },
        "2": {
            "cells": {
                "1": {"text": "区域", "style": 4},
                "2": {"text": "省份", "style": 4},
                "3": {"text": "#{area.groupRight(month)}", "style": 4,
                      "aggregate": "group", "direction": "right"}
            },
            "height": 34
        },
        "3": {
            "cells": {
                "1": {"text": "#{area.group(region)}", "style": 2, "aggregate": "group"},
                "2": {"text": "#{area.group(province)}", "style": 2, "aggregate": "group"},
                "3": {"text": "#{area.dynamic(sales)}", "style": 2},
                "4": {"text": "#{area.dynamic(gift)}", "style": 2}
            }
        },
        "len": 200
    },
    "cols": {"1": {"width": 80}, "2": {"width": 80}, "3": {"width": 100}, "4": {"width": 100}, "len": 100},
    "merges": ["B1:I1"]
}
```

---

## 示例3：省份月度销售统计（纯横向多级）

月份和省份都横向展开（groupRight），销售额为动态值。无纵向分组。

### 效果预览

```
              省份月度销售统计
┌────────┬────────┬────────┬────────┬────────┬───
│ 月份   │  1月   │  1月   │  1月   │  2月   │ ← groupRight(month)
│ 省份   │ 广东省 │ 江苏省 │ 浙江省 │ 广东省 │ ← groupRight(province)
│ 销售额 │ 85000  │ 72000  │ 65000  │ 92000  │ ← dynamic(sales)
└────────┴────────┴────────┴────────┴────────┴───
```

### 完整 JSON

```json
{
    "rows": {
        "1": {
            "cells": {"1": {"text": "省份月度销售统计", "style": 5, "merge": [0, 7]}},
            "height": 45
        },
        "2": {
            "cells": {
                "1": {"text": "月份", "style": 4},
                "2": {"text": "#{pms.groupRight(month)}", "style": 4,
                      "aggregate": "group", "direction": "right"}
            },
            "height": 34
        },
        "3": {
            "cells": {
                "1": {"text": "省份", "style": 4},
                "2": {"text": "#{pms.groupRight(province)}", "style": 4,
                      "aggregate": "group", "direction": "right"}
            },
            "height": 34
        },
        "4": {
            "cells": {
                "1": {"text": "销售额", "style": 2},
                "2": {"text": "#{pms.dynamic(sales)}", "style": 2}
            }
        },
        "len": 200
    },
    "cols": {"1": {"width": 80}, "2": {"width": 100}, "len": 100},
    "merges": ["B1:I1"]
}
```
