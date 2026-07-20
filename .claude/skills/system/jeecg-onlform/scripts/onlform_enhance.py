"""
JeecgBoot Online 表单增强工具脚本

用法:
  python onlform_enhance.py --api-base <URL> --token <TOKEN> --config <config.json>

支持的操作:
  - create_buttons: 创建自定义按钮
  - save_js: 保存JS增强（form/list）
  - save_java: 保存Java增强
  - save_sql: 保存SQL增强
  - query: 查询表单所有增强配置
"""

import urllib.request
import json
import sys
import ssl
import argparse

# 修复 Windows 控制台中文乱码
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')

# 全局 SSL 上下文（HTTPS 支持）
_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE


# ====== 工具函数 ======

def api_request(api_base: str, token: str, path: str, data=None, method: str = 'POST') -> dict:
    url = f'{api_base}{path}'
    if method == 'GET':
        import time as _time
        sep = '&' if '?' in url else '?'
        url += f'{sep}_t={int(_time.time() * 1000)}'
    headers = {
        'X-Access-Token': token,
        'Content-Type': 'application/json; charset=UTF-8'
    }
    if data is not None:
        json_data = json.dumps(data, ensure_ascii=False).encode('utf-8')
        req = urllib.request.Request(url, data=json_data, headers=headers, method=method)
    else:
        req = urllib.request.Request(url, headers=headers, method=method)
    resp = urllib.request.urlopen(req, context=_ssl_ctx)
    return json.loads(resp.read().decode('utf-8'))


def resolve_head_id(api_base: str, token: str, config: dict) -> str:
    """从 headId 或 tableName 解析出 headId"""
    head_id = config.get('headId')
    if head_id:
        return head_id
    table_name = config.get('tableName')
    if not table_name:
        print('错误: 必须提供 headId 或 tableName')
        sys.exit(1)
    result = api_request(api_base, token,
                         f'/online/cgform/head/list?tableName={table_name}&copyType=0&pageNo=1&pageSize=1',
                         method='GET')
    records = (result.get('result') or {}).get('records', [])
    if not records:
        print(f'错误: 表 {table_name} 不存在')
        sys.exit(1)
    head_id = records[0]['id']
    print(f'已解析 tableName={table_name} -> headId={head_id}')
    return head_id


# ====== Action: create_buttons ======

def action_create_buttons(api_base: str, token: str, config: dict) -> None:
    head_id = resolve_head_id(api_base, token, config)
    buttons = config.get('buttons', [])
    if not buttons:
        print('错误: buttons 列表为空')
        return

    print(f'\n{"=" * 50}')
    print(f'创建自定义按钮 (共 {len(buttons)} 个)')
    print(f'{"=" * 50}')

    button_list = []
    for btn in buttons:
        button_obj = {
            "cgformHeadId": head_id,
            "buttonCode": btn['buttonCode'],
            "buttonName": btn['buttonName'],
            "buttonStyle": btn.get('buttonStyle', 'button'),
            "optType": btn.get('optType', 'js'),
            "orderNum": btn.get('orderNum', 1),
            "buttonStatus": btn.get('buttonStatus', '1'),
            "optPosition": btn.get('optPosition', '2'),
        }
        # 可选字段透传
        for key in ('exp', 'buttonIcon'):
            if key in btn:
                button_obj[key] = btn[key]
        button_list.append(button_obj)
        print(f'  准备按钮: {btn["buttonCode"]} ({btn["buttonName"]})')

    result = api_request(api_base, token, '/online/cgform/button/aitest', button_list)
    print(f'创建结果: success={result.get("success")}, message={result.get("message")}')

    if result.get('success'):
        print(f'成功创建 {len(buttons)} 个按钮')
    else:
        print(f'创建失败: {result.get("message")}')


# ====== Action: save_js ======

def action_save_js(api_base: str, token: str, config: dict) -> None:
    head_id = resolve_head_id(api_base, token, config)
    cg_js_type = config.get('cgJsType', 'form')
    cg_js = config.get('cgJs', '')

    if not cg_js:
        print('错误: cgJs 内容为空')
        return

    print(f'\n{"=" * 50}')
    print(f'保存JS增强 (类型: {cg_js_type})')
    print(f'{"=" * 50}')

    # 查询是否已存在
    existing = api_request(api_base, token,
                           f'/online/cgform/head/enhanceJs/{head_id}?type={cg_js_type}',
                           method='GET')

    body = {
        "cgJs": cg_js,
        "cgformHeadId": head_id,
        "cgJsType": cg_js_type,
    }

    existing_record = existing.get('result')
    if existing_record and isinstance(existing_record, dict) and existing_record.get('id'):
        # 已存在，使用 PUT 更新
        body['id'] = existing_record['id']
        print(f'  已存在JS增强 (id={existing_record["id"]})，执行更新...')
        result = api_request(api_base, token,
                             f'/online/cgform/head/enhanceJs/{head_id}',
                             body, method='PUT')
    else:
        # 不存在，使用 POST 创建
        print('  JS增强不存在，执行创建...')
        result = api_request(api_base, token,
                             f'/online/cgform/head/enhanceJs/{head_id}',
                             body, method='POST')

    print(f'保存结果: success={result.get("success")}, message={result.get("message")}')


# ====== Action: save_java ======

def action_save_java(api_base: str, token: str, config: dict) -> None:
    head_id = resolve_head_id(api_base, token, config)
    enhancements = config.get('enhancements', [])
    if not enhancements:
        print('错误: enhancements 列表为空')
        return

    print(f'\n{"=" * 50}')
    print(f'保存Java增强 (共 {len(enhancements)} 条)')
    print(f'{"=" * 50}')

    # 查询已有的Java增强
    existing = api_request(api_base, token,
                           f'/online/cgform/head/enhanceJava/{head_id}',
                           method='GET')
    existing_list = existing.get('result', [])
    if not isinstance(existing_list, list):
        existing_list = []

    # 构建 buttonCode+event -> existing record 映射
    existing_map = {}
    for rec in existing_list:
        key = f'{rec.get("buttonCode")}_{rec.get("event")}'
        existing_map[key] = rec

    for enh in enhancements:
        body = {
            "cgformHeadId": head_id,
            "buttonCode": enh['buttonCode'],
            "event": enh.get('event', 'start'),
            "cgJavaType": enh.get('cgJavaType', 'http-api'),
            "cgJavaValue": enh.get('cgJavaValue', ''),
            "activeStatus": enh.get('activeStatus', '1'),
        }

        key = f'{enh["buttonCode"]}_{enh.get("event", "start")}'
        if key in existing_map:
            body['id'] = existing_map[key]['id']
            print(f'  更新Java增强: {enh["buttonCode"]} ({enh.get("event", "start")})')
            result = api_request(api_base, token,
                                 f'/online/cgform/head/enhanceJava/{head_id}',
                                 body, method='PUT')
        else:
            print(f'  创建Java增强: {enh["buttonCode"]} ({enh.get("event", "start")})')
            result = api_request(api_base, token,
                                 f'/online/cgform/head/enhanceJava/{head_id}',
                                 body, method='POST')

        print(f'    结果: success={result.get("success")}, message={result.get("message")}')


# ====== Action: save_sql ======

def action_save_sql(api_base: str, token: str, config: dict) -> None:
    head_id = resolve_head_id(api_base, token, config)
    enhancements = config.get('enhancements', [])
    if not enhancements:
        print('错误: enhancements 列表为空')
        return

    print(f'\n{"=" * 50}')
    print(f'保存SQL增强 (共 {len(enhancements)} 条)')
    print(f'{"=" * 50}')

    # 查询已有的SQL增强
    existing = api_request(api_base, token,
                           f'/online/cgform/head/enhanceSql/{head_id}',
                           method='GET')
    existing_list = existing.get('result', [])
    if not isinstance(existing_list, list):
        existing_list = []

    # 构建 buttonCode -> existing record 映射
    existing_map = {}
    for rec in existing_list:
        existing_map[rec.get('buttonCode', '')] = rec

    for enh in enhancements:
        body = {
            "cgformHeadId": head_id,
            "buttonCode": enh['buttonCode'],
            "cgbSql": enh.get('cgbSql', ''),
            "content": enh.get('content', ''),
        }
        # 可选字段透传
        for key in ('cgbSqlName', 'cgOrderNum'):
            if key in enh:
                body[key] = enh[key]

        if enh['buttonCode'] in existing_map:
            body['id'] = existing_map[enh['buttonCode']]['id']
            print(f'  更新SQL增强: {enh["buttonCode"]}')
            result = api_request(api_base, token,
                                 f'/online/cgform/head/enhanceSql/{head_id}',
                                 body, method='PUT')
        else:
            print(f'  创建SQL增强: {enh["buttonCode"]}')
            result = api_request(api_base, token,
                                 f'/online/cgform/head/enhanceSql/{head_id}',
                                 body, method='POST')

        print(f'    结果: success={result.get("success")}, message={result.get("message")}')


# ====== Action: query ======

def action_query(api_base: str, token: str, config: dict) -> None:
    head_id = resolve_head_id(api_base, token, config)
    table_name = config.get('tableName', head_id)

    print(f'\n{"=" * 50}')
    print(f'查询增强配置: {table_name} (headId={head_id})')
    print(f'{"=" * 50}')

    # 查询按钮
    print(f'\n--- 自定义按钮 ---')
    try:
        btn_result = api_request(api_base, token,
                                 f'/online/cgform/button/list?headId={head_id}&pageNo=1&pageSize=100',
                                 method='GET')
        buttons = (btn_result.get('result') or {}).get('records', [])
        if not buttons:
            print('  (无)')
        else:
            for btn in buttons:
                print(f'  [{btn.get("buttonCode")}] {btn.get("buttonName")} '
                      f'style={btn.get("buttonStyle")} optType={btn.get("optType")} '
                      f'status={btn.get("buttonStatus")} order={btn.get("orderNum")}')
    except Exception as e:
        print(f'  查询失败: {e}')

    # 查询JS增强 (form)
    print(f'\n--- JS增强 (form) ---')
    try:
        js_form = api_request(api_base, token,
                              f'/online/cgform/head/enhanceJs/{head_id}?type=form',
                              method='GET')
        js_record = js_form.get('result')
        if js_record and isinstance(js_record, dict) and js_record.get('cgJs'):
            js_content = js_record['cgJs']
            preview = js_content[:200] + ('...' if len(js_content) > 200 else '')
            print(f'  id={js_record.get("id")}')
            print(f'  内容预览: {preview}')
        else:
            print('  (无)')
    except Exception as e:
        print(f'  查询失败: {e}')

    # 查询JS增强 (list)
    print(f'\n--- JS增强 (list) ---')
    try:
        js_list = api_request(api_base, token,
                              f'/online/cgform/head/enhanceJs/{head_id}?type=list',
                              method='GET')
        js_record = js_list.get('result')
        if js_record and isinstance(js_record, dict) and js_record.get('cgJs'):
            js_content = js_record['cgJs']
            preview = js_content[:200] + ('...' if len(js_content) > 200 else '')
            print(f'  id={js_record.get("id")}')
            print(f'  内容预览: {preview}')
        else:
            print('  (无)')
    except Exception as e:
        print(f'  查询失败: {e}')

    # 查询Java增强
    print(f'\n--- Java增强 ---')
    try:
        java_result = api_request(api_base, token,
                                  f'/online/cgform/head/enhanceJava/{head_id}',
                                  method='GET')
        java_list = java_result.get('result', [])
        if not java_list or not isinstance(java_list, list):
            print('  (无)')
        else:
            for j in java_list:
                print(f'  [{j.get("buttonCode")}] event={j.get("event")} '
                      f'type={j.get("cgJavaType")} value={j.get("cgJavaValue")} '
                      f'status={j.get("activeStatus")}')
    except Exception as e:
        print(f'  查询失败: {e}')

    # 查询SQL增强
    print(f'\n--- SQL增强 ---')
    try:
        sql_result = api_request(api_base, token,
                                 f'/online/cgform/head/enhanceSql/{head_id}',
                                 method='GET')
        sql_list = sql_result.get('result', [])
        if not sql_list or not isinstance(sql_list, list):
            print('  (无)')
        else:
            for s in sql_list:
                sql_preview = (s.get('cgbSql', '') or '')[:100]
                print(f'  [{s.get("buttonCode")}] content={s.get("content")} '
                      f'sql={sql_preview}')
    except Exception as e:
        print(f'  查询失败: {e}')


# ====== Action 分发 ======

ACTION_MAP = {
    'create_buttons': action_create_buttons,
    'save_js': action_save_js,
    'save_java': action_save_java,
    'save_sql': action_save_sql,
    'query': action_query,
}


def main() -> None:
    parser = argparse.ArgumentParser(description='JeecgBoot Online 表单增强工具')
    parser.add_argument('--api-base', required=True, help='JeecgBoot 后端地址')
    parser.add_argument('--token', required=True, help='X-Access-Token')
    parser.add_argument('--config', required=True, help='配置文件路径 (JSON)')
    args = parser.parse_args()

    with open(args.config, 'r', encoding='utf-8') as f:
        config = json.load(f)

    action = config.get('action')
    if not action:
        print('错误: 配置文件必须包含 action 字段')
        print(f'支持的操作: {", ".join(ACTION_MAP.keys())}')
        sys.exit(1)

    handler = ACTION_MAP.get(action)
    if not handler:
        print(f'错误: 未知操作类型 "{action}"')
        print(f'支持的操作: {", ".join(ACTION_MAP.keys())}')
        sys.exit(1)

    try:
        handler(args.api_base, args.token, config)
    except urllib.error.HTTPError as e:
        print(f'HTTP 错误: {e.code} {e.reason}')
        try:
            body = e.read().decode('utf-8')
            print(f'响应内容: {body}')
        except Exception:
            pass
        sys.exit(1)
    except urllib.error.URLError as e:
        print(f'网络错误: {e.reason}')
        sys.exit(1)
    except Exception as e:
        print(f'错误: {e}')
        sys.exit(1)

    print('\n操作完成!')


if __name__ == '__main__':
    main()
