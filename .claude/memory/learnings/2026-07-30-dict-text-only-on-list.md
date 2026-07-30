# @Dict 注解字段的 _dictText 只在 list 接口返回，queryById 不返回

**场景**：前端 Drawer 编辑模式读取 `@Dict` 字段做关联展示（如"由订单 SO-xxx 创建"），以为 `queryById` 也会带出 `_dictText`，结果后端只返回 ID，`_dictText` 是 None/缺失。

**根因**：
- JeecgBoot 平台的 `DictAspect` 字典填充切面只对 `*Controller.list` 这类分页查询生效
- 自定义 `*Service.queryWithItems`（含 `selectById` + 关联子查询）走 MyBatis Plus 直接 mapper，绕过了切面
- 实测对比：list 接口 `salesOrderId_dictText="VERIFY-SO-20260730-001"`，queryById 接口 `salesOrderId_dictText=None`

**正确处理**：

```typescript
// 前端响应式文案 fallback（Claude 评审曾误判 queryById 也带 _dictText，必须实测验证）
const orderRef = delivery.salesOrderId_dictText || delivery.salesOrderId;
if (orderRef) {
  alertText.value = `由订单 ${orderRef} 创建。出库后订单自动置已发货。`;
}
```

**判断信号**：
- Claude 评审（自动化）声称"@Dict 让 queryById 自动带出 _dictText" → 写代码后实测 None → 必须 fallback
- list 接口返回的字段名带后缀 `_dictText` 是字典切面产物，queryById 默认不挂切面

**实证**：2026-07-30 销售链路黄金模板对齐，DeliveryDrawer.vue + OutboundDrawer.vue 各加一行 fallback。实跑测试数据 VERIFY-SO/VERIFY-DN 验证 fallback 生效。

**避免**：不要相信"@Dict 自动带"的说法，所有响应式关联文案必须实测 list 和 queryById 两个接口。