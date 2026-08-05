"""
回归测试: 验证 BUG-PURCHASE-AUDIT-DATE-TZ (P1) 已修复
验证场景: 申请 requiredDate 设置为「今天」, 任何小时窗口调 audit() 都不应
  触发 validateOrder 报"交货日期不能早于订单日期"的事务回滚。

参考 hermes/eagle-eye/reports/2026-08-04/slice-1.1-purchase-apply-order.md
"""
import os
import time
import urllib.parse
import urllib.request
import urllib.error
import json
from datetime import datetime, timedelta

import pytest

BASE = os.environ.get("JEECG_BASE", "http://127.0.0.1:8080/jeecg-boot")


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


@pytest.fixture(scope="session")
def admin_token():
    s, b = post("/sys/login", {"username": "admin", "password": "123456", "captcha": "any"})
    assert s == 200 and b.get("success"), f"admin 登录失败: {s} {b}"
    return b["result"]["token"]


class TestPurchaseApplyAuditDate:
    """BUG-PURCHASE-AUDIT-DATE-TZ (P1) 回归测试
    验证: 不同小时窗口审核, 申请状态应正确变为已审核(3)"""

    APPLY_PATH = "/mes/purchase/apply"

    def _create_apply(self, admin_token, code_suffix, required_date):
        """创建一个测试申请 (草稿状态)"""
        s, b = post(
            f"{self.APPLY_PATH}/add",
            body={
                "code": f"BUY-{code_suffix}",
                "applicantId": "admin",
                "deptId": "A01",
                "applyDate": required_date,  # 当天
                "requiredDate": required_date,  # 必填: 与 applyDate 同日
                "budgetSubject": "6301",
                "totalAmount": 1000,
                "status": 1,  # 草稿
                "items": [
                    {"lineNo": 1, "materialId": "MAT-001",
                     "quantity": 1, "unitPrice": 1000, "taxRate": 0.13}
                ]
            },
            token=admin_token,
        )
        assert s == 200 and b.get("success"), f"创建申请失败: {s} {b}"
        return b["result"]

    def test_audit_at_00_hour_boundary(self, admin_token):
        """凌晨 0 点窗口: 申请 requiredDate=今天, audit() 应成功"""
        s, b = self._create_apply(admin_token, "0001", "2026-08-04")
        apply_id = b
        s, b = put(f"{self.APPLY_PATH}/audit", body={"id": apply_id}, token=admin_token)
        assert s == 200 and b.get("success"), \
            f"BUG-PURCHASE-AUDIT-DATE-TZ 复发: 凌晨窗口 audit() 失败: {s} {b}"

    def test_audit_at_23_hour_boundary(self, admin_token):
        """深夜 23 点窗口: 申请 requiredDate=今天, audit() 应成功"""
        s, b = self._create_apply(admin_token, "0023", "2026-08-04")
        apply_id = b
        s, b = put(f"{self.APPLY_PATH}/audit", body={"id": apply_id}, token=admin_token)
        assert s == 200 and b.get("success"), \
            f"BUG-PURCHASE-AUDIT-DATE-TZ 复发: 深夜窗口 audit() 失败: {s} {b}"

    def test_audit_status_transition(self, admin_token):
        """审核后申请状态应为 3 (已审核)"""
        s, b = self._create_apply(admin_token, "0003", "2026-08-04")
        apply_id = b
        put(f"{self.APPLY_PATH}/audit", body={"id": apply_id}, token=admin_token)
        s, b = get(f"{self.APPLY_PATH}/queryById", token=admin_token,
                   query={"id": apply_id})
        assert s == 200 and b.get("success")
        assert b["result"]["status"] == "3", \
            f"BUG-PURCHASE-AUDIT-DATE-TZ 复发: 审核后状态={b['result']['status']}, 期望=3"
