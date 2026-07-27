---
name: file-scope
description: 文件读写边界——可新增自己项目的，不能改平台和别人的
glob: "**/*"
version: 2.0
---

# 文件读写边界

## 可以写入

### 项目文件（自由读写）
- `jeecg-boot/jeecg-boot-module/project-{当前项目}/`
- `jeecgboot-vue3/src/views/project/{当前项目}/`

### 公共注册点（只能新增，不改已有）
- `jeecgboot-vue3/src/router/routes/modules/` — 新增路由文件
- Maven pom.xml — 新增 `<module>` 和 `<dependency>`

## 绝对不能写入
- `jeecg-boot/jeecg-boot-base-core/` — 平台核心框架（全部）
- `jeecg-boot/jeecg-module-system/jeecg-system-biz/` — 系统业务逻辑代码
- `jeecg-boot/jeecg-module-system/jeecg-system-api/` — 系统 API 接口定义
- `jeecg-boot/jeecg-module-system/jeecg-system-start/src/` — 系统启动器和配置文件
- `jeecgboot-vue3/src/views/system/` — 系统管理前端
- `jeecgboot-vue3/src/components/` — 公共组件
- `.claude/` — Harness 工程文件
- 其他项目目录（`project-xxx/`）

> `system-start/pom.xml` 不在保护范围——新模块的 Maven 依赖注册是正常的项目开发操作。
> 数据库边界见 `data-scope`，管理员模式 `/admin` 解除限制

> 工程产物放 `harness/` 和 `hermes/`
> 数据库边界见 `data-scope`，管理员模式 `/admin` 解除限制
