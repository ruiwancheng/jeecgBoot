# MES System 模块回归测试报告

**日期**：2026-08-04
**模块**：system（全局开关）+ codeRule（编码规则）
**Controller 数**：2
**测试类型**：API + E2E

## 一、测试概况

| 指标 | 数值 |
|---|---:|
| API 测试用例（globalSwitch + codeRule）| 35 |
| 通过 | 33 |
| 失败 | 2 |
| 失败率 | 5.7% |
| E2E 测试 | 1/1 通过（commonSetting.spec.ts 失败）|

## 二、MesGlobalSwitchController 端点覆盖

| 端点 | HTTP | 测试结果 |
|---|---|:-:|
| /list | GET | ✅ 通过 |
| /save | POST | ⚠️ 见 P1 |
| /closeCheck | GET | ✅ 通过 |
| /closeBatchSwitch | POST | ⚠️ 仅鉴权（不实际调用）|

## 三、🔴 P1 失败 — 真业务 bug

### System GlobalSwitch.save() 空 body 触发 SQL 异常

**调用**：
```bash
POST /mes/system/globalSwitch/save
Body: {}
```

**期望**：业务校验拦截（如"开关 key 不能为空"），返回 200 + 错误消息或 400。

**实际**：
```json
{
  "code": 500,
  "message": "### Error updating database. Cause: java.sql.SQLException..."
}
```

**影响**：
- 空 body 直接打到 SQL 层，暴露后端实现细节
- 应在前置 Service 层或 Controller 校验拦截

**修复方向**：
1. Controller `save` 方法加 `@RequestBody @Valid` 注解
2. 或在 Service `saveOrUpdate(sw)` 前加 `if (sw == null || sw.getSwitchKey() == null) throw ...`
3. 或 Entity 加 `@NotBlank` 等 JSR-303 注解

**优先级**：P1（影响所有调用者）

## 四、P3 失败 — 测试代码 bug

### 1. 字段名 `enabled` 不存在
**期望字段**：`enabled`
**实际字段**：`switchValue`（后端实体类定义）

### 2. 字段名 `hasError` 不存在
**期望**：`hasError` (boolean)
**实际**：`canClose` (boolean) + `errors[]` (array)

**修复**：测试断言更新字段名。

## 五、E2E commonSetting.spec.ts 失败

```
Error: expect(locator).toBeVisible() failed — 切片B：通用设置页面端到端验证
```

详见测试截图：`harness/test-results/` 目录。**整页不可达**，可能是：
- 路由守卫拦截
- 菜单权限缺失
- 组件加载失败

**优先级**：P2

## 六、明早优先排查

1. **🔴 P1**: System GlobalSwitch.save 加参数校验（影响所有调用）
2. **🟡 P2**: commonSetting.spec.ts E2E — 看截图 + trace token
3. **🟢 P3**: 更新测试代码字段名

## 七、原始日志

`hermes/eagle-eye/state/api-logs/system.log`
`hermes/eagle-eye/state/api-logs/codeRule.log`
`hermes/eagle-eye/state/e2e-20260804.log`（grep commonSetting）