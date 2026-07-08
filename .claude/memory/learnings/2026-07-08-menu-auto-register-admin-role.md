[2026-07-08] [菜单自动注册] 跑者组件必须同时授权给项目角色和admin角色
触发条件：使用 ApplicationRunner 自动注册 sys_permission 菜单
处理方式：
1. 菜单 INSERT 到 sys_permission 后，需同时绑定两个角色：
   - 项目角色（如 `{项目名}_role_001`）：项目管理员可见
   - admin 角色（roleCode='admin'）：超级管理员可见
2. admin 角色 ID 需动态查询（不同环境的 admin 角色 ID 不同），不能硬编码
3. 每个绑定都要先 selectCount 检查是否存在，保证幂等
4. 如果不绑 admin 角色，admin 用户在菜单树里看不到新菜单，只有项目角色用户能看到
