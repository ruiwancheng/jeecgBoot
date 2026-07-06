# Super Harness v2.0 — 项目制 + 模式管理 完整方案

**状态**：待用户确认
**日期**：2026-07-05

---

## 一、核心变更

v1.x → v2.0：
1. 客户模块 → 项目制
2. 新增项目自动注册账号、角色、权限绑定
3. 多项目切换 + 管理员模式
4. 文件/数据库边界规则补全

---

## 二、项目管理

### 命令

| 命令 | 作用 |
|------|------|
| `/new-project <项目名>` | 创建新项目 + 代码目录 + Maven + 角色+用户 + 激活 |
| `/switch-project <项目名>` | 切换到已有项目 |
| `/list-projects` | 列出所有项目 |

### /new-project 自动创建

| 创建内容 | 命名 | 示例 |
|---------|------|------|
| Maven 模块 | `project-<项目名>/` | `project-demo/` |
| 角色 | `<项目名>` | `demo` |
| 用户 | `<项目名>_admin` / `123456` | `demo_admin` |
| 路由文件 | `modules/<项目名>.ts` | 
| 前端目录 | `src/views/project/<项目名>/` | 
| 记忆 | `memory/active-project.md` | 记录当前项目 |

### 命名规范

| 层面 | 格式 | 示例 |
|------|------|------|
| Maven 模块 | `project-demo` | |
| 角色编码 | `demo` | |
| 用户账号 | `demo_admin` | |
| 菜单 ID | `demo_wh` | |
| 数据库表 | `c_demo_*` | |
| 前端目录 | `src/views/project/demo/` | |

---

## 三、模式体系

### 业务模式（默认）
- 所有限制生效，操作自动归属当前项目
- `/new-project` `/switch-project` 可用

### 管理员模式
- `/admin` 进入，不做任何限制
- 会话提醒"管理员模式已开启"
- `/switch-project <项目名>` 回到业务模式

### 不做密码校验
能操作这台机器的人已有完全控制权，不加形式锁。

---

## 四、文件边界

| 区域 | 业务模式 | 管理员 |
|------|:---:|:---:|
| `project-<项目名>/` | 可写 | 可写 |
| `src/views/project/<项目名>/` | 可写 | 可写 |
| `src/router/routes/modules/` | 可新增 | 可写 |
| pom.xml | 可新增项 | 可写 |
| 平台核心 `base-core/` | 禁止 | 可写 |
| 系统管理 `module-system/` | 禁止 | 可写 |
| 公共组件 `components/` | 禁止 | 可写 |
| `.claude/` Harness | 禁止 | 可写 |
| 其他项目目录 | 禁止 | 可写 |

## 五、数据库边界

| 操作 | 业务模式 | 管理员 |
|------|:---:|:---:|
| `CREATE TABLE c_<项目名>_*` | 允许 | 允许 |
| `INSERT sys_permission` (项目前缀) | 允许 | 允许 |
| `INSERT sys_role_permission` (项目角色) | 允许 | 允许 |
| `UPDATE/DELETE` 系统核心表 | 禁止 | 允许 |
| `DROP TABLE` | 禁止 | 允许 |
| 改标品表结构 | 禁止 | 允许 |

## 六、归属判定

| 场景 | 判定 |
|------|------|
| 新增文件 | 必须在项目目录或路由 modules 下 |
| 新增菜单 | id 含项目前缀 |
| 新增权限 | 绑定到项目角色 |
| 修改已有 | git diff 检查归属 |

## 七、需要改动

| 文件 | 操作 |
|------|------|
| `/new-project` | 重写（替代 new-customer） |
| `/switch-project` | 新增 |
| `/admin` | 新增 |
| `rules/file-scope.md` | 更新 |
| `rules/data-scope.md` | 新增 |
| `project-template/` | 更新 |
| `hooks/session-start.sh` | 更新 |
| `memory/` | 自动管理 |

## 八、待确认

- [ ] 方案整体是否通过
- [ ] 用户账号挂根部门是否够用
- [ ] 密码 123456 是否需要额外提醒
