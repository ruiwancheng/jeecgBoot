# 外部评审报告 — 采购申请金额确认弹窗

**日期**: 2026-07-24
**评审阶段**: plan（实施计划评审）
**评审视角**: 架构/实施可行性
**评审方式**: 降级模式（Orca dispatch 不可用，手工评审笔记）

---

## 评审结论

方案方向正确，但 `Modal.confirm` 的异步时序处理需要精确设计——confirmLoading 的设置时机直接决定用户体验和按钮状态一致性。有一个关键遗漏：编辑场景下也应触发确认。

---

## ✅ 思路对齐

1. **computed totalAmount 设计合理** — 用 computed 自动响应 items 变化，无需手动维护，符合 Vue 响应式最佳实践
2. **阈值判断位置正确** — validate 之后、save 之前，保证表单校验先通过再弹窗，避免用户确认后又发现校验失败
3. **Modal.confirm 选择正确** — 比 Modal.error/warning 更合适，确认/取消双按钮语义清晰
4. **影响面极小** — 仅一个文件，不涉及后端、路由、API

---

## ⚠️ 遗漏或风险

### 1. confirmLoading 时序问题（关键）

当前代码 `setDrawerProps({ confirmLoading: true })` 在 validate 之后立即执行。如果 totalAmount > 10000：
- loading 已经设为 true，弹窗出现时 Drawer 的 OK 按钮已在转圈
- 用户点"取消" → loading 在 finally 中被置 false → 但弹窗期间的 loading 是误导性的

**正确时序**：先判断金额 → 弹窗 → 用户确认 → 再设 loading。

### 2. 编辑场景遗漏

编辑已有申请时，如果之前的金额已超 10000，再次编辑后提交也应触发确认。当前方案只在 `handleSubmit` 中判断 totalAmount，天然覆盖编辑场景——这一点实际是正确的，但需求描述中未明确说明。**结论：代码无遗漏，需求文档可补充说明**。

### 3. Modal.confirm 默认 onCancel 行为

`Modal.confirm` 返回 Promise。用户点取消时 Promise reject（或 resolve 为 false，取决于 ant-design-vue 版本）。需要 try/catch 或 `.then/.catch` 处理取消分支，避免未捕获的 rejection。

Ant Design Vue 4.x 中 `Modal.confirm` 的行为：
- 点确定 → `Promise.resolve()`
- 点取消 → `Promise.reject()` （注意：是 reject，不是 resolve(false)）

**如果直接用 await 且不 try/catch，点取消会导致未捕获的 Promise rejection。**

### 4. items 为空数组的边界

如果用户删光了所有行（虽然 `removeLine` 限制至少 1 行），totalAmount 为 0，不触发确认——行为正确。

---

## 💡 优化建议

### 1. 金额格式化显示

弹窗中可显示具体金额，增强用户决策信息量：
```
`申请总金额为 ¥${totalAmount.value.toFixed(2)}，金额较大，确认提交吗？`
```

### 2. 确认后行为一致

确认后走原有 save 流程（loading → save → close → emit success），与不超阈值路径完全一致，仅多一步确认——设计上优雅。

### 3. 推荐实现伪代码

```typescript
async function handleSubmit() {
  const values = await validate();
  
  // 金额确认
  if (totalAmount.value > 10000) {
    try {
      await Modal.confirm({
        title: '申请金额较大',
        content: `申请总金额为 ¥${totalAmount.value.toFixed(2)}，确认提交吗？`,
      });
    } catch {
      return; // 用户取消，直接返回（不设 loading）
    }
  }
  
  // 确认后或金额未超阈值：正常提交
  setDrawerProps({ confirmLoading: true });
  try {
    await saveOrUpdateApply({ ...values, items: items.value }, unref(isUpdate));
    closeDrawer();
    emit('success');
  } finally {
    setDrawerProps({ confirmLoading: false });
  }
}
```

关键点：
- confirmLoading 移到弹窗确认**之后**
- Modal.confirm 的 reject 用 try/catch 捕获，用户取消直接 return
- 不超阈值路径完全不变

---

## 评审人

Claude Code（外部评审降级模式 — Orca dispatch 不可用）

*评审完成时间: 2026-07-24*
