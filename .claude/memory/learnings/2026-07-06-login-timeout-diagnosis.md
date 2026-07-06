# 登录超时诊断

**触发条件：** 前端提示 `timeout of 10000ms exceeded`，点击登录无响应。

**处理方式：**
1. `curl` 直接 POST 调用后端 `/sys/login` 接口确认后端是否响应
2. `nc -zv localhost 3306` + `nc -zv localhost 6379` 检查 MySQL 和 Redis 端口是否可达
3. 若端口拒绝连接 → MySQL/Redis 未启动，后端收到请求后在连接池等待直到超时
4. JeecgBoot 开发环境默认连接 `127.0.0.1:3306` (MySQL root/root) 和 `127.0.0.1:6379` (Redis)
5. 用 Docker 快速启动：
```bash
docker run -d --name jeecg-boot-mysql -p 3306:3306 -e MYSQL_ROOT_PASSWORD=root -e MYSQL_DATABASE=jeecg-boot mysql:8.0 --character-set-server=utf8mb4
docker run -d --name jeecg-boot-redis -p 6379:6379 redis:7-alpine
```
6. 启动 MySQL/Redis 后必须重启后端（数据库连接池在启动时初始化）
