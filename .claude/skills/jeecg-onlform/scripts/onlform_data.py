from typing import Optional
"""
JeecgBoot Online 表单数据 CRUD 工具脚本

用法:
  python onlform_data.py --api-base <URL> --token <TOKEN> --config <config.json>

支持的操作:
  - insert       插入数据记录（单表/主子表）
  - insert_tree  插入树形数据（父优先顺序）
  - query        查询数据列表
  - query_tree   查询树形数据
  - get          获取单条记录
  - update       更新记录（先查后改）
  - delete       删除记录
  - export_csv   导出数据到 CSV
"""

import urllib.request
import json
import sys
import ssl
import csv

# 修复 Windows 控制台中文乱码
sys.stdout.reconfigure(encoding='utf-8')
sys.stderr.reconfigure(encoding='utf-8')
import argparse

# 全局 SSL 上下文（HTTPS 支持）
_ssl_ctx = ssl.create_default_context()
_ssl_ctx.check_hostname = False
_ssl_ctx.verify_mode = ssl.CERT_NONE


# ====== 工具函数 ======

def api_request(api_base: str, token: str, path: str,
                data: Optional[dict] = None, method: str = 'POST') -> dict:
    """发送 API 请求并返回 JSON 响应"""
    url = f'{api_base}{path}'
    # GET 请求加时间戳防缓存
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
    resolved = records[0]['id']
    print(f'已解析 tableName={table_name} -> headId={resolved}')
    return resolved


# ====== Action: insert ======

def action_insert(api_base: str, token: str, config: dict) -> None:
    """插入数据记录（单表 tableType=1 或主子表 tableType=2）"""
    head_id = resolve_head_id(api_base, token, config)
    table_type = config.get('tableType', 1)
    records = config.get('records', [])
    if not records:
        print('错误: records 为空')
        return

    print(f'\n插入数据: headId={head_id}, tableType={table_type}, 共 {len(records)} 条')

    success_count = 0
    fail_count = 0
    for i, record in enumerate(records, 1):
        try:
            result = api_request(
                api_base, token,
                f'/online/cgform/api/form/{head_id}?tabletype={table_type}',
                record
            )
            if result.get('success'):
                success_count += 1
                raw_result = result.get('result', '未知')
                record_id = raw_result.get('id', '未知') if isinstance(raw_result, dict) else raw_result
                print(f'  [{i}/{len(records)}] 插入成功, id={record_id}')
            else:
                fail_count += 1
                print(f'  [{i}/{len(records)}] 插入失败: {result.get("message")}')
        except Exception as e:
            fail_count += 1
            print(f'  [{i}/{len(records)}] 插入异常: {e}')

    print(f'\n插入完成: 成功 {success_count}, 失败 {fail_count}')


# ====== Action: insert_tree ======

def _insert_tree_node(api_base: str, token: str, head_id: str,
                      node: dict, pid: str, depth: int) -> int:
    """递归插入树节点，返回成功插入数量"""
    indent = '  ' * (depth + 1)
    node_data = dict(node.get('data', {}))
    node_data['pid'] = pid

    try:
        result = api_request(
            api_base, token,
            f'/online/cgform/api/form/{head_id}?tabletype=1',
            node_data
        )
    except Exception as e:
        name = node_data.get('name', node_data.get('title', '未知'))
        print(f'{indent}插入失败 [{name}]: {e}')
        return 0

    if not result.get('success'):
        name = node_data.get('name', node_data.get('title', '未知'))
        print(f'{indent}插入失败 [{name}]: {result.get("message")}')
        return 0

    raw_result = result.get('result')
    if isinstance(raw_result, dict):
        new_id = raw_result.get('id', '')
    else:
        new_id = str(raw_result) if raw_result else ''
    name = node_data.get('name', node_data.get('org_name', node_data.get('title', '未知')))
    print(f'{indent}插入成功 [{name}], id={new_id}, pid={pid or "(root)"}')

    count = 1
    for child in node.get('children', []):
        count += _insert_tree_node(api_base, token, head_id, child, new_id, depth + 1)
    return count


def action_insert_tree(api_base: str, token: str, config: dict) -> None:
    """插入树形数据（父优先顺序递归插入）"""
    head_id = resolve_head_id(api_base, token, config)
    nodes = config.get('nodes', [])
    if not nodes:
        print('错误: nodes 为空')
        return

    print(f'\n插入树形数据: headId={head_id}, 根节点数 {len(nodes)}')

    total = 0
    for node in nodes:
        total += _insert_tree_node(api_base, token, head_id, node, '', 0)

    print(f'\n树形插入完成: 共成功 {total} 条')


# ====== Action: query ======

def action_query(api_base: str, token: str, config: dict) -> dict:
    """查询数据列表"""
    head_id = resolve_head_id(api_base, token, config)
    page_no = config.get('pageNo', 1)
    page_size = config.get('pageSize', 10)
    filters = config.get('filters', {})

    params = f'pageNo={page_no}&pageSize={page_size}'
    for key, val in filters.items():
        params += f'&{key}={val}'

    print(f'\n查询数据: headId={head_id}, pageNo={page_no}, pageSize={page_size}')
    if filters:
        print(f'  过滤条件: {filters}')

    result = api_request(
        api_base, token,
        f'/online/cgform/api/getData/{head_id}?{params}',
        method='GET'
    )

    if not result.get('success'):
        print(f'查询失败: {result.get("message")}')
        return result

    data = result.get('result', {})
    records = data.get('records', [])
    total = data.get('total', 0)

    print(f'  总记录数: {total}, 当前页: {len(records)} 条')
    for i, rec in enumerate(records, 1):
        rec_id = rec.get('id', '未知')
        # 显示前几个业务字段
        display_fields = {k: v for k, v in rec.items()
                          if k not in ('id', 'create_by', 'create_time',
                                       'update_by', 'update_time', 'sys_org_code')
                          and not k.endswith('_dictText')}
        preview = dict(list(display_fields.items())[:5])
        print(f'  [{i}] id={rec_id} {preview}')

    return result


# ====== Action: query_tree ======

def action_query_tree(api_base: str, token: str, config: dict) -> dict:
    """查询树形数据"""
    head_id = resolve_head_id(api_base, token, config)
    pid = config.get('pid', '')

    if pid:
        path = f'/online/cgform/api/getTreeData/{head_id}?column=id&order=asc&pid={pid}&has_child=1'
        print(f'\n查询树形子节点: headId={head_id}, pid={pid}')
    else:
        path = f'/online/cgform/api/getTreeData/{head_id}?column=id&order=asc'
        print(f'\n查询树形根节点: headId={head_id}')

    result = api_request(api_base, token, path, method='GET')

    if not result.get('success'):
        print(f'查询失败: {result.get("message")}')
        return result

    records = result.get('result', [])
    print(f'  返回 {len(records)} 条记录')
    for i, rec in enumerate(records, 1):
        rec_id = rec.get('id', '未知')
        name = rec.get('name', rec.get('title', ''))
        has_child = rec.get('has_child', '')
        print(f'  [{i}] id={rec_id}, name={name}, has_child={has_child}')

    return result


# ====== Action: get ======

def action_get(api_base: str, token: str, config: dict) -> dict:
    """获取单条记录"""
    head_id = resolve_head_id(api_base, token, config)
    data_id = config.get('dataId')
    if not data_id:
        print('错误: 必须提供 dataId')
        sys.exit(1)

    print(f'\n获取记录: headId={head_id}, dataId={data_id}')

    result = api_request(
        api_base, token,
        f'/online/cgform/api/form/{head_id}/{data_id}',
        method='GET'
    )

    if not result.get('success'):
        print(f'获取失败: {result.get("message")}')
        return result

    record = result.get('result', {})
    print(f'  记录内容:')
    for key, val in record.items():
        if val is not None and val != '':
            print(f'    {key}: {val}')

    return result


# ====== Action: update ======

def action_update(api_base: str, token: str, config: dict) -> dict:
    """更新记录（先 GET 完整记录，合并变更，再 PUT）"""
    head_id = resolve_head_id(api_base, token, config)
    data_id = config.get('dataId')
    table_type = config.get('tableType', 1)
    update_data = config.get('data', {})

    if not data_id:
        print('错误: 必须提供 dataId')
        sys.exit(1)
    if not update_data:
        print('错误: data 为空，无需更新')
        return {}

    print(f'\n更新记录: headId={head_id}, dataId={data_id}')

    # Step 1: 获取完整记录
    get_result = api_request(
        api_base, token,
        f'/online/cgform/api/form/{head_id}/{data_id}',
        method='GET'
    )
    if not get_result.get('success'):
        print(f'获取原记录失败: {get_result.get("message")}')
        return get_result

    full_record = get_result.get('result', {})
    print(f'  已获取原记录')

    # Step 2: 合并变更（创建新字典，不修改原始数据）
    merged = {**full_record, **update_data}

    print(f'  合并变更字段: {list(update_data.keys())}')

    # Step 3: PUT 更新
    result = api_request(
        api_base, token,
        f'/online/cgform/api/form/{head_id}?tabletype={table_type}',
        merged,
        method='PUT'
    )

    if result.get('success'):
        print(f'  更新成功')
    else:
        print(f'  更新失败: {result.get("message")}')

    return result


# ====== Action: delete ======

def action_delete(api_base: str, token: str, config: dict) -> dict:
    """删除记录"""
    head_id = resolve_head_id(api_base, token, config)
    data_ids = config.get('dataIds', [])
    if not data_ids:
        print('错误: dataIds 为空')
        return {}

    ids_str = ','.join(data_ids)
    print(f'\n删除记录: headId={head_id}, 共 {len(data_ids)} 条')
    print(f'  IDs: {ids_str}')

    result = api_request(
        api_base, token,
        f'/online/cgform/api/form/{head_id}/{ids_str}',
        method='DELETE'
    )

    if result.get('success'):
        print(f'  删除成功')
    else:
        print(f'  删除失败: {result.get("message")}')

    return result


# ====== Action: export_csv ======

def action_export_csv(api_base: str, token: str, config: dict) -> None:
    """导出数据到 CSV 文件"""
    head_id = resolve_head_id(api_base, token, config)
    output_path = config.get('output', 'export.csv')
    page_size = config.get('pageSize', 1000)

    print(f'\n导出 CSV: headId={head_id}, 输出文件={output_path}')

    # Step 1: 获取列定义
    print('  [1/3] 获取列定义...')
    col_result = api_request(
        api_base, token,
        f'/online/cgform/api/getColumns/{head_id}',
        method='GET'
    )
    if not col_result.get('success'):
        print(f'  获取列定义失败: {col_result.get("message")}')
        return

    columns_raw = col_result.get('result', [])
    # 构建列映射: dataIndex -> title
    columns = []
    for col in columns_raw:
        field_name = col.get('dataIndex', col.get('key', ''))
        title = col.get('title', field_name)
        if field_name and title:
            columns.append({'field': field_name, 'title': title})
    print(f'  获取到 {len(columns)} 列')

    # Step 2: 分页获取全部数据
    print('  [2/3] 获取数据...')
    all_records = []
    page_no = 1
    while True:
        data_result = api_request(
            api_base, token,
            f'/online/cgform/api/getData/{head_id}?pageNo={page_no}&pageSize={page_size}',
            method='GET'
        )
        if not data_result.get('success'):
            print(f'  获取第 {page_no} 页失败: {data_result.get("message")}')
            break

        page_data = data_result.get('result', {})
        records = page_data.get('records', [])
        all_records.extend(records)
        total = page_data.get('total', 0)

        print(f'    第 {page_no} 页: {len(records)} 条 (累计 {len(all_records)}/{total})')

        if len(all_records) >= total or not records:
            break
        page_no += 1

    if not all_records:
        print('  无数据可导出')
        return

    # Step 3: 写 CSV（UTF-8-BOM 编码，优先使用 _dictText 字段）
    print(f'  [3/3] 写入 CSV ({len(all_records)} 条)...')

    # 构建最终列列表：优先用 _dictText 版本作为显示值
    final_columns = []
    for col in columns:
        field = col['field']
        dict_field = f'{field}_dictText'
        # 检查数据中是否存在 _dictText 字段
        has_dict = any(dict_field in rec for rec in all_records[:10])
        final_columns.append({
            'field': field,
            'dict_field': dict_field if has_dict else None,
            'title': col['title']
        })

    with open(output_path, 'w', encoding='utf-8-sig', newline='') as f:
        writer = csv.writer(f)
        # 写表头
        writer.writerow([col['title'] for col in final_columns])
        # 写数据
        for rec in all_records:
            row = []
            for col in final_columns:
                # 优先使用 _dictText 值（字典翻译后的显示值）
                if col['dict_field'] and col['dict_field'] in rec:
                    val = rec.get(col['dict_field'], '')
                else:
                    val = rec.get(col['field'], '')
                row.append(val if val is not None else '')
            writer.writerow(row)

    print(f'  导出完成: {output_path}')


# ====== 主入口 ======

ACTION_MAP = {
    'insert': action_insert,
    'insert_tree': action_insert_tree,
    'query': action_query,
    'query_tree': action_query_tree,
    'get': action_get,
    'update': action_update,
    'delete': action_delete,
    'export_csv': action_export_csv,
}


def main() -> None:
    parser = argparse.ArgumentParser(description='JeecgBoot Online 表单数据 CRUD 工具')
    parser.add_argument('--api-base', required=True, help='JeecgBoot 后端地址')
    parser.add_argument('--token', required=True, help='X-Access-Token')
    parser.add_argument('--config', required=True, help='配置文件路径 (JSON)')
    args = parser.parse_args()

    with open(args.config, 'r', encoding='utf-8') as f:
        config = json.load(f)

    action = config.get('action')
    if not action:
        print('错误: 配置文件中必须指定 action')
        sys.exit(1)

    handler = ACTION_MAP.get(action)
    if not handler:
        print(f'错误: 不支持的 action={action}')
        print(f'支持的操作: {", ".join(ACTION_MAP.keys())}')
        sys.exit(1)

    print(f'执行操作: {action}')
    handler(args.api_base, args.token, config)


if __name__ == '__main__':
    main()
