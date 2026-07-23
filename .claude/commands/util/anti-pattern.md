# /anti-pattern

代码写完后自动检查常见反模式。

## JeecgBoot 清单
- Controller 写业务逻辑（应在 Service）
- MyBatis-Plus 循环调数据库（N+1）
- 缺少 update-begin/end 标记
- SQL 字符串拼接
- 密码/Token 硬编码
- 空值未判直接调用
- Maven 新增模块未注册三处
- Vue 用 any 类型
- Drawer/Modal Hook 混用（见 @rules/frontend.md）
- DELETE 缺 joinParamsToUrl

引用: @rules/code-style.md, @rules/backend-first.md, @rules/security.md
