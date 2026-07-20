# 横向分组示例合集

包含三种横向分组方式的完整示例。

---

## 示例1：横向动态分组 (groupRight + dynamic)

**场景：** 省份月度销售统计，月份和省份都横向展开，销售额为动态值
**数据表：** `province_monthly_sales`：province(省份), month(月份), sales(销售额)

### 布局

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
    "merges": ["B1:I1"],
    "styles": [
        {"border": {"bottom": ["thin","#000"], "top": ["thin","#000"], "left": ["thin","#000"], "right": ["thin","#000"]}},
        {"border": {"bottom": ["thin","#000"], "top": ["thin","#000"], "left": ["thin","#000"], "right": ["thin","#000"]}, "align": "center"},
        {"border": {"bottom": ["thin","#000"], "top": ["thin","#000"], "left": ["thin","#000"], "right": ["thin","#000"]}, "align": "center", "valign": "middle"},
        {"border": {"bottom": ["thin","#000"], "top": ["thin","#000"], "left": ["thin","#000"], "right": ["thin","#000"]}, "align": "center", "valign": "middle", "bgcolor": "#01b0f1"},
        {"border": {"bottom": ["thin","#000"], "top": ["thin","#000"], "left": ["thin","#000"], "right": ["thin","#000"]}, "align": "center", "valign": "middle", "bgcolor": "#01b0f1", "color": "#ffffff"},
        {"border": {"bottom": ["thin","#000"], "top": ["thin","#000"], "left": ["thin","#000"], "right": ["thin","#000"]}, "align": "center", "valign": "middle", "font": {"bold": true, "size": 14}, "bgcolor": "#E6F2FF", "color": "#0066CC"}
    ]
}
```

### 样式说明

- groupRight 列头行（月份、省份）：style 4（蓝底白字）
- dynamic 值行（销售额标签 + 值）：style 2（白底居中），与数据行一致
- 标题行：style 5（淡蓝底深蓝字加粗）

---

## 示例2：自定义横向分组 (customGroup)

**场景：** 员工信息横向统计表，每条记录展开为一列，每行一个字段
**数据集编码：** `hex`，字段为员工信息

### 布局

```
              员工信息横向统计表
┌──────┬────────┬────────┬────────┬───
│ 部门 │ 研发部 │ 研发部 │ 人事部 │ ← customGroup(department)
│ 学历 │ 本科   │ 本科   │ 本科   │ ← customGroup(education)
│ 性别 │ 男     │ 男     │ 女     │ ← customGroup(sex)
│ 年龄 │ 21     │ 25     │ 22     │ ← customGroup(age) 无direction，纵向
│ 姓名 │ 张三   │ 李四   │ 咪咪   │ ← customGroup(name)
│ 薪水 │ 8000   │ 8500   │ 9600   │ ← customGroup(salary)
└──────┴────────┴────────┴────────┴───
```

### 数据字段

| 行 | 标签 | 绑定 | direction |
|---|---|---|---|
| 2 | 部门 | `#{hex.customGroup(department)}` | right |
| 3 | 学历 | `#{hex.customGroup(education)}` | right |
| 4 | 性别 | `#{hex.customGroup(sex)}` | right |
| 5 | 年龄 | `#{hex.customGroup(age)}` | 无（纵向） |
| 6 | 姓名 | `#{hex.customGroup(name)}` | right |
| 7 | 薪水 | `#{hex.customGroup(salary)}` | right |

### 完整 JSON

```json
{"loopBlockList":[],"querySetting":{"izOpenQueryBar":false,"izDefaultQuery":true},"recordSubTableOrCollection":{"group":[],"record":[],"range":[]},"printConfig":{"paper":"A4","width":210,"height":297,"definition":1,"isBackend":false,"marginX":10,"marginY":10},"hidden":{"rows":[],"cols":[],"conditions":{"rows":{},"cols":{}}},"dbexps":[],"toolPrintSizeObj":{"printType":"A4","widthPx":718,"heightPx":1047},"dicts":[],"freeze":"A1","dataRectWidth":204,"isViewContentHorizontalCenter":false,"autofilter":{},"validations":[],"cols":{"0":{"width":44},"1":{"width":79},"2":{"width":81},"len":50},"area":{"sri":7,"sci":5,"eri":7,"eci":5,"width":100,"height":36},"excel_config_id":"1194552262320803840","hiddenCells":[],"zonedEditionList":[],"rows":{"1":{"cells":{"0":{"text":"员工信息横向统计表","style":9,"merge":[0,11]}},"height":97},"2":{"cells":{"1":{"text":"部门","style":7},"2":{"text":"#{hex.customGroup(department)}","style":11,"direction":"right"}},"isDrag":true,"height":40},"3":{"cells":{"1":{"text":"学历","style":7},"2":{"text":"#{hex.customGroup(education)}","style":11,"direction":"right"}},"isDrag":true,"height":39},"4":{"cells":{"1":{"text":"性别","style":7},"2":{"text":"#{hex.customGroup(sex)}","style":11,"direction":"right"}},"isDrag":true,"height":41},"5":{"cells":{"1":{"text":"年龄","style":7},"2":{"text":"#{hex.customGroup(age)}","style":11}},"isDrag":true,"height":39},"6":{"cells":{"1":{"text":"姓名","style":7},"2":{"text":"#{hex.customGroup(name)}","style":11,"direction":"right"}},"isDrag":true,"height":40},"7":{"cells":{"1":{"text":"薪水","style":7},"2":{"text":"#{hex.customGroup(salary)}","style":11,"direction":"right"}},"isDrag":true,"height":36},"len":100},"name":"sheet1","fillFormStyle":"default","merges":["A2:L2"],"styles":[{"bgcolor":"#9cc2e6"},{"bgcolor":"#9cc2e6","align":"center"},{"bgcolor":"#9cc2e6","align":"center","border":{"bottom":["thin","#5b9cd6"],"top":["thin","#5b9cd6"],"left":["thin","#5b9cd6"],"right":["thin","#5b9cd6"]}},{"border":{"bottom":["thin","#5b9cd6"],"top":["thin","#5b9cd6"],"left":["thin","#5b9cd6"],"right":["thin","#5b9cd6"]}},{"align":"center"},{"align":"center","font":{"bold":true}},{"align":"center","font":{"bold":true,"size":14}},{"bgcolor":"#9cc2e6","align":"center","border":{"bottom":["thin","#5b9cd6"],"top":["thin","#5b9cd6"],"left":["thin","#5b9cd6"],"right":["thin","#5b9cd6"]},"font":{"name":"宋体"}},{"border":{"bottom":["thin","#5b9cd6"],"top":["thin","#5b9cd6"],"left":["thin","#5b9cd6"],"right":["thin","#5b9cd6"]},"font":{"name":"宋体"}},{"align":"center","font":{"bold":true,"size":14,"name":"宋体"}},{"align":"center","font":{"bold":false,"size":14,"name":"宋体"}},{"border":{"bottom":["thin","#5b9cd6"],"top":["thin","#5b9cd6"],"left":["thin","#5b9cd6"],"right":["thin","#5b9cd6"]},"font":{"name":"宋体"},"align":"center"}]}
```

### 关键样式索引

| 索引 | 效果 | 用途 |
|------|------|------|
| 7 | 蓝底(`#9cc2e6`)+居中+蓝边框+宋体 | 标签列 |
| 9 | 居中+加粗14号宋体 | 标题行 |
| 11 | 白底+居中+蓝边框+宋体 | 值列 |
