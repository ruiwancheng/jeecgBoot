---
name: boundary
description: 操作边界——文件写入+数据库操作+平台保护，合并自 file-scope + data-scope（2026-07-28 token 降本）
glob: "**/*"
version: 3.0
---

# 操作边界

## 文件系统

### 可以写入

#### 项目文件（自由读写）
- `jeecg-boot/jeecg-boot-module/project-{当前项目}/`
- `jeecgboot-vue3/src/views/project/{当前项目}/`

#### 公共注册点（只能新增，不改已有）
- `jeecgboot-vue3/src/router/routes/modules/` — 新增路由文件
- Maven pom.xml — 新增 `<module>` 和 `<dependency>`

### 禁止写入
- `jeecg-boot/jeecg-boot-base-core/` — 平台核心框架
- `jeecg-boot/jeecg-module-system/jeecg-system-biz/` — 系统业务逻辑
- `jeecg-boot/jeecg-module-system/jeecg-system-api/` — 系统 API 接口
- `jeecg-boot/jeecg-module-system/jeecg-system-start/src/` — 系统启动器
- `jeecgboot-vue3/src/views/system/` — 系统管理前端
- `jeecgboot-vue3/src/components/` — 公共组件
- `.claude/` — Harness 工程文件
- 其他项目目录（`project-xxx/`）

> `system-start/pom.xml` 不在保护范围——新模块的 Maven 依赖注册是正常操作。
> 工程产物放 `harness/` 和 `hermes/`，管理员模式 `/admin` 解除限制。

## 数据库

### 可以做的（当前项目）
- `CREATE TABLE c_{项目名}_*` — 项目表
- `INSERT sys_permission` — id 用项目前缀
- `INSERT sys_role_permission` — 绑到项目角色
- 读写项目自己的业务数据

### 不能做的
- `UPDATE/DELETE` 非当前项目的菜单和权限
- 改 `sys_role`、`sys_user`、`sys_depart` 等系统核心表
- `DROP TABLE` 任何表
- 改标品表结构
- SQL 必须参数化

## /evolve 增量规则（2026-07 / 8 月 整理）

### defHttp 拦截器自动成功横幅（defhttp-auto-banner）

**问题**：长文本接口（如导出）触发 `defHttp` 拦截器自动 `message.success('操作成功')` —— 与业务自定义 `successMessageMode: 'none'` 冲突，UI 出现两条重复提示 + 滚动。

**强制规则**：
- ✅ 所有**长文本/导出/下载/不返回 JSON** 的 API → `successMessageMode: 'none'` + `errorMessageMode: 'message'`
- ✅ 普通 CRUD → 默认（自动提示成功）
- ✅ 自定义提示的 API → `successMessageMode: 'message'`（自己控制）

详见 `learnings/2026-07-29-defhttp-auto-banner.md`。

### defHttp DELETE 参数（defhttp-delete-joinparams）

**问题**：`defHttp.delete(url, params)` 用 `URLSearchParams`（join）拼接，复杂对象被序列化错误（`[object Object]`）。

**强制规则**：
- ✅ 单 ID：`defHttp.delete({ url, params: { id: 1 } })`
- ✅ 批量 ID：`defHttp.delete({ url, params: { ids: '1,2,3' } })`（**逗号分隔字符串**，非数组）
- ❌ 不用数组 `ids: [1,2,3]`（被 join 成 `1,2,3` 字符串 OK，但 object 失败）
- ❌ 不用对象 `params: { filter: {...} }`（被 join 失败）

详见 `learnings/2026-07-06-defhttp-delete-joinparams.md`。

### HTTP 200 包着 404（http200-wraps-404）

**铁律**：JeecgBoot API `code=500` 时 HTTP 仍是 200。**HTTP 码 ≠ 业务码**。

**强制检查**（每次 API 测试）：
```js
expect(res.code).toBe(500)   // 业务码，不是 HTTP
expect(res.message).toContain('not found')
```

**反模式**：
- ❌ 只看 `response.status() === 404`
- ❌ 测试通过 HTTP 200 就认为成功

详见 `learnings/2026-07-28-http200-wraps-404.md`。

### 密码加密（password-encrypt）

JeecgBoot 默认 `RSA` + `AES` 混合加密。**前端不能直接传明文密码**。

**强制规则**：
- ✅ 用户登录 → 后端 `/sys/getEncryptedString` 获取公钥 → 前端 `encryptedData` 加密 → 提交
- ✅ 密码重置 → 同样加密流程
- ❌ 不要写 `password: 'plain123'`（会被 RSA 校验失败）

详见 `learnings/2026-07-06-password-encrypt.md`。

### 权限注解 + 字段影响（api-permission-add-drops-fields）

**问题**：Controller 加 `@RequiresPermissions("xxx:add")` 时，**SQL 自动过滤**导致返回字段被裁剪（如 `delFlag=0` 过滤掉后 select 字段不一致）。

**强制检查**（加权限注解时）：
- [ ] 看 SQL 是否有 `@SqlParser(filter=true)` 或逻辑删除过滤
- [ ] 跑实际 API 对比有/无权限的返回字段
- [ ] 前端是否依赖被过滤字段

详见 `learnings/2026-07-14-api-permission-add-drops-fields.md`。

#### 9. 权限注解作用域检查（permission-annotation-scope-check）
**加 `@RequiresPermissions` 前必查**：
- [ ] 方法是否在 `Controller`（不是 `Service` —— Service 注解无效）
- [ ] 权限码是否在 `sys_permission` 表已注册
- [ ] 注解是否 `@RequiresPermissions`（不是 `@RequiresRoles` —— 不同语义）
- [ ] 多权限用 `@RequiresPermissions(value={"a","b"}, logical=Logical.OR)`
详见 `learnings/2026-07-21-permission-annotation-scope-check.md`。

### Claude Code 沙箱 git push 失败处理（claude-code-sandbox-git-push）

//update-begin---author:evolve---date:2026-08-02---for:【/evolve 批 3】合并 7 月运维 1 条 learning 到 boundary.md---

**问题**：Claude Code Bash 中执行 `git push origin main` 反复失败（HTTP 408 / curl 56 / curl 16 / curl 52）。

**根因**：macOS git 使用 `osxkeychain` credential helper，凭证存储在系统 Keychain 中。Claude Code 的 Bash 沙箱**可能受 Keychain 访问限制**；HTTP 408 也可能是服务端代理配置问题。

**诊断**：
```bash
git config --get credential.helper  # 确认: osxkeychain
git push origin main --verbose      # 观察: curl 56 Connection died / HTTP 408
```

**解决方案（优先级排序）**：

**方案 A：终端手动推送**（最简单）
```bash
cd /path/to/repo && git push origin main
```
终端有完整 Keychain 访问权限，不受沙箱限制。

**方案 B：Personal Access Token**
```bash
git push https://TOKEN@github.com/user/repo.git main
```
Fine-grained PAT 必须选中目标仓库 + Contents: Read and write。

**方案 C：SSH**
```bash
git remote set-url origin git@github.com:user/repo.git
git push origin main
```

**不生效的方案**：
- ❌ `git config http.postBuffer 524288000`（不是缓冲区问题）
- ❌ `git config --local http.version HTTP/1.1`（不是协议版本问题）
- ❌ `git -c credential.helper= push`（沙箱层面阻断）

**关键教训**：
- 不要反复重试 git push —— 换认证方式才是正解
- `gh` CLI 同样受 Keychain 限制（`gh auth status` → keyring timeout）
- Token 推送成功一次不代表永久有效（Token 可能过期）

详见 `learnings/2026-07-20-claude-code-sandbox-git-push.md`。

### MCP server command 必须用绝对路径（mcp-server-absolute-path）

**铁律**：`.mcp.json` 里 `mcpServers.<name>.command` **必须填绝对路径**，禁止填 `python` / `python3` / `python3.11` 等可被 PATH 截胡的命令名。

**问题**：macOS 用户通常装了多个 Python 解释器，PATH 第一个命中的不一定是 homebrew 那个，**包安装位置不一致**：

| PATH 命中 | 是否装了 code_review_graph |
|-----------|:---:|
| `/Users/ruisuyun/.local/bin/python3.11` | ❌ |
| `/opt/homebrew/bin/python3.11` | ✅ v2.3.7 |

`python3.11 -m code_review_graph serve` 命中第一个 → `ModuleNotFoundError` → MCP 进程秒退 → Claude Code 静默无工具注入，无任何错误日志。

**强制规则**：
- ✅ `command: "/opt/homebrew/bin/code-review-graph"` + `args: ["mcp"]`
- ✅ `command: "/usr/local/bin/some-mcp-server"` + `args: [...]`
- ❌ `command: "python3.11"` + `args: ["-m", "code_review_graph", "serve"]`
- ❌ `command: "python"` + `args: [...]`

**诊断信号**：
- `/capability-check` 报 MCP 不可用但 `code-review-graph status` 显示图谱健康
- Claude Code 重启后依然无 `mcp__*__*` 工具
- 直接跑 `command args...` 在终端能启动 server，但 MCP 协议层不识别

**修复流程**：
1. `which <命令名>` 看命中哪个解释器
2. `command -p <绝对路径>` 验证绝对路径可执行
3. 改 `.mcp.json` 用绝对路径
4. **完全退出 Claude Code 重开**（`/exit` 不够）

**反模式**：
- ❌ 反复改 `python3` → `python3.11` → `python3.12`，猜下一个 PATH 命中（包可能没装）
- ❌ `pip install` 给错误的解释器装包（浪费 30s）
- ❌ 静默降级走 Grep/Read —— 失去架构感知能力不可恢复

详见 `learnings/2026-08-06-mcp-server-absolute-path.md`。

//update-begin---author:evolve---date:2026-08-06---for:【MCP 不可用】code-review-graph 修复沉淀（3 次改 command 才定位 PATH 截胡）---
//update-end---author:evolve---date:2026-08-06---for:【MCP 不可用】code-review-graph 修复沉淀（3 次改 command 才定位 PATH 截胡）---

//update-end---author:evolve---date:2026-08-02---for:【/evolve 批 3】合并 7 月运维 1 条 learning 到 boundary.md---
