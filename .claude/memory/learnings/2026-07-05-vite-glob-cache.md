[2026-07-05] [前端] 新增 Vue 组件后必须重启 Vite
触发：/new-customer 后页面显示"查看组件引用是否正确"（EmptyPage）
原因：import.meta.glob('../views/**/*.vue') 缓存文件列表，新文件不在缓存
处理：重启前端 dev server（pkill -f vite && pnpm dev）
