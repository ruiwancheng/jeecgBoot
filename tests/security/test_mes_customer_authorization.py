"""
回归测试: 验证 MES customer 子表 controller 的 @RequiresPermissions 授权

触发背景: 2026-08-03 渗透测试 H-1~H-4 (MesCustomer*Controller 4 个 controller 缺 @RequiresPermissions)
            MesCustomerController 额外 5 个写方法缺注解(Strix 未报,semgrep 发现)

执行要求:
  - 必须有可访问的 JeecgBoot 后端(默认 http://127.0.0.1:8080/jeecg-boot)
  - 后端必须包含低权限测试账号 ceshi / 123456
  - admin / 123456 必须在 DB 中(用于创建 victim customer)

环境变量:
  JEECG_BASE: 后端基础 URL(默认 http://127.0.0.1:8080/jeecg-boot)
"""
import os
import time
import urllib.parse
import urllib.request
import urllib.error
import json
import sys

import pytest

BASE = os.environ.get("JEECG_BASE", "http://127.0.0.1:8080/jeecg-boot")


# -----------------------------------------------------------------------
# HTTP 客户端
# -----------------------------------------------------------------------
def _http(method, path, token=None, body=None, query=None):
    url = BASE + path
    if query:
        url += "?" + urllib.parse.urlencode(query)
    data = json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    if body is not None:
        req.add_header("Content-Type", "application/json; charset=UTF-8")
    if token:
        req.add_header("X-Access-Token", token)
    try:
        with urllib.request.urlopen(req, timeout=15) as r:
            raw = r.read().decode("utf-8", "replace")
            try:
                return r.status, json.loads(raw)
            except json.JSONDecodeError:
                return r.status, raw
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", "replace") if e.fp else ""
        try:
            return e.code, json.loads(body)
        except json.JSONDecodeError:
            return e.code, body


def get(path, token=None, query=None):
    return _http("GET", path, token=token, query=query)


def post(path, body=None, token=None):
    return _http("POST", path, token=token, body=body)


def put(path, body=None, token=None):
    return _http("PUT", path, token=token, body=body)


def delete(path, token=None, query=None):
    return _http("DELETE", path, token=token, query=query)


# -----------------------------------------------------------------------
# Fixtures
# -----------------------------------------------------------------------
def _wait_for_backend():
    """最多等 60s 让后端就绪"""
    for _ in range(30):
        try:
            status, _ = get("/sys/randomImage/123")
            if status == 200:
                return
        except Exception:
            pass
        time.sleep(2)
    pytest.fail(f"后端在 60s 内未就绪: {BASE}")


@pytest.fixture(scope="session", autouse=True)
def backend_check():
    _wait_for_backend()


@pytest.fixture(scope="session")
def admin_token():
    status, body = post("/sys/login", {
        "username": "admin", "password": "123456", "captcha": "any"
    })
    assert status == 200 and isinstance(body, dict) and body.get("success"), \
        f"admin 登录失败: {status} {body}"
    return body["result"]["token"]


@pytest.fixture(scope="session")
def lowpriv_token():
    """ceshi = 系统测试角色, 仅 system:tenant:*, 不应有任何 mes:* 权限"""
    status, body = post("/sys/login", {
        "username": "ceshi", "password": "123456", "captcha": "any"
    })
    assert status == 200 and isinstance(body, dict) and body.get("success"), \
        f"lowpriv(ceshi) 登录失败: {status} {body}"
    return body["result"]["token"]


@pytest.fixture(scope="session")
def victim_customer_id(admin_token):
    """admin 创建一个 victim customer, 作为低权限用户越权操作的目标"""
    status, body = post(
        "/mes/basic/customer/add",
        body={"code": "POC-VICTIM", "name": "POC_VICTIM", "type": "1", "status": 1},
        token=admin_token,
    )
    assert status == 200 and isinstance(body, dict) and body.get("success"), \
        f"admin 创建 victim customer 失败: {status} {body}"
    return body["result"]


def _must_reject(label, status, body):
    """验证低权限请求被拒(非 200 success)"""
    if isinstance(body, dict):
        if body.get("success") is True:
            pytest.fail(
                f"[REGRESSION] {label}: 低权限用户本应被拒,但成功执行: {body}"
            )
    # success=False / 401 / 403 / 500 都视为被拒(其中 500 是业务拦截)
    assert status in (200, 401, 403, 500), f"{label}: 异常 status {status}"


# -----------------------------------------------------------------------
# H-1: MesCustomerAddressController
# -----------------------------------------------------------------------
class TestMesCustomerAddressAuthz:
    LABEL = "H-1 MesCustomerAddressController"

    def test_list(self, lowpriv_token, victim_customer_id):
        s, b = get(
            f"/mes/basic/customer/address/list",
            token=lowpriv_token,
            query={"pageNo": 1, "pageSize": 10, "customerId": victim_customer_id},
        )
        _must_reject(f"{self.LABEL} list", s, b)

    def test_add(self, lowpriv_token, victim_customer_id):
        s, b = post(
            "/mes/basic/customer/address/add",
            body={
                "customerId": victim_customer_id, "addressType": "1",
                "contact": "PWN", "phone": "13800138000",
                "detail": "PWNED_BY_LOW_PRIV", "isDefault": 0,
            },
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} add", s, b)

    def test_edit(self, lowpriv_token, victim_customer_id):
        s, b = put(
            "/mes/basic/customer/address/edit",
            body={"id": "any-bogus", "customerId": victim_customer_id, "addressType": "1"},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} edit", s, b)

    def test_delete(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/address/delete",
            token=lowpriv_token,
            query={"id": "any-bogus"},
        )
        _must_reject(f"{self.LABEL} delete", s, b)

    def test_deletebatch(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/address/deleteBatch",
            token=lowpriv_token,
            query={"ids": "any1,any2"},
        )
        _must_reject(f"{self.LABEL} deleteBatch", s, b)


# -----------------------------------------------------------------------
# H-2: MesCustomerContactController
# -----------------------------------------------------------------------
class TestMesCustomerContactAuthz:
    LABEL = "H-2 MesCustomerContactController"

    def test_list(self, lowpriv_token, victim_customer_id):
        s, b = get(
            "/mes/basic/customer/contact/list",
            token=lowpriv_token,
            query={"pageNo": 1, "pageSize": 10, "customerId": victim_customer_id},
        )
        _must_reject(f"{self.LABEL} list", s, b)

    def test_add(self, lowpriv_token, victim_customer_id):
        s, b = post(
            "/mes/basic/customer/contact/add",
            body={"customerId": victim_customer_id, "name": "PWN",
                  "phone": "13800138000", "title": "PWN", "isDefault": 0},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} add", s, b)

    def test_edit(self, lowpriv_token, victim_customer_id):
        s, b = put(
            "/mes/basic/customer/contact/edit",
            body={"id": "any-bogus", "customerId": victim_customer_id, "name": "PWN"},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} edit", s, b)

    def test_delete(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/contact/delete",
            token=lowpriv_token,
            query={"id": "any-bogus"},
        )
        _must_reject(f"{self.LABEL} delete", s, b)

    def test_deletebatch(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/contact/deleteBatch",
            token=lowpriv_token,
            query={"ids": "any1,any2"},
        )
        _must_reject(f"{self.LABEL} deleteBatch", s, b)


# -----------------------------------------------------------------------
# H-3: MesCustomerFollowUpController
# -----------------------------------------------------------------------
class TestMesCustomerFollowUpAuthz:
    LABEL = "H-3 MesCustomerFollowUpController"

    def test_list(self, lowpriv_token, victim_customer_id):
        s, b = get(
            "/mes/basic/customer/followUp/list",
            token=lowpriv_token,
            query={"pageNo": 1, "pageSize": 10, "customerId": victim_customer_id},
        )
        _must_reject(f"{self.LABEL} list", s, b)

    def test_add(self, lowpriv_token, victim_customer_id):
        s, b = post(
            "/mes/basic/customer/followUp/add",
            body={"customerId": victim_customer_id, "followType": "1",
                  "followDate": "2026-08-03 19:00:00", "content": "PWN",
                  "follower": "ceshi"},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} add", s, b)

    def test_edit(self, lowpriv_token, victim_customer_id):
        s, b = put(
            "/mes/basic/customer/followUp/edit",
            body={"id": "any-bogus", "customerId": victim_customer_id, "content": "PWN"},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} edit", s, b)

    def test_delete(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/followUp/delete",
            token=lowpriv_token,
            query={"id": "any-bogus"},
        )
        _must_reject(f"{self.LABEL} delete", s, b)

    def test_deletebatch(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/followUp/deleteBatch",
            token=lowpriv_token,
            query={"ids": "any1,any2"},
        )
        _must_reject(f"{self.LABEL} deleteBatch", s, b)


# -----------------------------------------------------------------------
# H-4: MesCustomerPriceController
# -----------------------------------------------------------------------
class TestMesCustomerPriceAuthz:
    LABEL = "H-4 MesCustomerPriceController"

    def test_list(self, lowpriv_token, victim_customer_id):
        s, b = get(
            "/mes/basic/customer/price/list",
            token=lowpriv_token,
            query={"pageNo": 1, "pageSize": 10, "customerId": victim_customer_id},
        )
        _must_reject(f"{self.LABEL} list", s, b)

    def test_add(self, lowpriv_token, victim_customer_id):
        s, b = post(
            "/mes/basic/customer/price/add",
            body={"customerId": victim_customer_id,
                  "productId": "ATTACKER_PRODUCT", "price": 0.01},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} add", s, b)

    def test_edit(self, lowpriv_token, victim_customer_id):
        s, b = put(
            "/mes/basic/customer/price/edit",
            body={"id": "any-bogus", "customerId": victim_customer_id, "price": 0.01},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} edit", s, b)

    def test_delete(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/price/delete",
            token=lowpriv_token,
            query={"id": "any-bogus"},
        )
        _must_reject(f"{self.LABEL} delete", s, b)

    def test_deletebatch(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/price/deleteBatch",
            token=lowpriv_token,
            query={"ids": "any1,any2"},
        )
        _must_reject(f"{self.LABEL} deleteBatch", s, b)


# -----------------------------------------------------------------------
# Bonus: MesCustomerController 写方法 (Strix 未报, semgrep 发现)
# -----------------------------------------------------------------------
class TestMesCustomerControllerAuthz:
    """MesCustomerController 5 个写方法缺 @RequiresPermissions
    (L63 add, L66 edit, L69 delete, L72 deleteBatch, L103 importExcel)
    2026-08-03 渗透测试: semgrep 找到,Strix 未报"""

    LABEL = "BONUS MesCustomerController write methods"

    def test_add(self, lowpriv_token):
        s, b = post(
            "/mes/basic/customer/add",
            body={"code": "PWN-CODE", "name": "PWN", "type": "1", "status": 1},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} add", s, b)

    def test_edit(self, lowpriv_token):
        s, b = put(
            "/mes/basic/customer/edit",
            body={"id": "any-bogus", "code": "PWN", "name": "PWN"},
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} edit", s, b)

    def test_delete(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/delete",
            token=lowpriv_token,
            query={"id": "any-bogus"},
        )
        _must_reject(f"{self.LABEL} delete", s, b)

    def test_deletebatch(self, lowpriv_token):
        s, b = delete(
            "/mes/basic/customer/deleteBatch",
            token=lowpriv_token,
            query={"ids": "any1,any2"},
        )
        _must_reject(f"{self.LABEL} deleteBatch", s, b)

    def test_importExcel(self, lowpriv_token):
        s, b = post(
            "/mes/basic/customer/importExcel",
            token=lowpriv_token,
        )
        _must_reject(f"{self.LABEL} importExcel", s, b)


# -----------------------------------------------------------------------
# M-1: MesMenuRegistry 重复 addPerms 防御
# 通过查询 sys_permission 表确认 mes:productionPicking:* 和 mes:completionReceipt:*
# 没有重复行
# -----------------------------------------------------------------------
class TestMenuRegistryNoDuplicates:
    """M-1: MesMenuRegistry 启动时 addPerms 重复调用,产生 sys_permission 重复行
    启动后端时由 MesMenuAutoRegisterRunner 创建,若 addPerms 重复会得到 2 份
    防御方式: 修复 MesMenuRegistry L109/L111 + L114/L116,SQL 迁移清理"""

    LABEL = "M-1 MesMenuRegistry duplicate addPerms"

    @pytest.fixture(scope="class")
    def menu_list(self, admin_token):
        """获取系统菜单列表"""
        s, b = get("/sys/permission/list", token=admin_token, query={"pageNo": 1, "pageSize": 9999})
        assert s == 200 and isinstance(b, dict) and b.get("success"), \
            f"获取菜单列表失败: {s} {b}"
        return b.get("result", {}).get("records", [])

    def test_production_picking_no_duplicate(self, menu_list):
        perms = [m.get("perms", "") for m in menu_list if m.get("perms", "").startswith("mes:productionPicking:")]
        # 期望: list/add/edit/delete/deleteBatch/export 各 1 行 = 6 条
        # 重复时: 12 条
        assert len(perms) == 6, (
            f"{self.LABEL}: mes:productionPicking:* 出现 {len(perms)} 次,期望 6。"
            f"如出现 12 表示 MesMenuRegistry 重复 addPerms 未清理。"
            f"实际值: {sorted(perms)}"
        )

    def test_completion_receipt_no_duplicate(self, menu_list):
        perms = [m.get("perms", "") for m in menu_list if m.get("perms", "").startswith("mes:completionReceipt:")]
        assert len(perms) == 5, (
            f"{self.LABEL}: mes:completionReceipt:* 出现 {len(perms)} 次,期望 5。"
            f"如出现 10 表示重复 addPerms 未清理。"
            f"实际值: {sorted(perms)}"
        )


# -----------------------------------------------------------------------
# 健全性: admin 仍可正常操作(防止规则误伤)
# -----------------------------------------------------------------------
class TestAdminStillWorks:
    """负向测试: 修复后 admin 必须仍能正常使用这些 endpoint
    防止规则误伤导致 admin 也被拒"""

    def test_admin_list_addresses(self, admin_token, victim_customer_id):
        s, b = get(
            "/mes/basic/customer/address/list",
            token=admin_token,
            query={"pageNo": 1, "pageSize": 10, "customerId": victim_customer_id},
        )
        assert s == 200 and isinstance(b, dict) and b.get("success"), \
            f"admin 应能 list addresses,但被拒: {s} {b}"
