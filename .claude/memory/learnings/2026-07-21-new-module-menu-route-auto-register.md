# [2026-07-21] [Harness] 新模块必须自动注册菜单+路由+权限 — checklist最易漏项

## 触发条件
新建模块后，后端 Entity/Controller/Service + 前端 index.vue/data.ts/api.ts 全部写完，
但页面在菜单中找不到，404。

## 根因
新模块开发 checklist 中"菜单注册"排在 SQL/Entity 之后，容易被遗忘。
本次编码规则模块就是写了后端+前端但忘了注册菜单和路由。

## 三步注册（新模块必须全部执行）

### 1. MesMenuRegistry（后端菜单 + 权限码）
```java
// 菜单
list.add(MesMenuDefinition.leaf("menu_id", "parent_id", "菜单名", "/url", "component/path", "ComponentName"));
// 权限码
addPerms(list, "mes:xxx:", "menu_id", new String[]{"list","add","edit","delete","deleteBatch","export","import"});
```

### 2. mes.ts 路由（前端路由）
```ts
{ path: 'xxx', name: 'XxxName', component: () => import('/@/views/project/mes/basic/xxx/index.vue'), meta: { title: '页面标题' } }
```

### 3. 验证
- 部署后登录 → 菜单出现 → 页面可访问
- 如果 404 → 检查 `sys_permission.is_route = 1` 且 `component` 路径正确

## Harness 保护措施
- `pre-commit-check.sh` 已加入前端语法检查（`vue-tsc`），防止路由文件语法错误
- `code-style.md` checklist 首条已改为"菜单与路由"
- 以后新模块写完代码后，AI 必须自动执行此三步注册
