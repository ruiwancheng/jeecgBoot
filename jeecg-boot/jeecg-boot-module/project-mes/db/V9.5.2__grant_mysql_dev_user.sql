-- V9.5.2 — MySQL 远程访问授权（全新文件名，绕过校验码缓存）
SET @user_exists = (SELECT COUNT(*) FROM mysql.user WHERE user = 'dev' AND host = '%');
SET @sql1 = IF(@user_exists = 0, 'CREATE USER ''dev''@''%'' IDENTIFIED WITH mysql_native_password BY ''root''', 'SELECT 1');
PREPARE stmt1 FROM @sql1; EXECUTE stmt1; DEALLOCATE PREPARE stmt1;
GRANT ALL PRIVILEGES ON *.* TO 'dev'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
