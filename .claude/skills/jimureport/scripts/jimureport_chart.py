"""
jimureport_chart.py — 图表构建、布局、更新、数据回填
"""
import json
import copy
from collections import OrderedDict
from concurrent.futures import ThreadPoolExecutor

from jimureport_core import Session, col_letter
from jimureport_report import get_report, base_save


def pick_chart_axes(field_list: list[dict]) -> tuple[str, str]:
    """
    从 parse_api / parse_sql 返回的 field_list 中自动选出 (axis_x, axis_y)。
    优先按字段名语义关键词匹配，避免按 widgetType 猜测选错 ID/日期字段。
    返回 (类别字段名, 数值字段名)。
    """
    LABEL_KW = ("name", "product", "category", "type", "spec", "title", "label", "item", "goods")
    VALUE_KW = ("price", "amount", "total", "count", "qty", "value", "num", "sum", "sales", "revenue")

    names = [f["fieldName"] for f in field_list]

    axis_x = next(
        (n for kw in LABEL_KW for n in names if kw in n.lower()),
        names[0],
    )
    axis_y = next(
        (n for kw in VALUE_KW for n in names if kw in n.lower() and n != axis_x),
        next((n for n in names if n != axis_x), names[-1]),
    )
    return axis_x, axis_y


def chart_entry(
    layer_id: str,
    db_id: str,
    db_code: str,
    chart_type: str,
    echarts_cfg: dict,
    row: int,
    col: int = 1,
    col_end: int = 6,
    width: str = "580",
    height: str = "320",
    link_ids: str = "",
    axis_x: str = "name",
    axis_y: str = "value",
    series: str = "",
    api_status: str = "1",
    data_type: str = "sql",
    is_custom_prop: bool = False,
    x_text: str = "",
    y_text: str = "",
) -> dict:
    # API 数据集且字段名非默认 name/value 时自动开启自定义属性
    if data_type == "api" and (axis_x != "name" or axis_y != "value"):
        is_custom_prop = True
        x_text = x_text or axis_x
        y_text = y_text or axis_y
    return {
        "row":    row,
        "col":    col,
        "width":  width,
        "height": height,
        "config": json.dumps(echarts_cfg, ensure_ascii=False),
        "url":    "",
        "extData": {
            "chartId": layer_id,
            "id":      layer_id,
            "chartType":  chart_type,
            "dataType":   data_type,
            "apiStatus":  api_status,
            "dataId":     db_id,
            "dataId1":    "",
            "dbCode":     db_code,
            "axisX":      axis_x,
            "axisY":      axis_y,
            "series":     series,
            "xText": x_text, "yText": y_text,
            "linkIds":    link_ids,
            "source": "", "target": "",
            "isTiming": "", "intervalTime": "",
            "isCustomPropName": is_custom_prop,
        },
        "layer_id": layer_id,
        "virtualCellRange": [[row, c] for c in range(col, col_end + 1)],
        "backgroud": {"enabled": False, "color": "#fff", "image": ""},
        "colspan":  col_end - col + 1,
        "rowspan":  14,
        "offsetX":  0,
        "offsetY":  0,
    }


def virtual_row(layer_id: str, col_start: int = 1, col_end: int = 6) -> dict:
    return {"cells": {str(c): {"text": " ", "virtual": layer_id}
                      for c in range(col_start, col_end + 1)}}


def build_chart_layout(
    report_name: str,
    layer_configs: list[dict],
    col_end: int = 9,
) -> tuple[dict, dict, list, list]:
    """
    构建标准图表布局（标题行 + 图表虚拟占位行），返回 (rows, cols, styles, merges)。
    layer_configs: [{"layer_id": str, "row": int, "span": int}, ...]
    """
    styles = [
        {"align": "center"},
        {"align": "center", "font": {"size": 14}},
        {"font": {"size": 14}},
        {"align": "center", "font": {"size": 14, "bold": True}},
        {"font": {"size": 14, "bold": True}},
    ]

    title_cells = {"1": {"merge": [0, col_end - 1], "text": report_name, "style": 3}}
    for c in range(2, col_end + 1):
        title_cells[str(c)] = {"style": 4}

    rows: dict = {"0": {"cells": title_cells, "height": 50}, "len": 200}

    for cfg in layer_configs:
        lid, row = cfg["layer_id"], cfg["row"]
        rows[str(row)] = {
            "cells": {str(c): {"text": " ", "virtual": lid}
                      for c in range(1, col_end + 1)}
        }

    if layer_configs:
        last = max(layer_configs, key=lambda c: c["row"])
        end_row = last["row"] + last.get("span", 16)
        rows[str(end_row)] = {"cells": {"1": {"text": " "}}}

    cols = {
        "0": {"width": 20},
        **{str(i): {"width": 100} for i in range(1, col_end + 1)},
        "len": 100,
    }

    return rows, cols, styles, [f"B1:{col_letter(col_end)}1"]


def update_chart_config(
    session: Session,
    report_id: str,
    updater_fn,
    *,
    chart_index: int | None = None,
    chart_type_filter: str = "",
) -> int:
    """
    通用图表配置更新：get_report → updater_fn 修改 config → save。
    updater_fn(config: dict, chart_type: str) -> bool
    返回实际更新的图表数量。
    """
    designer, design = get_report(session, report_id)
    chart_list = design.get("chartList", [])
    if not chart_list:
        raise RuntimeError("报表没有图表组件")

    updated = 0
    for idx, chart in enumerate(chart_list):
        if chart_index is not None and idx != chart_index:
            continue
        ct = chart.get("extData", {}).get("chartType", "")
        if chart_type_filter and ct != chart_type_filter:
            continue
        config = json.loads(chart.get("config", "{}"))
        if updater_fn(config, ct):
            chart["config"] = json.dumps(config, ensure_ascii=False)
            updated += 1

    if updated:
        session.request("/save", base_save(report_id, designer, **design))
    return updated


def parallel_fill_charts(session: Session, charts: list[dict],
                          json_records_map: dict | None = None) -> list[dict]:
    """
    并行回填 chartList 里的 SQL/API/JSON 图表数据（原地修改 + 返回列表）。
    支持单系列、多系列、横向图、饼图/漏斗/仪表盘。并发上限 10。

    json_records_map: {dbCode: [records]} — JSON 数据集（dbType=3）图表的本地填充数据。
        parallel_fill_charts 对 JSON 数据集没有服务端查询接口，需调用方传入原始 records。
        示例：json_records_map={"myDs": [{"name":"一月","value":120}, ...]}
        未传或 dbCode 不在 map 中时，JSON 数据集图表保持原样（config 不变）。
    """
    def _fill_one(chart: dict) -> dict:
        ext = chart.get("extData", {})
        data_type = ext.get("dataType")
        data_id = ext.get("dataId")
        db_code = ext.get("dbCode", "")

        # JSON 数据集：使用调用方传入的本地 records 直接填充，无需查询服务端
        if data_type == "json" and json_records_map and db_code in json_records_map:
            rows = json_records_map[db_code]
        elif data_type not in ("sql", "api") or not data_id:
            return chart
        else:
            payload = {
                "apiSelectId": data_id,
                "chartSetting": {
                    "chartId": ext.get("chartId", ""), "id": ext.get("chartId", ""),
                    "chartType": ext.get("chartType", ""), "dataType": data_type,
                    "apiStatus": ext.get("apiStatus", "1"), "dataId": data_id,
                    "dataId1": "", "dbCode": db_code,
                    "axisX": ext.get("axisX", "name"), "axisY": ext.get("axisY", "value"),
                    "series": ext.get("series", ""),
                    "xText": ext.get("xText", ""), "yText": ext.get("yText", ""),
                    "linkIds": "", "source": "", "target": "", "isTiming": "", "intervalTime": "",
                    "isCustomPropName": ext.get("isCustomPropName", False), "run": 1,
                },
            }
            if data_type == "api":
                result = session.request("/qurestApi", payload)["result"]
                rows = result.get("data") if isinstance(result, dict) else result
            else:
                rows = session.request("/qurestSql", payload)["result"]
        if not rows:
            return chart

        cfg = json.loads(chart["config"])
        axis_x = ext.get("axisX", "name")
        axis_y = ext.get("axisY", "value")
        series_fld = ext.get("series", "")

        if series_fld:
            x_seen = OrderedDict()
            for r in rows:
                x_seen[r[axis_x]] = None
            x_data = list(x_seen.keys())
            smap = OrderedDict()
            for r in rows:
                t = r[series_fld]
                smap.setdefault(t, {})[r[axis_x]] = r[axis_y]
            series_names = list(smap.keys())
            for t in smap:
                smap[t] = [smap[t].get(x) for x in x_data]
            if isinstance(cfg.get("xAxis"), dict):
                cfg["xAxis"]["data"] = x_data
            elif isinstance(cfg.get("yAxis"), dict):
                cfg["yAxis"]["data"] = x_data
            if isinstance(cfg.get("legend"), dict):
                cfg["legend"]["data"] = series_names
            orig = {s.get("name", ""): s for s in cfg.get("series", [])}
            template = cfg["series"][0] if cfg.get("series") else {}
            new_series = []
            for sname in series_names:
                tmpl = copy.deepcopy(orig.get(sname, template))
                tmpl["name"] = sname
                tmpl["data"] = smap[sname]
                tmpl.setdefault("typeData", [])
                new_series.append(tmpl)
            cfg["series"] = new_series
        else:
            if rows and isinstance(rows[0], dict) and axis_x in rows[0] and axis_y in rows[0]:
                x_data = [r[axis_x] for r in rows]
                y_data = [r[axis_y] for r in rows]
            else:
                x_data = y_data = []
            if not cfg.get("xAxis") and not cfg.get("yAxis"):
                if cfg.get("series"):
                    cfg["series"][0]["data"] = [
                        {"name": n, "value": v, "itemStyle": {"color": None}}
                        for n, v in zip(x_data, y_data)
                    ]
            else:
                # 优先正向判断：yAxis 是分类轴（横向图/象形图）→ 更新 yAxis.data
                # 避免依赖 xAxis.type 缺省时的负向判断导致误填
                if isinstance(cfg.get("yAxis"), dict) and cfg["yAxis"].get("type") == "category":
                    cfg["yAxis"]["data"] = x_data
                elif isinstance(cfg.get("xAxis"), dict) and cfg["xAxis"].get("type") != "value":
                    cfg["xAxis"]["data"] = x_data
                if cfg.get("series"):
                    cfg["series"][0]["data"] = y_data

        chart["config"] = json.dumps(cfg, ensure_ascii=False)
        return chart

    with ThreadPoolExecutor(max_workers=10) as ex:
        list(ex.map(_fill_one, charts))
    return charts
