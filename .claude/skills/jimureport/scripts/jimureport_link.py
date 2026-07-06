"""
jimureport_link.py — 钻取/联动配置
"""
import json
from concurrent.futures import ThreadPoolExecutor

from jimureport_core import Session


def save_mastersub_link(
    session: Session,
    report_id: str,
    main_db: str,
    sub_db: str,
    main_field: str,
    sub_param: str,
    link_name: str = "主子表关联",
    *,
    link_id: str | None = None,
) -> str:
    """
    保存主子表关联（linkType=4），返回 linkId。

    ⚠️ /link/saveAndEdit 无 id 时始终 INSERT，重复调用会产生多条记录导致渲染 NPE。
    JimuReport 没有提供通过接口查询已有 link 记录的能力，因此：
      - 首次创建：不传 link_id → INSERT，返回的 linkId 必须由调用方保存
      - Patch 更新：传入之前保存的 link_id → UPDATE，避免重复
    若丢失了 link_id 又无法用接口查询，只能通过数据库手动清理重复记录。
    """
    param_str = json.dumps({
        "main": main_db,
        "sub":  sub_db,
        "subReport": [{"mainField": main_field, "subParam": sub_param, "tableIndex": 1}],
    }, ensure_ascii=False)

    payload = {
        "reportId":   report_id,
        "mainReport": main_db,
        "subReport":  sub_db,
        "linkName":   link_name,
        "parameter":  param_str,
        "linkType":   "4",
    }
    if link_id:
        payload["id"] = link_id

    r = session.request("/link/saveAndEdit", payload)
    return r.get("result", "")


def create_link(
    session: Session,
    report_id: str,
    link_name: str,
    link_type: str,
    parameter_list: list[dict],
    *,
    target_report_id: str = "",
    link_chart_id: str = "",
    api_url: str = "",
    eject_type: str = "0",
) -> str:
    """
    创建钻取/联动配置，返回 linkId。
    link_type: "0"=报表钻取 / "1"=网络链接 / "2"=图表联动
    """
    payload = {
        "linkName":    link_name,
        "linkType":    link_type,
        "reportId":    target_report_id if link_type == "0" else report_id,
        "ejectType":   eject_type,
        "apiUrl":      api_url,
        "apiMethod":   "",
        "requirement": "",
        "linkChartId": link_chart_id,
        "parameter":   json.dumps(parameter_list, ensure_ascii=False),
    }
    r = session.request("/link/saveAndEdit", payload)
    return r["result"]


def parallel_create_links(session: Session, link_configs: list[dict]) -> list[str]:
    with ThreadPoolExecutor(max_workers=len(link_configs)) as ex:
        futures = [ex.submit(create_link, session, **cfg) for cfg in link_configs]
        return [f.result() for f in futures]
