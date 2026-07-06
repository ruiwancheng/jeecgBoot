"""
jimureport_dataset.py — 数据集操作（parse / save / update / parallel）
"""
import time
from concurrent.futures import ThreadPoolExecutor

import requests as _req

from jimureport_core import Session, SIGN_SECRET, _compute_sign


def parse_api(session: Session, api_url: str) -> list[dict]:
    """解析 API 数据集字段，返回 fieldList。"""
    params = {"api": api_url, "method": "0"}
    sign = _compute_sign(params)
    resp = _req.post(
        session.base_url + "/executeSelectApi",
        params=params,
        headers={
            "X-Access-Token": session._s.headers["X-Access-Token"],
            "X-Sign": sign,
            "X-TIMESTAMP": str(int(time.time() * 1000)),
        },
        proxies={},
    )
    resp.raise_for_status()
    r = resp.json()
    if not r.get("success"):
        raise RuntimeError(f"[executeSelectApi] 失败: {r.get('message')}")
    result = r["result"]
    return result["fieldList"] if isinstance(result, dict) else result


def parse_sql(session: Session, sql: str, db_source: str = "") -> list[dict]:
    r = session.request("/queryFieldBySql", {"sql": sql, "dbSource": db_source, "type": "0"})
    return r["result"]["fieldList"]


def save_db(
    session: Session,
    report_id: str,
    db_code: str,
    db_name: str,
    sql: str,
    field_list: list[dict],
    param_list: list[dict] | None = None,
    *,
    db_type: str = "0",
    db_source: str = "",
    is_list: str = "1",
    is_page: str = "1",
    json_data: str = "",
    db_id: str | None = None,
    is_shared: int = 0,
    api_url: str = "",
    api_method: str = "0",
    api_convert: str = "",
    java_type: str = "",
    java_value: str = "",
) -> str:
    """
    保存（新增/更新）数据集，返回数据集 ID。
    db_type: "0"=SQL / "1"=API / "2"=JavaBean / "3"=JSON / "4"=共享
    JavaBean 专用：java_type="spring-key", java_value=Bean名称
    """
    # JSON 数据集自动包裹：引擎从 data 键取行，裸 list/dict 会导致预览全空
    if db_type == "3" and json_data:
        try:
            import json as _json
            _parsed = _json.loads(json_data) if isinstance(json_data, str) else json_data
            if isinstance(_parsed, list):
                json_data = _json.dumps({"data": _parsed}, ensure_ascii=False)
            elif isinstance(_parsed, dict) and "data" not in _parsed:
                json_data = _json.dumps({"data": [_parsed]}, ensure_ascii=False)
            elif not isinstance(json_data, str):
                json_data = _json.dumps(_parsed, ensure_ascii=False)
        except (ValueError, TypeError):
            pass

    payload: dict = {
        "izSharedSource": is_shared,
        "jimuReportId":   "" if is_shared else report_id,
        "dbCode":         db_code,
        "dbChName":       db_name,
        "dbType":         db_type,
        "dbSource":       db_source,
        "isList":         is_list,
        "isPage":         is_page,
        "dbDynSql":       sql,
        "jsonData":       json_data,
        "apiConvert":     api_convert,
        "apiUrl":         api_url,
        "apiMethod":      api_method,
        "fieldList":      field_list,
        "paramList":      param_list or [],
    }
    if db_type == "1":
        payload["apiUrl"]    = api_url or sql
        payload["apiMethod"] = api_method
    if db_type == "2":
        payload["javaType"]  = java_type or "spring-key"
        payload["javaValue"] = java_value
    if db_id:
        payload["id"] = db_id
    for attempt in range(3):
        try:
            r = session.request("/saveDb", payload)
            return r["result"]["id"]
        except RuntimeError as e:
            if "Deadlock" in str(e) and attempt < 2:
                time.sleep(0.3 * (attempt + 1))
            else:
                raise


def update_db(session: Session, db_id: str, **fields) -> None:
    """
    轻量更新数据集单个或多个字段，比 save_db 快 ~300x。

    传 paramList 时若新列表含与原表已有 paramName 相同的项，必须保留原项的 `id`，
    否则后端按 (jimuReportHeadId + paramName) 唯一约束插入冲突 → 整事务回滚，
    连 dbDynSql/其它字段也跟着保存失败（响应仍可能显示 success）。
    """
    result = session.get(f"/loadDbData/{db_id}")["result"]
    db = result["reportDb"]
    db["fieldList"] = result["fieldList"]
    existing_params = result.get("paramList") or []
    db["paramList"] = existing_params

    if "paramList" in fields:
        existing_id_by_name = {p["paramName"]: p.get("id") for p in existing_params}
        merged = []
        for p in fields["paramList"]:
            if p.get("id") is None and p.get("paramName") in existing_id_by_name:
                p = {**p, "id": existing_id_by_name[p["paramName"]]}
            merged.append(p)
        fields = {**fields, "paramList": merged}

    # JSON 数据集自动包裹（同 save_db 逻辑）
    if "jsonData" in fields and db.get("dbType") == "3":
        try:
            import json as _json
            _jd = fields["jsonData"]
            _parsed = _json.loads(_jd) if isinstance(_jd, str) else _jd
            if isinstance(_parsed, list):
                fields = {**fields, "jsonData": _json.dumps({"data": _parsed}, ensure_ascii=False)}
            elif isinstance(_parsed, dict) and "data" not in _parsed:
                fields = {**fields, "jsonData": _json.dumps({"data": [_parsed]}, ensure_ascii=False)}
            elif not isinstance(_jd, str):
                fields = {**fields, "jsonData": _json.dumps(_parsed, ensure_ascii=False)}
        except (ValueError, TypeError):
            pass

    db.update(fields)
    session.request("/saveDb", db)


def parse_and_save_dataset(
    session: Session,
    report_id: str,
    db_code: str,
    db_name: str,
    sql: str,
    db_source: str = "",
    **save_db_kwargs,
) -> tuple[list[dict], str]:
    """
    解析 SQL → 保存数据集，返回 (field_list, db_id)。
    允许 report_id 此时尚不存在于服务端（orphan report_id）。
    """
    field_list = parse_sql(session, sql, db_source)
    db_id = save_db(session, report_id, db_code, db_name, sql, field_list,
                    db_source=db_source, **save_db_kwargs)
    return field_list, db_id


def parallel_parse_sqls(session: Session, sql_configs: list[dict]) -> list[list[dict]]:
    with ThreadPoolExecutor(max_workers=len(sql_configs)) as ex:
        futures = [
            ex.submit(parse_sql, session, cfg["sql"], cfg.get("db_source", ""))
            for cfg in sql_configs
        ]
        return [f.result() for f in futures]


def parallel_save_dbs(session: Session, db_configs: list[dict]) -> list[str]:
    with ThreadPoolExecutor(max_workers=len(db_configs)) as ex:
        futures = [ex.submit(save_db, session, **cfg) for cfg in db_configs]
        return [f.result() for f in futures]


def parallel_parse_apis(session: Session, api_urls: list[str]) -> list[list[dict]]:
    with ThreadPoolExecutor(max_workers=min(len(api_urls), 8)) as ex:
        futures = [ex.submit(parse_api, session, u) for u in api_urls]
        return [f.result() for f in futures]
