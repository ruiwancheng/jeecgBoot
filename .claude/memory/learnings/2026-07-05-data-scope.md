[2026-07-05] [边界规则] 文件规则管不了数据库操作，需要独立的 data-scope
触发：业务人员通过 SQL 配菜单绕过了 Hook
处理：新建 data-scope 规则。允许 INSERT 项目前缀的菜单，禁止 UPDATE/DELETE 系统核心表。
