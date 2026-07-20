# 对象数据集示例

对象数据集：数据集返回单条记录（对象），不勾选"是否分页"和"是否集合"，使用 `${}` 单值绑定语法。

---

## 一、核心规则

### 对象数据集 vs 列表数据集

| 特性 | 对象数据集 | 列表数据集 |
|------|-----------|-----------|
| isList | `"0"` 不勾选 | `"1"` 勾选 |
| isPage | `"0"` 不勾选 | `"1"` 或 `"0"` |
| 绑定语法 | `${dbCode.field}` | `#{dbCode.field}` |
| 数据形态 | 单条记录，直接取值 | 多条记录，循环展开 |
| 典型场景 | 套打、证件、单据、合同 | 明细列表、统计报表 |

### 关键约束

> **对象数据集的 `isList` 和 `isPage` 必须都为 `"0"`。** 因为返回的是单条记录对象，不是列表，不需要分页和集合处理。
>
> **报表设计中使用 `${dbCode.fieldName}` 语法**（注意是 `$` 不是 `#`），每个占位符直接替换为字段值，不会循环展开。
>
> **所有数据集类型（SQL/API/JSON/JavaBean）都支持对象模式**，只需设 `isList: "0"`, `isPage: "0"` 即可。

### 适用场景

| 场景 | 说明 |
|------|------|
| 证件/证书 | 逮捕证、结业证书、资格证 |
| 合同/协议 | 劳动合同、租赁协议 |
| 发票/收据 | 单张发票表头（明细行用 `#{}` 列表绑定） |
| 个人信息表 | 员工档案、学生信息卡 |
| 通知/公文 | 套打模板，填入具体信息 |

---

## 二、完整示例：员工入职劳动合同（JSON 对象数据集）

### 预览布局

```
 ┌─────────────────────────────────────────────┐
 │            员工入职劳动合同                    │  标题 style 1
 │                     合同编号：HT-20260331-001 │  副标题 style 2
 │─────────────────────────────────────────────│
 │ 甲方（用人单位）：${contract.company_name}     │
 │                                             │
 │ 乙方（劳动者）：${contract.emp_name}  性别：${contract.emp_sex}
 │ 身份证号：      ${contract.emp_idcard}        │
 │ 联系电话：      ${contract.emp_phone} 住址：${contract.emp_address}
 │                                             │
 │▌一、工作岗位                                  │  章节标题 style 5
 │ 部门：${contract.department}  职位：${contract.position}
 │                                             │
 │▌二、合同期限                                  │
 │ 合同期限自 ${contract.start_date} 起，至 ${contract.end_date} 止。
 │ 试用期至 ${contract.probation_end} 止         │
 │                                             │
 │▌三、劳动报酬                                  │
 │ 月薪（税前）：${contract.salary} 元           │
 │                                             │
 │▌四、其他条款                                  │
 │ 1. 乙方应遵守甲方的各项规章制度...             │
 │ 2. 甲方应按照国家规定为乙方缴纳社会保险...     │
 │ 3. 本合同一式两份...                          │
 │ 4. 未尽事宜...                               │
 │─────────────────────────────────────────────│
 │ 甲方（盖章）：          乙方（签名）：         │
 │                                             │
 │ 日期：${contract.sign_date}  日期：${contract.sign_date}
 └─────────────────────────────────────────────┘
```

### Step 1: 创建空报表

```python
report_id = gen_id()
# save 空报表 → 获取 report_id
```

### Step 2: 创建 JSON 对象数据集

```python
import json

json_data_content = json.dumps({
    "data": [{
        "company_name": "XX科技有限公司",
        "emp_name": "张三",
        "emp_sex": "男",
        "emp_idcard": "620102199001011234",
        "emp_phone": "13800138000",
        "emp_address": "兰州市城关区XX路XX号",
        "department": "技术部",
        "position": "高级工程师",
        "start_date": "2026-04-01",
        "end_date": "2029-03-31",
        "probation_end": "2026-09-30",
        "salary": "15000",
        "sign_date": "2026-03-31"
    }]
}, ensure_ascii=False)

db_data = {
    "izSharedSource": 0,
    "jimuReportId": report_id,
    "dbCode": "contract",
    "dbChName": "入职合同",
    "dbType": "3",           # JSON 数据集
    "dbSource": "",
    "jsonData": json_data_content,  # 必须 {"data": [...]} 包裹
    "apiConvert": "",
    "isList": "0",           # ← 不勾选"是否集合"（对象模式）
    "isPage": "0",           # ← 不勾选"是否分页"
    "dbDynSql": "",
    "fieldList": [
        {"fieldName": "company_name", "fieldText": "公司名称", "widgetType": "String", "orderNum": 1},
        {"fieldName": "emp_name", "fieldText": "员工姓名", "widgetType": "String", "orderNum": 2},
        {"fieldName": "emp_sex", "fieldText": "性别", "widgetType": "String", "orderNum": 3},
        {"fieldName": "emp_idcard", "fieldText": "身份证号", "widgetType": "String", "orderNum": 4},
        {"fieldName": "emp_phone", "fieldText": "联系电话", "widgetType": "String", "orderNum": 5},
        {"fieldName": "emp_address", "fieldText": "住址", "widgetType": "String", "orderNum": 6},
        {"fieldName": "department", "fieldText": "部门", "widgetType": "String", "orderNum": 7},
        {"fieldName": "position", "fieldText": "职位", "widgetType": "String", "orderNum": 8},
        {"fieldName": "start_date", "fieldText": "合同开始日期", "widgetType": "String", "orderNum": 9},
        {"fieldName": "end_date", "fieldText": "合同结束日期", "widgetType": "String", "orderNum": 10},
        {"fieldName": "probation_end", "fieldText": "试用期截止", "widgetType": "String", "orderNum": 11},
        {"fieldName": "salary", "fieldText": "月薪", "widgetType": "String", "orderNum": 12},
        {"fieldName": "sign_date", "fieldText": "签署日期", "widgetType": "String", "orderNum": 13}
    ],
    "paramList": []
}
api_request('/jmreport/saveDb', db_data)
```

### Step 3: 样式定义

```python
styles = [
    # 0: 无边框居中
    {"align": "center", "valign": "middle"},
    # 1: 大标题 - 加粗20号居中
    {"align": "center", "valign": "middle", "font": {"bold": True, "size": 20}},
    # 2: 副标题/编号 - 右对齐灰色
    {"align": "right", "valign": "middle", "font": {"size": 10}, "color": "#666666"},
    # 3: 标签 - 右对齐加粗
    {"align": "right", "valign": "middle", "font": {"bold": True, "size": 11}},
    # 4: 值 - 左对齐+底线
    {"align": "left", "valign": "middle", "font": {"size": 11},
     "border": {"bottom": ["thin", "#333333"]}},
    # 5: 章节标题 - 蓝底白字
    {"align": "left", "valign": "middle", "font": {"bold": True, "size": 12},
     "bgcolor": "#01b0f1", "color": "#ffffff",
     "border": {"bottom": ["thin", "#01b0f1"], "top": ["thin", "#01b0f1"],
                "left": ["thin", "#01b0f1"], "right": ["thin", "#01b0f1"]}},
    # 6: 正文
    {"align": "left", "valign": "middle", "font": {"size": 11}},
    # 7: 值 - 居中+底线
    {"align": "center", "valign": "middle", "font": {"size": 11},
     "border": {"bottom": ["thin", "#333333"]}},
    # 8: 签章区标签 - 居中加粗
    {"align": "center", "valign": "middle", "font": {"bold": True, "size": 12}},
    # 9: 分隔线
    {"border": {"bottom": ["thin", "#d8d8d8"]}},
    # 10: 条款正文 - 自动换行
    {"align": "left", "valign": "top", "font": {"size": 10}, "textwrap": True},
]
```

### Step 4: 列宽与行数据

```python
cols = {
    "0": {"width": 25},   # A列 左边距
    "1": {"width": 80},   # B列
    "2": {"width": 100},  # C列
    "3": {"width": 80},   # D列
    "4": {"width": 100},  # E列
    "5": {"width": 80},   # F列
    "6": {"width": 100},  # G列
    "7": {"width": 25},   # H列 右边距
    "len": 100
}

rows = {}
merges = []
r = 1  # 当前行号

# Row 1: 空行间距
rows[str(r)] = {"cells": {}, "height": 20}
r += 1

# Row 2: 大标题
rows[str(r)] = {
    "cells": {"1": {"text": "员工入职劳动合同", "style": 1, "merge": [0, 5]}},
    "height": 55
}
merges.append(f"B{r+1}:G{r+1}")
r += 1

# Row 3: 合同编号
rows[str(r)] = {
    "cells": {"1": {"text": "合同编号：HT-20260331-001", "style": 2, "merge": [0, 5]}},
    "height": 25
}
merges.append(f"B{r+1}:G{r+1}")
r += 1

# Row 4: 分隔线
rows[str(r)] = {
    "cells": {"1": {"text": "", "style": 9, "merge": [0, 5]}},
    "height": 10
}
merges.append(f"B{r+1}:G{r+1}")
r += 1

# Row 5: 甲方信息 — ${contract.company_name}
rows[str(r)] = {
    "cells": {
        "1": {"text": "甲方（用人单位）：", "style": 3, "merge": [0, 1]},
        "3": {"text": "${contract.company_name}", "style": 4, "merge": [0, 3]}
    },
    "height": 35
}
merges.append(f"B{r+1}:C{r+1}")
merges.append(f"D{r+1}:G{r+1}")
r += 1

# Row 6: 分隔
rows[str(r)] = {"cells": {}, "height": 10}
r += 1

# Row 7: 乙方姓名+性别 — ${contract.emp_name} + ${contract.emp_sex}
rows[str(r)] = {
    "cells": {
        "1": {"text": "乙方（劳动者）：", "style": 3, "merge": [0, 1]},
        "3": {"text": "${contract.emp_name}", "style": 4, "merge": [0, 0]},
        "4": {"text": "性别：", "style": 3},
        "5": {"text": "${contract.emp_sex}", "style": 4, "merge": [0, 1]}
    },
    "height": 35
}
merges.append(f"B{r+1}:C{r+1}")
merges.append(f"D{r+1}:D{r+1}")
merges.append(f"F{r+1}:G{r+1}")
r += 1

# Row 8: 身份证号 — ${contract.emp_idcard}
rows[str(r)] = {
    "cells": {
        "1": {"text": "身份证号：", "style": 3, "merge": [0, 1]},
        "3": {"text": "${contract.emp_idcard}", "style": 4, "merge": [0, 3]}
    },
    "height": 35
}
merges.append(f"B{r+1}:C{r+1}")
merges.append(f"D{r+1}:G{r+1}")
r += 1

# Row 9: 联系电话+住址 — ${contract.emp_phone} + ${contract.emp_address}
rows[str(r)] = {
    "cells": {
        "1": {"text": "联系电话：", "style": 3, "merge": [0, 1]},
        "3": {"text": "${contract.emp_phone}", "style": 4, "merge": [0, 0]},
        "4": {"text": "住址：", "style": 3},
        "5": {"text": "${contract.emp_address}", "style": 4, "merge": [0, 1]}
    },
    "height": 35
}
merges.append(f"B{r+1}:C{r+1}")
merges.append(f"D{r+1}:D{r+1}")
merges.append(f"F{r+1}:G{r+1}")
r += 1

# Row 10: 分隔
rows[str(r)] = {"cells": {}, "height": 10}
r += 1

# Row 11: 章节一 - 工作岗位（蓝底白字）
rows[str(r)] = {
    "cells": {"1": {"text": "一、工作岗位", "style": 5, "merge": [0, 5]}},
    "height": 32
}
merges.append(f"B{r+1}:G{r+1}")
r += 1

# Row 12: 部门+职位 — ${contract.department} + ${contract.position}
rows[str(r)] = {
    "cells": {
        "1": {"text": "部门：", "style": 3},
        "2": {"text": "${contract.department}", "style": 4, "merge": [0, 1]},
        "4": {"text": "职位：", "style": 3},
        "5": {"text": "${contract.position}", "style": 4, "merge": [0, 1]}
    },
    "height": 35
}
merges.append(f"C{r+1}:D{r+1}")
merges.append(f"F{r+1}:G{r+1}")
r += 1

# Row 13: 分隔
rows[str(r)] = {"cells": {}, "height": 10}
r += 1

# Row 14: 章节二 - 合同期限
rows[str(r)] = {
    "cells": {"1": {"text": "二、合同期限", "style": 5, "merge": [0, 5]}},
    "height": 32
}
merges.append(f"B{r+1}:G{r+1}")
r += 1

# Row 15: 合同起止 — ${contract.start_date} + ${contract.end_date}
rows[str(r)] = {
    "cells": {
        "1": {"text": "合同期限自", "style": 6},
        "2": {"text": "${contract.start_date}", "style": 7},
        "3": {"text": "起，至", "style": 0},
        "4": {"text": "${contract.end_date}", "style": 7},
        "5": {"text": "止。", "style": 6, "merge": [0, 1]}
    },
    "height": 35
}
merges.append(f"F{r+1}:G{r+1}")
r += 1

# Row 16: 试用期 — ${contract.probation_end}
rows[str(r)] = {
    "cells": {
        "1": {"text": "试用期至", "style": 6},
        "2": {"text": "${contract.probation_end}", "style": 7},
        "3": {"text": "止，试用期内双方均可依法解除合同。", "style": 6, "merge": [0, 3]}
    },
    "height": 35
}
merges.append(f"D{r+1}:G{r+1}")
r += 1

# Row 17: 分隔
rows[str(r)] = {"cells": {}, "height": 10}
r += 1

# Row 18: 章节三 - 劳动报酬
rows[str(r)] = {
    "cells": {"1": {"text": "三、劳动报酬", "style": 5, "merge": [0, 5]}},
    "height": 32
}
merges.append(f"B{r+1}:G{r+1}")
r += 1

# Row 19: 月薪 — ${contract.salary}
rows[str(r)] = {
    "cells": {
        "1": {"text": "月薪（税前）：", "style": 3, "merge": [0, 1]},
        "3": {"text": "${contract.salary}", "style": 7},
        "4": {"text": "元，每月15日发放上月工资。", "style": 6, "merge": [0, 2]}
    },
    "height": 35
}
merges.append(f"B{r+1}:C{r+1}")
merges.append(f"E{r+1}:G{r+1}")
r += 1

# Row 20: 分隔
rows[str(r)] = {"cells": {}, "height": 10}
r += 1

# Row 21: 章节四 - 其他条款
rows[str(r)] = {
    "cells": {"1": {"text": "四、其他条款", "style": 5, "merge": [0, 5]}},
    "height": 32
}
merges.append(f"B{r+1}:G{r+1}")
r += 1

# Rows 22-25: 条款正文（固定文本，不绑定数据）
clauses = [
    "1. 乙方应遵守甲方的各项规章制度，按时完成工作任务，保守商业秘密。",
    "2. 甲方应按照国家规定为乙方缴纳社会保险，提供符合国家规定的劳动条件和劳动保护。",
    "3. 本合同一式两份，甲乙双方各执一份，自双方签字（盖章）之日起生效。",
    "4. 未尽事宜，按照《中华人民共和国劳动合同法》及相关法律法规执行。"
]
for clause in clauses:
    rows[str(r)] = {
        "cells": {"1": {"text": clause, "style": 10, "merge": [0, 5]}},
        "height": 30
    }
    merges.append(f"B{r+1}:G{r+1}")
    r += 1

# Row 26: 空行
rows[str(r)] = {"cells": {}, "height": 25}
r += 1

# Row 27: 分隔线
rows[str(r)] = {
    "cells": {"1": {"text": "", "style": 9, "merge": [0, 5]}},
    "height": 5
}
merges.append(f"B{r+1}:G{r+1}")
r += 1

# Row 28: 签章区
rows[str(r)] = {
    "cells": {
        "1": {"text": "甲方（盖章）：", "style": 8, "merge": [0, 1]},
        "4": {"text": "乙方（签名）：", "style": 8, "merge": [0, 2]}
    },
    "height": 35
}
merges.append(f"B{r+1}:C{r+1}")
merges.append(f"E{r+1}:G{r+1}")
r += 1

# Row 29: 签章空白区
rows[str(r)] = {"cells": {}, "height": 60}
r += 1

# Row 30: 签署日期 — ${contract.sign_date}
rows[str(r)] = {
    "cells": {
        "1": {"text": "日期：", "style": 3},
        "2": {"text": "${contract.sign_date}", "style": 7, "merge": [0, 0]},
        "4": {"text": "日期：", "style": 3},
        "5": {"text": "${contract.sign_date}", "style": 7, "merge": [0, 1]}
    },
    "height": 30
}
merges.append(f"C{r+1}:C{r+1}")
merges.append(f"F{r+1}:G{r+1}")
r += 1

rows["len"] = 200
```

### 设计要点

**对象数据集布局特点：**
- 标签+值 成对出现（如 `"甲方：" + "${contract.company_name}"`）
- 值字段用底线样式（style 4/7）模拟手写填写效果
- 章节标题用蓝底白字（style 5）区分层级
- 固定文本（条款内容）不绑定数据，直接写死
- 签章区留空白行（height: 60）供盖章/签名

**合并单元格技巧：**
- 标签占 2 列（merge [0,1]），值占 4 列（merge [0,3]）→ 整行 6 列对齐
- 左右两组并列时：标签 1 列 + 值 2 列 | 标签 1 列 + 值 2 列
- 标题和章节标题合并整行（merge [0,5]）

---

## 三、SQL 对象数据集示例（逮捕证）

SQL 数据集也可以用对象模式，参考报表：https://api.jimureport.com/jmreport/index/1198894185512783872

```python
sql = """select pname, fname, fsex, cdata, shiqing, zhuzhi, gdata
from pdaibu where id='${id}'"""

db_data = {
    "jimuReportId": report_id,
    "dbCode": "pdaibu",
    "dbChName": "逮捕信息",
    "dbType": "0",           # SQL 数据集
    "dbSource": "",
    "isList": "0",           # ← 对象模式
    "isPage": "0",           # ← 不分页
    "dbDynSql": sql,
    "fieldList": [
        {"fieldName": "pname", "fieldText": "批准机关", "widgetType": "String", "orderNum": 1},
        {"fieldName": "fname", "fieldText": "姓名", "widgetType": "String", "orderNum": 2},
        {"fieldName": "fsex", "fieldText": "性别", "widgetType": "String", "orderNum": 3},
        {"fieldName": "cdata", "fieldText": "出生日期", "widgetType": "String", "orderNum": 4},
        {"fieldName": "shiqing", "fieldText": "犯罪事实", "widgetType": "String", "orderNum": 5},
        {"fieldName": "zhuzhi", "fieldText": "住址", "widgetType": "String", "orderNum": 6},
        {"fieldName": "gdata", "fieldText": "日期", "widgetType": "String", "orderNum": 7}
    ],
    "paramList": [
        {"paramName": "id", "paramTxt": "ID", "paramValue": "",
         "widgetType": "String", "orderNum": 1, "searchFlag": 1, "searchMode": 1}
    ]
}
api_request('/jmreport/saveDb', db_data)
```

报表中使用 `${}` 绑定：
```
经 ${pdaibu.pname} 批准，决定逮捕犯罪嫌疑人：
姓名：${pdaibu.fname}    性别：${pdaibu.fsex}
出生日期：${pdaibu.cdata}
住址：${pdaibu.zhuzhi}
涉嫌犯罪事实：${pdaibu.shiqing}
日期：${pdaibu.gdata}
```

URL 传参切换记录：
```
/jmreport/view/{report_id}?token=xxx&id=1
/jmreport/view/{report_id}?token=xxx&id=2
```

---

## 四、与主子表的结合

主子表报表中，**主表通常用对象数据集 `${}`，子表用列表数据集 `#{}`**：

```python
# 主表 — 对象数据集
main_db = {
    "dbCode": "orderMain",
    "isList": "0",       # 不勾选集合
    "isPage": "0",       # 不勾选分页
    ...
}

# 子表 — 列表数据集
sub_db = {
    "dbCode": "orderSub",
    "isList": "1",       # 勾选集合
    "isPage": "0",       # 子表不分页
    ...
}
```

报表设计中：
```
订单编号：${orderMain.order_no}      日期：${orderMain.order_date}
客户姓名：${orderMain.customer_name}  电话：${orderMain.customer_phone}

| 商品名称              | 单价             | 数量          | 小计             |
| #{orderSub.product_name} | #{orderSub.price} | #{orderSub.qty} | #{orderSub.subtotal} |
```

详见 `examples/master-sub-table.md`。
