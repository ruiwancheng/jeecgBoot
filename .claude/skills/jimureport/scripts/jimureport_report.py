"""
jimureport_report.py — 报表创建/读取/保存（make_designer / base_save / get_report）
"""
import json
from concurrent.futures import ThreadPoolExecutor

from jimureport_core import Session, gen_code, DEFAULT_BASE_URL, DEFAULT_TOKEN, DEFAULT_TENANT


def report_urls(report_id: str, base_url: str = DEFAULT_BASE_URL,
                token: str = DEFAULT_TOKEN, tenant: str = DEFAULT_TENANT) -> tuple[str, str]:
    """返回 (preview_url, design_url)。"""
    host = base_url.removesuffix("/jmreport").rstrip("/")
    qs   = f"token={token}&tenantId={tenant}"
    return (
        f"{host}/jmreport/view/{report_id}?{qs}",
        f"{host}/jmreport/index/{report_id}?{qs}",
    )


def make_designer(report_id: str, name: str, **extra) -> dict:
    return {
        "id":          report_id,
        "code":        gen_code(),
        "name":        name,
        "reportName":  name,
        "type":        "0",
        "template":    0,
        "delFlag":     0,
        "viewCount":   0,
        "updateCount": 0,
        "submitForm":  0,
        **extra,
    }


def base_save(report_id: str, designer_obj: dict, **overrides) -> dict:
    """
    构造 /jmreport/save 请求体。
    只有 designerObj 会被 json.dumps；其他字段保持原始 Python 对象。
    """
    payload: dict = {
        "designerObj":  json.dumps(designer_obj, ensure_ascii=False),
        "name":         "sheet1",
        "sheetId":      "default",
        "sheetName":    "默认Sheet",
        "sheetOrder":   "0",
        "freeze":       "A1",
        "freezeLineColor": "rgb(185, 185, 185)",
        "excel_config_id": report_id,
        "rows":         {"len": 200},
        "cols":         {"len": 100},
        "styles":       [],
        "merges":       [],
        "chartList":    [],
        "imgList":      [],
        "barcodeList":  [],
        "qrcodeList":   [],
        "loopBlockList":    [],
        "zonedEditionList": [],
        "fixedPrintHeadRows": [],
        "fixedPrintTailRows": [],
        "hiddenCells":    [],
        "submitHandlers": [],
        "validations":    [],
        "autofilter":     {},
        "dbexps":         [],
        "dicts":          [],
        "displayConfig":  {},
        "printConfig": {
            "paper": "A4", "width": 210, "height": 297, "definition": 1,
            "isBackend": False, "marginX": 10, "marginY": 10,
            "layout": "portrait", "printCallBackUrl": "",
        },
        "querySetting":      {"izOpenQueryBar": False, "izDefaultQuery": True},
        "queryFormSetting":  {"useQueryForm": False, "dbKey": "", "idField": ""},
        "rpbar": {"show": True, "pageSize": "", "btnList": []},
        "fillFormToolbar": {"show": True, "btnList": [
            "save", "subTable_add", "verify", "subTable_del", "print", "close",
            "first", "prev", "next", "paging", "total", "last",
            "exportPDF", "exportExcel", "exportWord",
        ]},
        "hidden": {"rows": [], "cols": [], "conditions": {"rows": {}, "cols": {}}},
        "fillFormInfo":   {"layout": {"direction": "horizontal", "width": 200, "height": 45}},
        "recordSubTableOrCollection": {"group": [], "record": [], "range": []},
        "area":             False,
        "background":       False,
        "pyGroupEngine":    False,
        "isViewContentHorizontalCenter": False,
        "fillFormStyle":    "default",
        "dataRectWidth":    700,
    }
    payload.update(overrides)
    return payload


def get_report(session: Session, report_id: str) -> tuple[dict, dict]:
    """
    获取报表设计，返回 (designer_obj, design)。
    design 可直接 **展开传给 base_save。
    """
    r = session.get(f"/get/{report_id}")
    result = r["result"]
    json_str = result.get("jsonStr", "{}")
    design = json.loads(json_str) if isinstance(json_str, str) else (json_str or {})
    designer_obj = {
        "id":          result["id"],
        "code":        result.get("code", ""),
        "name":        result.get("name", ""),
        "reportName":  result.get("name", ""),
        "type":        result.get("reportType", result.get("type", "0")),
        "template":    result.get("template", 0),
        "delFlag":     result.get("delFlag", 0),
        "viewCount":   result.get("viewCount", 0),
        "updateCount": result.get("updateCount", 0),
        "submitForm":  result.get("submitForm", 0),
        "cssStr":      result.get("cssStr", ""),
        "jsStr":       result.get("jsStr", ""),
    }
    return designer_obj, design


def parallel_init_and_parse(
    session: Session,
    report_id: str,
    designer_obj: dict,
    sql: str,
    db_source: str = "",
    **save_overrides,
) -> list[dict]:
    """⚠️ 已不推荐。保留供旧脚本兼容。新脚本请用 parse_and_save_dataset。"""
    from jimureport_dataset import parse_sql
    with ThreadPoolExecutor(max_workers=2) as ex:
        save_fut  = ex.submit(
            session.request, "/save",
            base_save(report_id, designer_obj, **save_overrides)
        )
        parse_fut = ex.submit(parse_sql, session, sql, db_source)
        save_fut.result()
        return parse_fut.result()


def print_summary(report_id: str, report_name: str,
                  base_url: str = DEFAULT_BASE_URL, token: str = DEFAULT_TOKEN):
    preview, design = report_urls(report_id, base_url, token)
    print(f"\n{'=' * 50}")
    print(f"报表创建成功: {report_name}")
    print(f"  report_id:  {report_id}")
    print(f"  预览地址:   {preview}")
    print(f"  设计器地址: {design}")
    print(f"{'=' * 50}")
