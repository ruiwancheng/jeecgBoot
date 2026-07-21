-- V9.5.1 — 开发环境 MySQL 远程访问授权（本地后端直连服务端数据库）
-- 允许 Tailscale VPN 网内所有主机以 root 连接（仅开发环境，生产环境请收紧）
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root' WITH GRANT OPTION;
FLUSH PRIVILEGES;
