# docker exec 管道传 SQL 中文乱码

**触发条件：** 用 `docker exec -i mysql-container mysql < file.sql` 执行 SQL 后，数据库中的中文字段变成乱码（如 `MESç®¡ç†å˜`）。

**处理方式：**
1. 根因：MySQL 客户端通过管道输入时默认字符集为 `latin1`，SQL 文件中的 UTF-8 中文经过双重编码
2. 解决（推荐方式 — 管道传文件）：
```bash
cat file.sql | docker exec -i jeecg-boot-mysql mysql -uroot -proot --default-character-set=utf8mb4
```
3. 备选方式（直接重定向）：
```bash
docker exec -i jeecg-boot-mysql mysql -uroot -proot --default-character-set=utf8mb4 jeecg-boot < file.sql
```
4. ⚠️ 避免：`docker exec ... -e "INSERT ... VALUES('中文')"` — shell 会将中文二次编码，即使加了 `--default-character-set=utf8mb4` 也不可靠
3. 已乱码的数据可以用 UPDATE 直接修复（`docker exec` 带 `-e "SET NAMES utf8mb4; UPDATE ..."` 的方式不受影响）
4. SQL 文件（`init-role-user.sql`）中应标注正确的执行方式
