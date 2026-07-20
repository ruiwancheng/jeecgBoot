"""
JeecgBoot Online 表单权限配置工具脚本

用法:
  python onlform_auth.py --api-base <URL> --token <TOKEN> --config <config.json>

支持的操作:
  - setup_field_auth: 配置字段权限（列表/表单/编辑 可见性）
  - setup_button_auth: 配置按钮权限（新增/编辑/删除/导入 等）
  - setup_data_auth: 配置数据权限规则
  - grant_role: 授权角色（字段/按钮/数据权限）
  - query: 查询所有权限配置
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
    table_name = config.get('tableName')
    if head_id:
        return head_id
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


# ====== Action: setup_field_auth ======

def setup_field_auth(api_base: str, token: str, config: dict) -> None:
    """配置字段权限"""
    cgform_id = resolve_head_id(api_base, token, config)
    fields = config.get('fields', [])
    if not fields:
        print('警告: 没有配置任何字段权限')
        return

    print(f'\n{"=" * 50}')
    print(f'配置字段权限: cgformId={cgform_id}')
    print(f'{"=" * 50}')

    for field in fields:
        code = field['code']
        list_show = field.get('listShow', True)
        form_show = field.get('formShow', True)
        form_editable = field.get('formEditable', True)

        print(f'\n  字段: {code}')
        print(f'    listShow={list_show}, formShow={form_show}, formEditable={form_editable}')

        # Step 1: 启用字段权限
        try:
            enable_result = api_request(api_base, token,
                                        '/online/cgform/api/authColumn',
                                        {'cgformId': cgform_id, 'code': code, 'status': 1},
                                        method='PUT')
            print(f'    启用权限: success={enable_result.get("success")}')
        except Exception as e:
            print(f'    启用权限失败: {e}')
            continue

        # Step 2: 配置 switchFlag=1 (列表可见性)
        try:
            r1 = api_request(api_base, token,
                             '/online/cgform/api/authColumn',
                             {'cgformId': cgform_id, 'code': code, 'switchFlag': 1,
                              'listShow': list_show, 'formShow': False, 'formEditable': False})
            print(f'    列表可见(switchFlag=1): success={r1.get("success")}')
        except Exception as e:
            print(f'    列表可见配置失败: {e}')

        # Step 3: 配置 switchFlag=2 (表单可见性)
        try:
            r2 = api_request(api_base, token,
                             '/online/cgform/api/authColumn',
                             {'cgformId': cgform_id, 'code': code, 'switchFlag': 2,
                              'listShow': False, 'formShow': form_show, 'formEditable': False})
            print(f'    表单可见(switchFlag=2): success={r2.get("success")}')
        except Exception as e:
            print(f'    表单可见配置失败: {e}')

        # Step 4: 配置 switchFlag=3 (表单可编辑)
        try:
            r3 = api_request(api_base, token,
                             '/online/cgform/api/authColumn',
                             {'cgformId': cgform_id, 'code': code, 'switchFlag': 3,
                              'listShow': False, 'formShow': False, 'formEditable': form_editable})
            print(f'    表单可编辑(switchFlag=3): success={r3.get("success")}')
        except Exception as e:
            print(f'    表单可编辑配置失败: {e}')

    print(f'\n字段权限配置完成，共处理 {len(fields)} 个字段')


# ====== Action: setup_button_auth ======

def setup_button_auth(api_base: str, token: str, config: dict) -> None:
    """配置按钮权限

    buttons 支持两种格式:
      - 字符串: ["add", "edit", "delete"]  (page 默认 3)
      - 字典:   [{"code": "add", "page": 3}, {"code": "form_confirm", "page": 5}]
    """
    cgform_id = resolve_head_id(api_base, token, config)
    buttons = config.get('buttons', [])
    if not buttons:
        print('警告: 没有配置任何按钮权限')
        return

    print(f'\n{"=" * 50}')
    print(f'配置按钮权限: cgformId={cgform_id}')
    print(f'{"=" * 50}')

    # 查询已启用的按钮，避免重复创建
    existing_codes = set()
    try:
        r = api_request(api_base, token,
                        f'/online/cgform/api/authButton/{cgform_id}?pageNo=1&pageSize=50',
                        method='GET')
        for btn in (r.get('result') or {}).get('authList', []):
            existing_codes.add(btn.get('code'))
    except Exception:
        pass

    ok_count = 0
    skip_count = 0
    for button in buttons:
        # 兼容字符串和字典两种格式
        if isinstance(button, str):
            code, page = button, 3
        else:
            code, page = button['code'], button.get('page', 3)

        if code in existing_codes:
            print(f'  {code}: 已启用，跳过')
            skip_count += 1
            continue

        try:
            payload = {
                'code': code,
                'page': page,
                'cgformId': cgform_id,
                'type': 2,
                'control': 5,
                'status': 1
            }
            result = api_request(api_base, token,
                                 '/online/cgform/api/authButton', payload)
            success = result.get('success')
            print(f'  {code} (page={page}): success={success}, message={result.get("message", "")}')
            if success:
                ok_count += 1
        except Exception as e:
            print(f'  {code} 配置失败: {e}')

    print(f'\n按钮权限配置完成: 新启用 {ok_count}, 已存在跳过 {skip_count}, 共 {len(buttons)} 个')


# ====== Action: setup_data_auth ======

def setup_data_auth(api_base: str, token: str, config: dict) -> None:
    """配置数据权限规则"""
    cgform_id = resolve_head_id(api_base, token, config)
    rules = config.get('rules', [])
    if not rules:
        print('警告: 没有配置任何数据权限规则')
        return

    print(f'\n{"=" * 50}')
    print(f'配置数据权限: cgformId={cgform_id}')
    print(f'{"=" * 50}')

    for rule in rules:
        rule_name = rule.get('ruleName', '')
        try:
            payload = {
                'cgformId': cgform_id,
                'ruleName': rule_name,
                'ruleColumn': rule.get('ruleColumn', ''),
                'ruleOperator': rule.get('ruleOperator', ''),
                'ruleValue': rule.get('ruleValue', ''),
                'status': rule.get('status', 1)
            }
            result = api_request(api_base, token,
                                 '/online/cgform/api/authData', payload)
            print(f'  规则 [{rule_name}]: success={result.get("success")}')
        except Exception as e:
            print(f'  规则 [{rule_name}] 配置失败: {e}')

    print(f'\n数据权限配置完成，共处理 {len(rules)} 条规则')


# ====== Action: grant_role ======

def _fetch_auth_ids(api_base: str, token: str, cgform_id: str, auth_type: str) -> list:
    """根据权限类型自动获取所有权限项 ID"""
    type_page_map = {'field': '1', 'button': '2'}
    if auth_type in type_page_map:
        r = api_request(api_base, token,
                        f'/online/cgform/api/authPage/{cgform_id}/{type_page_map[auth_type]}',
                        method='GET')
        return [item['id'] for item in r.get('result', [])]
    if auth_type == 'data':
        r = api_request(api_base, token,
                        f'/online/cgform/api/validAuthData/{cgform_id}',
                        method='GET')
        return [item['id'] for item in r.get('result', [])]
    return []


def grant_role(api_base: str, token: str, config: dict) -> None:
    """授权角色/部门/用户

    支持两种配置格式:

    格式1 - 单目标 (向后兼容):
      {"action":"grant_role", "tableName":"xxx", "type":"field",
       "roleId":"xxx", "authMode":"role", "authIds":["id1","id2"]}

    格式2 - 批量多目标:
      {"action":"grant_role", "tableName":"xxx", "authType":"field",
       "grants":[
         {"targetId":"role_id", "authMode":"role"},
         {"targetId":"dept_id", "authMode":"depart"},
         {"targetId":"user_id", "authMode":"user"}
       ]}
      authIds 可省略，自动从权限树获取全部已配置的权限项。
    """
    cgform_id = resolve_head_id(api_base, token, config)

    type_path_map = {
        'field': 'roleColumnAuth',
        'button': 'roleButtonAuth',
        'data': 'roleDataAuth'
    }

    # 格式2: 批量多目标
    grants = config.get('grants')
    if grants:
        auth_type = config.get('authType') or config.get('type')
        if not auth_type:
            print('错误: 必须提供 authType (field/button/data)')
            sys.exit(1)
        path_segment = type_path_map.get(auth_type)
        if not path_segment:
            print(f'错误: 未知的权限类型 {auth_type}，支持: field, button, data')
            sys.exit(1)

        # authIds: 优先用配置中指定的，否则自动获取
        auth_ids = config.get('authIds', [])
        if not auth_ids:
            auth_ids = _fetch_auth_ids(api_base, token, cgform_id, auth_type)
            print(f'自动获取 {auth_type} 权限项: {len(auth_ids)} 个')

        print(f'\n{"=" * 50}')
        print(f'批量授权: type={auth_type}, cgformId={cgform_id}')
        print(f'权限项数量={len(auth_ids)}, 授权目标数={len(grants)}')
        print(f'{"=" * 50}')

        for grant in grants:
            target_id = grant['targetId']
            auth_mode = grant.get('authMode', 'role')
            label = grant.get('label', target_id)
            # 每个目标可以指定子集 authIds，否则用全局的
            target_ids = grant.get('authIds', auth_ids)
            try:
                payload = {
                    'authId': json.dumps(target_ids, ensure_ascii=False),
                    'authMode': auth_mode
                }
                result = api_request(api_base, token,
                                     f'/online/cgform/api/{path_segment}/{target_id}/{cgform_id}',
                                     payload)
                print(f'  → {label} ({auth_mode}): success={result.get("success")}, message={result.get("message", "")}')
            except Exception as e:
                print(f'  → {label} ({auth_mode}): 失败 - {e}')

        print(f'\n批量授权完成')
        return

    # 格式1: 单目标 (向后兼容)
    role_id = config.get('roleId')
    auth_mode = config.get('authMode', 'role')
    auth_type = config.get('type')
    auth_ids = config.get('authIds', [])

    if not role_id:
        print('错误: 必须提供 roleId (单目标) 或 grants (批量)')
        sys.exit(1)
    if not auth_type:
        print('错误: 必须提供 type (field/button/data)')
        sys.exit(1)

    path_segment = type_path_map.get(auth_type)
    if not path_segment:
        print(f'错误: 未知的权限类型 {auth_type}，支持: field, button, data')
        sys.exit(1)

    # 自动获取 authIds
    if not auth_ids:
        auth_ids = _fetch_auth_ids(api_base, token, cgform_id, auth_type)
        print(f'自动获取 {auth_type} 权限项: {len(auth_ids)} 个')

    print(f'\n{"=" * 50}')
    print(f'授权: roleId={role_id}, type={auth_type}, authMode={auth_mode}')
    print(f'cgformId={cgform_id}, authIds数量={len(auth_ids)}')
    print(f'{"=" * 50}')

    try:
        payload = {
            'authId': json.dumps(auth_ids, ensure_ascii=False),
            'authMode': auth_mode
        }
        result = api_request(api_base, token,
                             f'/online/cgform/api/{path_segment}/{role_id}/{cgform_id}',
                             payload)
        print(f'  授权结果: success={result.get("success")}, message={result.get("message", "")}')
    except Exception as e:
        print(f'  授权失败: {e}')


# ====== Action: query ======

def query_auth(api_base: str, token: str, config: dict) -> None:
    """查询所有权限配置"""
    cgform_id = resolve_head_id(api_base, token, config)

    print(f'\n{"=" * 50}')
    print(f'查询权限配置: cgformId={cgform_id}')
    print(f'{"=" * 50}')

    # 查询字段权限
    print(f'\n--- 字段权限 ---')
    try:
        result = api_request(api_base, token,
                             f'/online/cgform/api/authColumn/{cgform_id}',
                             method='GET')
        if result.get('success'):
            columns = result.get('result', [])
            if not columns:
                print('  (无字段权限配置)')
            else:
                for col in columns:
                    status = col.get('status', 0)
                    code = col.get('code', col.get('dbFieldName', ''))
                    status_txt = '启用' if status == 1 else '禁用'
                    print(f'  {code}: {status_txt}')
                    if isinstance(col, dict):
                        for key in ['listShow', 'formShow', 'formEditable']:
                            if key in col:
                                print(f'    {key}={col[key]}')
        else:
            print(f'  查询失败: {result.get("message")}')
    except Exception as e:
        print(f'  查询失败: {e}')

    # 查询按钮权限
    print(f'\n--- 按钮权限 ---')
    try:
        result = api_request(api_base, token,
                             f'/online/cgform/api/authButton/{cgform_id}',
                             method='GET')
        if result.get('success'):
            buttons = result.get('result', [])
            if not buttons:
                print('  (无按钮权限配置)')
            else:
                for btn in buttons:
                    code = btn.get('code', btn.get('buttonCode', ''))
                    status = btn.get('status', 0)
                    status_txt = '启用' if status == 1 else '禁用'
                    print(f'  {code}: {status_txt}')
        else:
            print(f'  查询失败: {result.get("message")}')
    except Exception as e:
        print(f'  查询失败: {e}')

    # 查询数据权限
    print(f'\n--- 数据权限 ---')
    try:
        result = api_request(api_base, token,
                             f'/online/cgform/api/authData/{cgform_id}',
                             method='GET')
        if result.get('success'):
            rules = result.get('result', [])
            if not rules:
                print('  (无数据权限配置)')
            else:
                for rule in rules:
                    rule_name = rule.get('ruleName', '')
                    rule_col = rule.get('ruleColumn', '')
                    rule_op = rule.get('ruleOperator', '')
                    rule_val = rule.get('ruleValue', '')
                    status = rule.get('status', 0)
                    status_txt = '启用' if status == 1 else '禁用'
                    rule_id = rule.get('id', '')
                    print(f'  [{rule_name}] {rule_col} {rule_op} {rule_val} ({status_txt}) id={rule_id}')
        else:
            print(f'  查询失败: {result.get("message")}')
    except Exception as e:
        print(f'  查询失败: {e}')

    print(f'\n查询完成')


# ====== 主入口 ======

def main() -> None:
    parser = argparse.ArgumentParser(description='JeecgBoot Online 表单权限配置工具')
    parser.add_argument('--api-base', required=True, help='JeecgBoot 后端地址')
    parser.add_argument('--token', required=True, help='X-Access-Token')
    parser.add_argument('--config', required=True, help='配置文件路径 (JSON)')
    args = parser.parse_args()

    with open(args.config, 'r', encoding='utf-8') as f:
        config = json.load(f)

    action = config.get('action')
    if not action:
        print('错误: 配置文件必须包含 action 字段')
        sys.exit(1)

    action_map = {
        'setup_field_auth': setup_field_auth,
        'setup_button_auth': setup_button_auth,
        'setup_data_auth': setup_data_auth,
        'grant_role': grant_role,
        'query': query_auth,
    }

    handler = action_map.get(action)
    if not handler:
        print(f'错误: 未知操作 {action}，支持: {", ".join(action_map.keys())}')
        sys.exit(1)

    handler(args.api_base, args.token, config)


if __name__ == '__main__':
    main()
