---
name: done
description: 开发完成检查，验证代码提交和文档完整性 — Development completion checklist: verify commits and documentation
version: 1.0.0
---

# 开发完成检查 (Done)

## 检查清单

### 1. 文件范围检查

- [ ] 所有新增/修改文件都在项目专属目录内：
  - 后端：`jeecg-boot/jeecg-boot-module/project-{项目名}/`
  - 前端：`jeecgboot-vue3/src/views/customer/{客户名}/`
- [ ] 没有改动平台核心目录（`jeecg-boot-base-core/`、`jeecg-module-system/`）
- [ ] 没有改动其他项目的目录
- [ ] 公共注册点（路由文件、pom.xml）只新增不改已有

### 2. 代码标记检查

- [ ] 所有 Java 修改/新增有 `update-begin` / `update-end` 标记
- [ ] 标记中的 `author`、`date`、`for` 字段完整
- [ ] 标记格式符合规范（参见 `jeecg-dev` 技能）

### 3. 功能完整性检查

- [ ] Controller 有权限注解（`@RequiresPermissions` 或 `@RequiresRoles`）
- [ ] Service 有事务注解（需要事务的场景）
- [ ] 异常有 try-catch 或全局异常处理
- [ ] 输入参数有校验（`@NotBlank`、`@NotNull` 等）
- [ ] 外部接口调用有超时和降级处理

### 4. 注册完整性检查

- [ ] 新 Controller 是否在菜单表（`sys_permission`）注册（如有前端页面）
- [ ] 新前端页面是否在路由文件中注册
- [ ] 新 Maven 模块是否在三处注册（boot-module pom、system-start pom、mvn install）

## 验证证据

### /verify 结果

/verify 通过，具体输出：
- curl 返回的 HTTP 状态码（如 `200`）
- 响应体关键片段（如 `"code":200,"success":true`）
- Playwright 页面验证截图或元素确认

### /test-api 结果

/test-api 通过，具体输出：
- 测试方法数：`N` 个
- 通过数：`N` 个
- 失败数：`0` 个
- 任何失败项的详细报错

## 下一步选项

完成检查后，给用户以下选项：

1. **提交代码** — 生成 commit message，确认后提交
2. **继续修改** — 还有需要调整的地方
3. **暂留不提交** — 当前改动保留在工作区，稍后处理

## 铁律

> **不确定下一步时给用户选项，不自作主张。**
>
> 不自动执行 `git commit` 或 `git push`，必须等用户确认。
> 不自动创建 MR/PR。
