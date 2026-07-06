[2026-07-05] [前端] 数据库菜单路径必须和前端路由完全一致
触发：菜单配了但页面不渲染（EmptyPage）
原因：菜单 url 和路由 path 必须一致（/customer/demo/warehouse ≠ /customer-demo/warehouse）。component 字段要去 ../views 前缀和 .vue 后缀后完全匹配。
