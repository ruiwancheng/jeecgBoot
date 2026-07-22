# [2026-07-21] [前端] JeecgBoot 单据自动编码接线模式（Drawer + 编码规则）

## 触发条件
新单据页面需要"打开新增弹窗时自动带出业务编号"。

## 标准做法（已在 10 个单据页验证）

1. **统一映射点**：`views/project/{项目}/basic/codeRule/bizCodeMap.ts` 定义 `MES_BIZ_CODE` 常量（单据→规则编码），禁止页面硬编码 `'SO'` 这类字符串
2. **Drawer 接线**（useDrawerInner 内，isUpdate 判断之后）：
```ts
if (!unref(isUpdate)) {
  try {
    const nextCode = await getNextCode(MES_BIZ_CODE.XXX);
    if (nextCode) await setFieldsValue({ code: nextCode });
  } catch (e) { /* 取号失败静默回退手工输入，不阻塞开单 */ }
}
```
3. **配套必备**：数据库补规则（INSERT IGNORE 固定 id）+ 字典 `mes_code_biz_type` + 规则实体 `@Dict` 注解（列表才能显示中文）

## 已知行为（设计取舍，勿当 bug 改）
- 打开弹窗即占用号码，取消不归还 → 单号允许跳号
- 取号失败（规则未配）→ 用户手工输入，后端业务表唯一约束兜底

**关联：** 2026-07-21 编码规则绑定任务（9 个 Drawer 统一接线）
## 关联
- ✅ 已覆盖: frontend.md Drawer自动编码接线
