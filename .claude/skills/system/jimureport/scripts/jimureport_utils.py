"""
jimureport_utils.py — 向后兼容的全量导出
旧脚本继续 `from jimureport_utils import *` 无需修改。
新脚本推荐按需从各子模块导入，AI 按需读取对应文件：
  jimureport_core.py        Session、签名、gen_id/code/layer、col_letter
  jimureport_dataset.py     parse_api/sql、save_db、update_db、parse_and_save_dataset、parallel_*
  jimureport_report.py      make_designer、base_save、get_report、report_urls、print_summary
  jimureport_styles.py      make_styles
  jimureport_chart.py       chart_entry、virtual_row、build_chart_layout、update_chart_config、parallel_fill_charts
  jimureport_link.py        create_link、parallel_create_links、save_mastersub_link
  jimureport_datasource.py  resolve_db_source、ensure_datasource、find_datasource、get_ds_connection、query_mysql
"""
from jimureport_core import (
    Session, _compute_sign, gen_id, gen_code, gen_layer, col_letter,
    DEFAULT_BASE_URL, DEFAULT_TOKEN, DEFAULT_TENANT, SIGN_SECRET, SIGNED_PATHS,
)
from jimureport_dataset import (
    parse_api, parse_sql, save_db, update_db, parse_and_save_dataset,
    parallel_parse_sqls, parallel_save_dbs, parallel_parse_apis,
)
from jimureport_report import (
    report_urls, make_designer, base_save, get_report,
    parallel_init_and_parse, print_summary,
)
from jimureport_styles import make_styles, STYLE_BASE, STYLE_DATA, STYLE_HEADER, STYLE_TITLE, STYLE_LINK
from jimureport_chart import (
    chart_entry, virtual_row, build_chart_layout,
    update_chart_config, parallel_fill_charts,
)
from jimureport_link import create_link, parallel_create_links, save_mastersub_link
from jimureport_datasource import (
    resolve_db_source, find_datasource, ensure_datasource, get_ds_connection, query_mysql,
    execute_ds,
)

__all__ = [
    "Session", "gen_id", "gen_code", "gen_layer", "col_letter",
    "DEFAULT_BASE_URL", "DEFAULT_TOKEN", "DEFAULT_TENANT",
    "parse_api", "parse_sql", "save_db", "update_db", "parse_and_save_dataset",
    "parallel_parse_sqls", "parallel_save_dbs", "parallel_parse_apis",
    "report_urls", "make_designer", "base_save", "get_report",
    "parallel_init_and_parse", "print_summary",
    "make_styles", "STYLE_BASE", "STYLE_DATA", "STYLE_HEADER", "STYLE_TITLE", "STYLE_LINK",
    "chart_entry", "virtual_row", "build_chart_layout",
    "update_chart_config", "parallel_fill_charts",
    "create_link", "parallel_create_links",
    "resolve_db_source", "find_datasource", "ensure_datasource", "get_ds_connection", "query_mysql",
    "execute_ds",
]
