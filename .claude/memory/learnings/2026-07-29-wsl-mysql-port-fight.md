# WSL MySQL 与 Windows mysqld 抢 3306（DB 幻影根因 + 根治法）

**现象**：本地开发库反复出现"表不存在/删了的数据又回来了/连接抖动"。

**根因**：WSL Ubuntu 里装了 MySQL 且 systemd **enabled**，wslrelay.exe 把 WSL 的 3306 转发到 127.0.0.1:3306，与 Windows 手动启动的 mysqld（0.0.0.0:3306）同时应答。连接被随机路由到两个不同数据库（不同 server_uuid、不同数据），`service mysql stop` 后 systemd 又自动拉起。

**诊断命令**：
```bash
for i in 1 2 3; do mysql -uroot -proot --host=127.0.0.1 -N -e "SELECT @@server_uuid;"; done
# 出现两个不同 uuid = 两个库在抢端口
netstat -ano | grep ":3306" | grep LISTEN   # wslrelay.exe + mysqld.exe 双监听
```

**根治**（stop 不够，必须 disable 防 systemd 复活）：
```bash
wsl -d Ubuntu -- sudo systemctl disable mysql
wsl -d Ubuntu -- sudo service mysql stop
```

**项目约定**：本地开发库以 Windows 手动 mysqld 为准（`"C:\Program Files\MySQL\MySQL Server 8.4\bin\mysqld.exe" --console`），WSL 内禁止跑 MySQL。

**实证**：2026-07-29 两次"残留清理后又出现"均因此（清理打到 WSL 库，查的是 Windows 库）。disable 后清理一次到位。
