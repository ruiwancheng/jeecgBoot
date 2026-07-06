---
name: restart-backend
description: 重启后端 Java 应用。当用户说"重启后端"、"重启服务"、"重启应用"时自动触发。Restart the backend Java application when user says "restart backend", "restart server", "restart service".
---

# 重启后端应用

重启 JeecgBoot 后端 Spring Boot 应用。

---

## 进程信息

| 项目 | 值 |
|------|-----|
| 主类名 | `JeecgSystemApplication` |
| 默认端口 | 8080 |
| 上下文路径 | `/jeecg-boot` |

---

## 执行流程

### 1. 停止旧进程

```bash
pkill -f "JeecgSystemApplication" 2>/dev/null
sleep 3
```

确保进程完全退出后再启动。如果进程不存在，`pkill` 不会报错（`2>/dev/null` 静默处理）。

### 2. 启动新进程

```bash
cd jeecg-boot/jeecg-module-system/jeecg-system-start
nohup mvn spring-boot:run -DskipTests > /tmp/jeecg-backend.log 2>&1 &
```

| 参数 | 说明 |
|------|------|
| `nohup` | 后台运行，忽略 SIGHUP |
| `-DskipTests` | 跳过测试，加快启动 |
| `> /tmp/jeecg-backend.log 2>&1` | 标准输出和错误重定向到日志文件 |
| `&` | 放入后台 |

### 3. 验证启动

等待最多 60 秒，然后检查启动结果：

**成功信号：**
```bash
grep "Started JeecgSystemApplication" /tmp/jeecg-backend.log
```

出现该日志行表示应用启动成功，端口 8080 已就绪。

**失败信号：**
```bash
grep -E "BUILD FAILURE|Error" /tmp/jeecg-backend.log
```

出现 `BUILD FAILURE` 或严重 `Error` 表示启动失败。查看日志尾部获取详细错误信息：

```bash
tail -50 /tmp/jeecg-backend.log
```

### 4. 查看实时日志（可选）

```bash
tail -f /tmp/jeecg-backend.log
```

---

## 常见失败原因

| 错误 | 原因 | 处理 |
|------|------|------|
| `Connection refused` (MySQL) | MySQL 未启动 | 启动 MySQL 服务 |
| `Connection refused` (Redis) | Redis 未启动 | 启动 Redis 服务 |
| `Address already in use` | 端口 8080 被占用 | 检查是否有残留进程，手动 kill |
| `BUILD FAILURE` | 编译错误 | 查看编译错误详情，修复代码 |
| `Table 'xxx' doesn't exist` | Flyway 未执行 | 检查 SQL 文件是否正确放置 |

---

## 注意事项

- 启动需要 Maven 本地仓库已有依赖包，首次启动可能需要较长时间下载
- 如果使用 Docker 环境，数据库和 Redis 地址可能不同，请参考 `application-docker.yml`
- 不要同时启动多个后端实例（端口冲突）
