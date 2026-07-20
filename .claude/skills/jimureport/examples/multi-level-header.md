# 多级循环表头示例（横向纵向组合分组）— 索引

> **此文件已拆分为3个较小文件，请直接读取对应子文件，不要读本文件：**

| 文件 | 内容 | 场景关键词 |
|------|------|----------|
| `multi-level-header-basic.md` | 示例1-3（基础多级表头） | 二级表头、纵横组合、纯横向 |
| `multi-level-header-advanced.md` | 示例4-5（交叉报表+区域销售） | 学生成绩交叉、compute小计、列标题循环 |
| `multi-level-header-api.md` | 特殊规则 + 示例6（API数据集）+ 踩坑 | API数据集交叉表、gen_id优化、常见踩坑 |

**类型：** 多级循环表头（交叉表）
**特征：** `groupRight()` 横向展开表头 + `dynamic()` 填充数据 + `group()` 纵向分组
**参考文档：** https://help.jimureport.com/group/directionDynamic

## 场景匹配速查

| 需求 | 读哪个文件 |
|------|----------|
| 二级横向表头（年+月双层） | `multi-level-header-basic.md` 示例1 |
| 区域+省份纵向 + 月份横向（多动态值） | `multi-level-header-basic.md` 示例2 |
| 纯横向多级展开 | `multi-level-header-basic.md` 示例3 |
| 简单交叉报表（1层横向 + 2层纵向） | `multi-level-header-advanced.md` 示例4 |
| 横向分组 + 列标题循环 + compute小计 | `multi-level-header-advanced.md` 示例5 |
| **API数据集交叉报表（gen_id 2步法）** | `multi-level-header-api.md` 示例6 |
| 交叉报表踩坑（aggregate/direction/merges等） | `multi-level-header-api.md` 踩坑章节 |
