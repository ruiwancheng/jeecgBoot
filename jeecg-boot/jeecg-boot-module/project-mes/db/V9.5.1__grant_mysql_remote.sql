-- V9.5.1 — MySQL 远程访问授权（MySQL 8.0 native auth 兼容）
-- 新建 dev 用户（不改 root，避免权限冲突）
CREATE USER IF NOT EXISTS 'dev'@'%' IDENTIFIED WITH mysql_native_password BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'dev'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
