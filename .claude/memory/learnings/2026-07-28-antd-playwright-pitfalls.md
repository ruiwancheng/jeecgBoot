# Ant Design Vue + Playwright 六大选择器坑

**场景**：JeecgBoot 前端 E2E 编写（BasicDrawer + BasicForm + a-select + a-modal）。

1. **抽屉 vs 背后搜索区**：列表页搜索表单和抽屉表单都有同名 select（如"入库类型"），全局 locator 会命中背后被遮罩的元素 → "intercepts pointer events"。**必须作用域限定** `.ant-drawer:has-text("标题")` 再操作。
2. **ant select 点击目标**：点 `.ant-select-selector`（不是 `.ant-select` 根 div 也不是 `.ant-select-selection-wrap`——此版本无此 class）；选项点击用 `.ant-select-item-option`，且下拉有动画需 `waitForTimeout(400)` + 必要时 `force: true`。
3. **字典下拉首项是"全部"（空值）**：点 first 会显示回显但表单值为空 → 提交时校验报"请选择XX"。用 `.nth(1)`。
4. **按钮两汉字间有空格**：ant 自动给两汉字按钮加空格（"确 认"/"搜 索"），`has-text("确认")` 匹配不到，用 `getByRole('button', { name: '确 认' })`。
5. **单选/多选组件不同**：MaterialSelectModal single 模式是 radio，multiple 模式是 checkbox——写选择器前先看 mode。
6. **抽屉默认带空明细行**：OtherInDrawer 初始化就有一行，再"添加行"会产生空行导致静默保存失败（无 toast 无落库）。**保存结果别信 toast，用 API 查落库**（`list?code=xxx` 断言 + totalAmount）。
7. **`has-text` 子串误匹配**：`button:has-text("审核")` 会同时命中"反审核"，断言按钮状态时误报。用 `getByRole('button', { name: '审 核', exact: true })`（注意 ant 两汉字间空格）。实证：Gallery 状态守卫验证，粗选择器报假失败，精确选择器证实控件正常。
8. **`innerText` 不含 input 的值**：表格单元格里 InputNumber 的当前值不会出现在 innerText 中（看到的是空白）。读输入值必须 `locator('input').inputValue()`，列定位用 `td.nth(N)` 比全局 `input.nth(N)` 可靠（物料只读输入框会占位）。

**复用**：`harness/e2e/mes/other-stock-in.spec.ts` 是完整范例。
