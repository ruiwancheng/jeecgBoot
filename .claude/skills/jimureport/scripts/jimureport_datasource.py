"""
jimureport_datasource.py — 数据源管理（ensure / find / query）
"""
import time

from jimureport_core import Session, _compute_sign


def resolve_db_source(session: Session) -> str:
    """
    用户未指定数据源时自动选取，规则：
    1. initDataSource 返回空 → RuntimeError 提示先新增数据源
    2. 存在 name 含「积木」的项 → 自动选第一个，返回其 id
    3. 无含「积木」的项 → RuntimeError 列出全部数据源，由上层询问用户
    """
    records = session.get("/initDataSource").get("result", [])
    if not records:
        raise RuntimeError(
            "当前积木报表没有可用数据源，请先在【数据源管理】中新增一个数据源。"
        )
    jimureport_ds = [r for r in records if "积木" in (r.get("name") or "")]
    if jimureport_ds:
        return jimureport_ds[0]["id"]
    names = "\n".join(f"  - {r.get('name')}（id: {r.get('id')}）" for r in records)
    raise RuntimeError(
        f"未找到含「积木」的数据源，请告知选用哪个：\n{names}"
    )


def find_datasource(session: Session, ds_name: str) -> str:
    resp = session.get("/initDataSource")
    records = resp.get("result", [])
    matched = [r for r in records if r.get("name") == ds_name]
    if not matched:
        names = [r.get("name") for r in records]
        raise RuntimeError(f"未找到数据源 '{ds_name}'，可用列表：{names}")
    return max(matched, key=lambda x: x["id"])["id"]


def ensure_datasource(
    session: Session,
    name: str,
    db_type: str,
    db_url: str,
    db_username: str = "",
    db_password: str = "",
    db_driver: str = "",
    report_id: str = "",
) -> str:
    """
    确保指定名称的数据源存在，返回其 ID。
    已存在：1 次 HTTP；不存在：创建 + 再查，2 次 HTTP。

    dbType 枚举值（大小写严格，前端下拉枚举匹配）：
      MySQL 5.7  → "MYSQL5.7"    MySQL 8   → "MYSQL8"
      Oracle     → "ORACLE"      SQLServer → "SQLSERVER"
      PostgreSQL → "POSTGRESQL"  Redis     → "redis"  ← 全小写（唯一例外，已验证）
      MongoDB    → "mongodb"
    Redis 示例：
      ensure_datasource(session, "myRedis", db_type="redis",
                        db_driver="redis.clients.jedis.Jedis",
                        db_url="127.0.0.1:6379")
    """
    resp = session.get("/initDataSource")
    records = resp.get("result", [])
    matched = [r for r in records if r.get("name") == name]
    if matched:
        return max(matched, key=lambda x: x["id"])["id"]

    session.request("/addDataSource", {
        "id": "", "reportId": report_id, "code": "",
        "name": name, "dbType": db_type, "dbDriver": db_driver,
        "dbUrl": db_url, "dbUsername": db_username, "dbPassword": db_password,
    })

    resp = session.get("/initDataSource")
    records = resp.get("result", [])
    matched = [r for r in records if r.get("name") == name]
    if not matched:
        raise RuntimeError(f"数据源 '{name}' 保存后仍无法查询到，请检查服务端日志")
    return max(matched, key=lambda x: x["id"])["id"]


def get_ds_connection(session: Session, ds_id: str) -> tuple[str, int, str, str, str]:
    """获取数据源 JDBC 连接信息，返回 (host, port, db_name, username, password)。"""
    import re
    sign = _compute_sign({"id": ds_id})
    resp = session._s.get(
        f"{session.base_url}/getDataSourceById?id={ds_id}",
        headers={
            "X-Access-Token": session._s.headers["X-Access-Token"],
            "X-TIMESTAMP": str(int(time.time() * 1000)),
            "X-Sign": sign,
        },
    )
    resp.raise_for_status()
    ds = resp.json()["result"]
    m = re.search(r"jdbc:mysql://([^:/]+):(\d+)/([^?]+)", ds["dbUrl"])
    if not m:
        raise RuntimeError(f"无法解析 JDBC URL: {ds['dbUrl']}")
    return m.group(1), int(m.group(2)), m.group(3), ds["dbUsername"], ds["dbPassword"]


def query_mysql(host: str, port: int, db_name: str, user: str, pwd: str, sql: str) -> list[tuple]:
    import pymysql
    conn = pymysql.connect(host=host, port=port, database=db_name,
                           user=user, password=pwd, charset="utf8mb4")
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchall()
    finally:
        conn.close()


def execute_ds(session: Session, ds_id: str, sql: str, params=None) -> list[tuple]:
    """通过数据源 ID 自动取凭证并执行 SQL（DDL/DML/SELECT 均可），无需手动传 MySQL 凭证。"""
    import pymysql
    host, port, db, user, pwd = get_ds_connection(session, ds_id)
    conn = pymysql.connect(host=host, port=port, database=db,
                           user=user, password=pwd, charset="utf8mb4")
    try:
        with conn.cursor() as cur:
            cur.execute(sql, params or ())
            conn.commit()
            return cur.fetchall()
    finally:
        conn.close()
