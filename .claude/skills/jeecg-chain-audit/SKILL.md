---
name: jeecg-chain-audit
description: "铁拳团第11视角——端到端链路贯通审计。追踪业务流程从头到尾是否走得通，填补模块审计的跨模块盲区。触发条件：变更涉及 business-chains.json 中任意链路 ≥2 个模块。"
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [jeecg, tiequan, audit, chain, integration, mes]
    related_skills: [jeecg-tiequan-audit, quality-gate]
---

# 链路审计 — 铁拳团第11视角

## Overview

链路审计是铁拳团的第 11 个视角——**链路人1号：端到端链路贯通视角**。

与 10 人模块审计不同，链路审计不读 Service 实现细节，而是站在业务流程的视角追踪"数据能不能从头走到尾"。

**核心问题**：模块审计看"房间里有没有问题"，链路审计看"门和门之间能不能走过去"。两者互补——模块全部 PASS 不等于链路通。

## When to Use

**自动触发**（deploy-quality-gate.md 中定义）：
- 变更涉及 `business-chains.json` 中任意链路的 ≥2 个模块
- 在模块审计完成之后执行
- 作为部署质量门控的一部分

**手动触发**：
- 用户说"检查采购链路是否通畅"、"验证申请→订单→入库的流程"
- 新增跨模块功能后

## When NOT to Use

- 单模块变更（不需要链路视角）
- 纯前端样式/文案变更
- 不涉及业务链路的独立模块（如基础数据）

## Role Definition

```
链路人1号 — 端到端链路贯通视角

不是产品/研发/测试任一梯队，是独立于三梯队之外的"架构集成"角色。

核心任务: 追踪业务流程从头到尾是否走得通
不看什么: Service 内部的 if-else 分支、for 循环体、数值计算细节
要看什么: Controller 方法签名 + 参数/返回类型 + 注解、DTO 字段映射、Entity 状态字段、Mapper 方法签名、跨模块调用链
```

## 7 个检查维度

### 维度1：状态机衔接

检查上游模块的终态是否在下游模块有对应的准入校验。

**方法**：
- 读取上游 Entity 的 status 字段 + `@Dict` 注解 → 获取状态字典
- 读取下游 Service 中"创建/关联上游单据"的方法 → 检查是否校验了上游 status
- 对比：上游能走到哪些终态 vs 下游接受哪些状态作为输入

**示例**：
```
申请.status 终态 = '2'(已审核) 
订单.create 是否校验了"仅已审核申请可生成订单"？
→ 未校验 → 断点！
```

### 维度2：接口衔接

检查每个模块是否暴露了"下一步"所需的 API。

**方法**：
- 列出链路上游模块的 Controller 所有 `@PostMapping/@PutMapping` 端点
- 与下游模块需要"上游提供的"数据比对
- 标注缺失的端点

**示例**：
```
订单→入库需要: "根据订单ID加载可入库明细"的接口
订单 Controller 有: /loadOrderItemsForReceipt ✅
申请→订单需要: "根据已审核申请生成订单"的接口
申请 Controller 有: 无 ❌ 断点！
```

### 维度3：数据契约

检查上下游模块之间传递的数据字段是否完整匹配。

**方法**：
- 读取 DTO 类的字段名+类型（链路上游返回的数据结构）
- 读取下游 Entity 的字段名+类型（下游接收的数据结构）
- 比对字段映射：DTO 是否有下游需要的所有字段？类型是否兼容？

**示例**：
```
DTO MesPurchaseOrderItemForReceipt:
  materialCode ✅声明 / materialName ✅声明
Service 构建 DTO 时:
  .setMaterialId(...) ✅ / materialCode ❌未赋值 / materialName ❌未赋值
→ 字段存在但从未赋值，前端显示空白 → 契约不匹配
```

### 维度4：逆向流程 & 回滚

检查中间环节失败时，前面环节能否回滚。

**方法**：
- 识别链路中"有副作用"的操作（写库存、生成应付、改状态）
- 检查下游失败时是否有对应的补偿/回滚端点
- 标注"无回滚"的单向操作

**示例**：
```
入库审核: atomicReceive(扣减可收数) + stockIn(加库存) + payable.save(生成应付)
如果 stockIn 成功但 payable.save 失败:
  → atomicReceive 已扣减（在审核事务内）
  → 库存已加（在同一事务内）  
  → 应付未生成 → 有货无账
  → 需要: 事务回滚机制 or 补偿端点 → @Transactional 是否覆盖全部？
```

### 维度5：跨模块事务边界

检查一个操作涉及多张不同模块的表时，事务边界是否正确。

**方法**：
- 从上游 Service 的写方法出发，追踪所有 `@Autowired` 的下游 Service 调用
- 检查 `@Transactional` 注解位置和 `rollbackFor` 参数
- 检查下游 Mapper 是否使用了 `FOR UPDATE` 行锁

**示例**：
```
MesPurchaseReceiptServiceImpl.audit() {
  @Transactional ← 事务边界在这里
  purchaseOrderItemMapper.atomicReceive() → 订单模块表
  inventoryService.stockIn()              → 基础模块表
  payableService.save()                   → 财务模块表
}
→ 4 张表在同一个 @Transactional 内 ✅
→ 但 stockIn() 和 payableService.save() 是否自己开了新事务？
  （需要检查其 Service 上的 @Transactional(propagation=...)）
```

### 维度6：字典/常量一致性

检查不同模块中对同一概念使用的字典值是否语义一致。

**方法**：
- 读取链路中每个 Entity 的 `@Dict(dicCode="...")` 注解
- 对比同一语义在不同模块中的字典编码和取值
- 标注潜在的语义冲突

**示例**：
```
申请.status: @Dict(dicCode="mes_purchase_apply_status")
订单.status: @Dict(dicCode="mes_purchase_order_status")
入库.status: @Dict(dicCode="mes_purchase_receipt_status")

→ 三个不同字典！值 '1' 在申请/订单/入库中各代表什么意思？
→ 订单入库校验: if (order.status == '3' || order.status == '4') ← 硬编码！
→ 如果申请的 '2'=已审核，但订单的 '2'=待审核 → 跨模块传递时语义错位
```

### 维度7：权限衔接

检查上游写入的数据在下游是否有对等的读取权限。

**方法**：
- 读取链路上每个 Controller 的 `@RequiresPermissions` 注解值
- 比对相邻模块的权限粒度
- 检查是否有"上游能写但下游不能读"的权限缺口

**示例**：
```
采购员: mes:purchaseApply:add (能创建申请)
        mes:purchaseApply:list (能看申请列表)
但:      mes:purchaseOrder:list 只授权给采购经理
→ 采购员看不到自己申请生成的下游订单 → 业务流程断裂
```

## 读代码边界（关键规则）

链路审计遵循严格的"接口表面层"读法：

| 要读的 | 不读的 | 
|--------|--------|
| Controller 类上的 `@RequestMapping` + 方法上的 `@PostMapping/@GetMapping` + 参数类型 | Controller 方法内部逻辑 |
| Entity 字段名 + 类型 + `@Dict` 注解 | Entity 的 getter/setter 实现 |
| DTO 字段名 + 类型 | DTO 的赋值/转换逻辑 |
| Service 方法签名 + `@Transactional` 注解 | Service 方法体的 if-else/for 循环 |
| Mapper 方法签名 + `@Select/@Update` SQL 关键词 | Mapper XML 的完整 SQL（除非有关键词） |
| `@RequiresPermissions` 注解值 | Shiro 配置类 |

**降级兜底**：当接口表面层信息不足以判定时（如图谱查询结果矛盾），可以 Read 具体代码行进行二次确认，但必须在报告中标注 `[来源: read文件确认]`。

## 执行流程

```
Step 1: 从 business-chains.json 读取链路定义
        → 得到模块列表 + 流转顺序 + 已有 health 状态

Step 2: 加载接口表面层信息（3种方式，按可靠性排序）
        a) code-review-graph MCP 工具（最快）
           query_graph_tool → Controller 端点签名
           get_impact_radius_tool → 跨模块调用关系
        b) 直接 Read Controller 文件的方法签名行（兜底）
        c) grep 搜索关键注解（极端兜底）

Step 3: 按 7 个维度逐项检查
        每个维度产生: ✅ 通 / ⚠️ 隐患 / ❌ 断点

Step 4: 输出报告 → 标注每个发现的置信度 + 建议修复位置

Step 5: 回写 business-chains.json 的 health 字段
```

## 报告模板

输出文件：`hermes/tiequan/{YYYY-MM-DD}/{链路的第一个模块}-chain/13_链路审计报告.md`

```markdown
# 链路审计报告 — {链路名}

**审计日期:** YYYY-MM-DD
**审计人:** 链路人1号（端到端链路贯通视角）
**触发原因:** {模块1}、{模块2} 变更涉及本链路

## 链路状态: 🟢 贯通 / 🟡 有隐患 / 🔴 断裂

{流程图: 模块A ──状态──→ 模块B ──状态──→ 模块C}

## 7 维检查结果

| 维度 | 状态 | 发现 |
|------|:--:|------|
| 1.状态机衔接 | 🔴 | ... |
| 2.接口衔接 | 🟢 | ... |
| ... | ... | ... |

## ❌ 断点详情

### 断点 1: {描述}
- 位置: {上游模块} → {下游模块}
- 根因: ...
- 建议修复位置: {A模块 / B模块 / 两个都要修}
- 理由: ...
- 置信度: [来源: Controller签名 / read文件确认 / 图谱traverse]

## ⚠️ 隐患清单
...

## ✅ 通畅环节
...

## 建议修复优先级
1. P0: ...
2. P1: ...
```

## 置信度标注规则

每条发现必须标注信息来源：

| 标注 | 置信度 | 适用场景 |
|------|:--:|------|
| `[来源: Controller签名]` | 高 | 直接从方法签名/注解判定 |
| `[来源: read文件确认]` | 高 | 图谱信息不足时手动 read 确认 |
| `[来源: 图谱traverse]` | 中 | 依赖 code-review-graph 的调用链分析（需确认图谱最新） |
| `[来源: 推断]` | 低 | 基于命名约定或模式的推断，未经代码确认 |

## 冲突解决规则（与模块审计的关系）

当链路审计发现与模块审计结论不一致时：

| 场景 | 以哪个为准 | 规则 |
|------|:--:|------|
| 链路审计发现跨模块衔接问题 | **链路审计** | 模块审计没有跨模块视角，其"无问题"判定不适用于跨模块场景 |
| 链路审计发现单模块代码问题 | **模块审计** | 模块审计读了完整代码，链路审计只读了接口表面层 |
| 两者对同一代码段严重度不一致 | **取高者** | 不同视角基于不同影响面假设，链路视角通常能看到更大影响面 |
| 无法判定谁对 | **标记"需人工复核"** | 不自动合并，保留双方原始结论 |

## 与 deploy-quality-gate 的集成

链路审计结果通过 `business-chains.json` 的 `health` 字段回写：

```json
"采购链路": {
  "health": {
    "lastAudit": "2026-07-22",
    "status": "broken",
    "openGaps": [
      "申请无审核端点→申请→订单不通",
      "入库DTO缺少materialCode/materialName"
    ]
  }
}
```

deploy-quality-gate 在下次部署时读取 `health.status`：
- `broken` → 自动提醒"链路上次审计发现断点未修复"
- `degraded` → 提醒有隐患
- `healthy` → 无提醒

**注意：** health 状态不阻塞部署（影子模式），仅提醒。正式模式下由 deploy-quality-gate 的 `failureStrategy` 决定是否阻断。

## Verification Checklist

- [ ] 已从 business-chains.json 读取链路定义
- [ ] 已加载各模块的 Controller 方法签名
- [ ] 7 个维度逐项检查完成
- [ ] 每个发现标注了置信度来源
- [ ] 断点标注了"建议修复位置"
- [ ] 报告已写入 hermes/tiequan/{日期}/{模块}-chain/13_链路审计报告.md
- [ ] health 字段已回写 business-chains.json
- [ ] 未修改任何业务代码
