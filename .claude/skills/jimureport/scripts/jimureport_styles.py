"""
jimureport_styles.py — 样式预设
"""

STYLE_BASE   = 0  # 基础边框
STYLE_DATA   = 1  # 数据行（居中+垂直居中）
STYLE_HEADER = 2  # 表头（蓝底白字）
STYLE_TITLE  = 3  # 大标题（淡蓝底深蓝加粗）
STYLE_LINK   = 4  # 链接/钻取列（蓝色字体）


def make_styles(border_color: str = "#d8d8d8") -> list[dict]:
    """
    标准5种样式（索引 0-4）：
      0 = 基础边框
      1 = 居中+垂直居中（数据行）
      2 = 蓝底白字（表头）
      3 = 淡蓝底深蓝加粗（标题）
      4 = 蓝色字体（链接/钻取列）
    """
    b = lambda: {"bottom": ["thin", border_color], "top": ["thin", border_color],
                 "left":   ["thin", border_color], "right": ["thin", border_color]}
    return [
        {"border": b()},
        {"border": b(), "align": "center", "valign": "middle"},
        {"border": b(), "align": "center", "valign": "middle",
         "bgcolor": "#01b0f1", "color": "#ffffff"},
        {"border": b(), "align": "center", "valign": "middle",
         "bgcolor": "#E6F2FF", "color": "#0066CC", "font": {"bold": True, "size": 14}},
        {"border": b(), "align": "center", "valign": "middle", "color": "#1677ff"},
    ]
