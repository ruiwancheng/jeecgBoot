# JeecgBoot Online 图表 AI 自动生成 — Skills 使用指南

> 通过 Claude Code 以自然语言描述图表需求，AI 自动生成 SQL、推导 X/Y 轴字段、配置图表类型，并调用 API 在 JeecgBoot 系统中创建/编辑 Online 图表。
> 无需手动写 SQL 或逐一配置字段，AI 从需求描述到可预览图表一步到位。

## 与传统方式的区别

- **无需手写 SQL**：描述业务需求，AI 自动推导 SQL 语句和字段配置
- **智能推导 X/Y 轴**：AI 根据 SQL 字段语义自动识别维度字段（X 轴）和度量字段（Y 轴）
- **自动选择图表类型**：根据数据特征推荐最适合的图表类型（柱状图、折线图、饼图等）
- **字段中文名翻译**：自动将 SQL 字段名翻译为中文显示名称
- **字典自动匹配**：识别常见字段（如 sex、status）并关联系统字典

---

## 前置准备

使用前需准备两样东西：

| 信息 | 获取方式 | 示例 |
|------|---------|------|
| **后端地址** | 运维/开发提供 | `https://boot3.jeecg.com/jeecgboot` |
| **X-Access-Token** | 浏览器 F12 → Network → 任意请求 Headers | `eyJhbGciOiJIUzI1NiJ9...` |

---

## 触发方式

在 Claude Code 对话中，用自然语言描述你要创建的图表，包含以下任意关键词即可自动触发：

```
创建图表 / 生成图表 / 新建图表 / 做一个图表 / online图表 / 数据图表
柱状图 / 折线图 / 饼图 / 统计图 / 可视化 / chart / graph
```

---

## 实战案例：用户性别统计图表

以下是一个完整的图表创建过程，展示了 skill 的实际使用方式。

### 第一步：描述需求

**用户输入：**
```
创建一个柱状图，统计系统用户的男女比例
```

**AI 交互过程：**

1. AI 询问后端地址和 Token
2. 用户提供凭据后，AI 自动推导 SQL 和字段配置，展示摘要：

```
## Online 图表配置摘要

- 图表编码：tj_user_sex
- 图表名称：统计男女比例
- 图表类型：bar（柱状图）
- X 轴字段：sex（性别）
- Y 轴字段：cout（人数）
- 数据源：默认
- 目标环境：https://boot3.jeecg.com/jeecgboot

### SQL 语句
select count(*) cout, sex from sys_user group by sex

### 字段配置

| 序号 | 字段名 | 显示名称 | 类型 | 显示 | 查询 | 字典 | 合计 |
|------|--------|---------|------|------|------|------|------|
| 0 | cout | 人数 | String | Y | N | - | Y |
| 1 | sex | 性别 | String | Y | N | sex | N |

确认以上配置？(y/n)
```

3. 用户确认 `y` 后，AI 自动调用 API 创建图表
4. 返回结果：

```
## Online 图表创建成功

- 图表编码：tj_user_sex
- 图表名称：统计男女比例
- 图表类型：bar（柱状图）

### 后续操作
1. 打开 JeecgBoot 后台 → Online图表
2. 找到该图表，点击「功能测试」预览效果
```

---

### 第二步：修改图表类型

**用户输入：**
```
把刚才的图表改成折线+柱状组合图
```

**AI 交互过程：**

1. AI 基于已有图表信息，展示修改摘要（标注变更项）：

```
### 变更内容
- 图表类型：bar → line,bar（组合图表）
- 新增标记：isCombination = combination
```

2. 用户确认后，AI 调用 edit API 更新图表

---

## 示例用法

### 1. 一句话描述（最简方式）

```
做一个柱状图，统计各部门的人数
```

AI 会自动推导 SQL：`select count(*) cnt, depart_name from sys_depart group by depart_name`

### 2. 指定图表类型

```
用饼图展示系统用户的性别分布
```

AI 识别 "饼图" → `graphType: "pie"`

### 3. 指定 SQL

```
创建图表，SQL：select DATE_FORMAT(create_time,'%Y-%m') month, count(*) cnt from sys_user group by month
用折线图展示
```

### 4. 组合图表

```
做一个月度销售分析，同时显示折线图和柱状图
```

AI 自动设置 `graphType: "line,bar"` + `isCombination: "combination"`

### 5. 带查询参数的图表

```
创建一个柱状图统计各部门人数，支持按状态筛选
```

AI 生成带 Velocity 参数的 SQL：
```sql
select count(*) cnt, dept from sys_user
where 1=1
${#if($status != '')} AND status = '$status' ${#end}
group by dept
```

### 6. 指定数据源

```
用 second_db 数据源做一个销售统计图表
```

AI 设置 `dbSource: "second_db"`

---

## 支持的图表类型

| 图表类型 | graphType 值 | 适用场景 |
|---------|-------------|---------|
| 柱状图 | `bar` | 分类对比（如男女人数、部门对比） |
| 折线图 | `line` | 趋势变化（如月度销售、访问量趋势） |
| 饼图 | `pie` | 占比分布（如部门比例、状态分布） |
| 组合图表 | `line,bar` | 趋势+对比（同时展示折线和柱状） |

AI 会根据数据特征自动推荐最合适的图表类型：
- 分类对比场景 → 柱状图
- 时间趋势场景 → 折线图
- 占比分布场景 → 饼图
- 多维分析场景 → 组合图表

---

## 智能字段推导

AI 根据 SQL 字段语义自动推导配置：

### X/Y 轴推导

| 字段特征 | 推导为 |
|---------|--------|
| 分类/维度字段（sex、dept、month、category） | X 轴 |
| 度量/聚合字段（count、sum、avg 的结果） | Y 轴 |

### 字段中文名翻译

| 字段名 | 自动翻译 |
|--------|---------|
| count / cout / cnt | 数量/人数 |
| sum / total / amount | 合计/总额 |
| avg / average | 平均值 |
| sex | 性别 |
| dept / department | 部门 |
| month / year / date | 月份/年份/日期 |

### 字典自动关联

| 字段名 | 关联字典 |
|--------|---------|
| sex | `sex`（性别） |
| status | `valid_status`（有效状态） |
| priority | `priority`（优先级） |

---

## 修改已有图表

如果要修改已创建的图表：

```
修改图表 tj_user_sex，把图表类型改成饼图
```

```
给图表 tj_user_sex 的 Y 轴加上标签文字"人数（单位：人）"
```

需要提供图表 ID 或编码。AI 会先查询现有配置，再进行修改。

---

## 高级功能

### Y 轴标签

```
创建图表并设置 Y 轴标签为"销售额（万元）"
```

### 扩展 JS

通过自定义 JS 扩展图表行为，适合高级用户：

```
创建图表，加一段扩展 JS：option.tooltip = {trigger: 'axis'};
```

### 动态数据源

查询非默认数据源的数据：

```
用 report_db 数据源创建统计图表
```

---

## 与其他 Skill 的区别

| Skill | 产出物 | 适用场景 |
|-------|--------|---------|
| **jeecg-onlchart** | Online 图表配置（SQL 驱动，数据可视化） | 柱状图、折线图、饼图等数据可视化 |
| jeecg-onlreport | Online 报表配置（SQL 驱动，数据列表） | 数据查询报表、统计列表 |
| jeecg-onlform | Online 表单配置（元数据驱动，CRUD） | 数据录入管理表单 |
| jeecg-codegen | Java + Vue3 代码 + SQL | 需要自定义业务逻辑的模块 |
| jeecg-desform | 设计器表单 JSON | 数据采集、审批表单 |
| jeecg-bpmn | Flowable BPMN 2.0 XML | 审批流程、工作流 |

**选择建议：**
- 需要数据可视化（图表） → **jeecg-onlchart**
- 需要数据查询列表 → jeecg-onlreport
- 需要简单 CRUD 表单 → jeecg-onlform
- 需要自定义业务逻辑 → jeecg-codegen
- 需要数据采集/审批表单 → jeecg-desform
- 需要审批流程 → jeecg-bpmn

---

## 注意事项

1. **Token 有效期**：JWT Token 有过期时间，过期后需重新从浏览器获取
2. **图表编码唯一**：同一系统中 code 不能重复，如已存在需改名或使用编辑功能
3. **SQL 安全**：不要在 SQL 中使用 DROP/DELETE/UPDATE 等危险语句
4. **同一会话内可连续修改**：AI 会记住当前图表的 ID 和编码，无需重复提供
5. **创建后可在后台微调**：AI 创建的图表可以在 Online 图表编辑页面中继续调整
6. **菜单配置可选**：创建成功后 AI 会提供菜单 SQL，可选择执行或手动添加
