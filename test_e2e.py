#!/usr/bin/env python3
"""
SignVCB 完整业务 E2E 测试脚本
覆盖后端 BFF (8012) + 算法引擎 (8001) 所有业务接口

用法：
    python test_e2e.py

或指定地址：
    python test_e2e.py --server http://localhost:8012 --engine http://localhost:8001
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Optional

import httpx


# ============================================================
# 配置
# ============================================================
DEFAULT_SERVER = "http://localhost:8012"
DEFAULT_ENGINE = "http://localhost:8001"


# ============================================================
# HTTP 客户端工具
# ============================================================
class HTTPClient:
    def __init__(self, base_url: str, timeout: float = 30.0):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout
        self._token: Optional[str] = None

    def set_token(self, token: str):
        self._token = token

    def _headers(self, extra: dict = None) -> dict:
        h = {"Content-Type": "application/json"}
        if self._token:
            h["Authorization"] = f"Bearer {self._token}"
        if extra:
            h.update(extra)
        return h

    def get(self, path: str, **kwargs) -> httpx.Response:
        url = f"{self.base_url}{path}"
        kwargs.setdefault("timeout", self.timeout)
        kwargs.setdefault("headers", self._headers())
        return httpx.get(url, **kwargs)

    def post(self, path: str, **kwargs) -> httpx.Response:
        url = f"{self.base_url}{path}"
        kwargs.setdefault("timeout", self.timeout)
        kwargs.setdefault("headers", self._headers())
        return httpx.post(url, **kwargs)


# ============================================================
# SSE 解析
# ============================================================
def parse_sse_events(raw_text: str) -> list[tuple[str, Any]]:
    """解析 SSE 响应文本，返回 [(event_name, data_dict), ...]"""
    events = []
    current_event = "message"
    current_data = ""

    for line in raw_text.split("\n"):
        line = line.rstrip("\n\r")
        if line.startswith("event:"):
            current_event = line[6:].strip()
        elif line.startswith("data:"):
            current_data = line[5:].strip()
        elif line == "":
            if current_data:
                try:
                    data = json.loads(current_data)
                    events.append((current_event, data))
                except json.JSONDecodeError:
                    pass
            current_event = "message"
            current_data = ""

    return events


# ============================================================
# 测试结果数据类
# ============================================================
@dataclass
class TestResult:
    name: str
    passed: bool
    input: str = ""
    expected: str = ""
    actual: str = ""
    detail: str = ""
    latency_ms: float = 0.0


# ============================================================
# 测试套件
# ============================================================
class TestSuite:
    def __init__(self, server_url: str, engine_url: str):
        self.server = HTTPClient(server_url)
        self.engine = HTTPClient(engine_url)
        self.results: list[TestResult] = []
        self.username = f"e2e_user_{int(time.time())}"
        self.password = "TestPass123"
        self.token: Optional[str] = None
        self._question_ids_collected: dict = {}

    def record(self, name: str, passed: bool, detail: str = "", latency_ms: float = 0.0, input: str = "", expected: str = "", actual: str = ""):
        self.results.append(TestResult(name=name, passed=passed, input=input, expected=expected, actual=actual, detail=detail, latency_ms=latency_ms))

    def extract_error(self, resp: httpx.Response) -> str:
        try:
            data = resp.json()
            if isinstance(data, dict):
                return data.get("detail") or data.get("message") or data.get("code") or str(data)
            return str(data)
        except Exception:
            return resp.text[:200]

    # --------------------------------------------------------
    # [Engine] 健康检查
    # --------------------------------------------------------
    def test_engine_health(self):
        """[Engine] GET /health"""
        t0 = time.perf_counter()
        r = self.engine.get("/health")
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Engine健康检查", False, f"HTTP {r.status_code}", elapsed, input="GET /health", expected="HTTP 200 + status=healthy", actual=f"HTTP {r.status_code}")
            return

        data = r.json()
        deps = data.get("dependencies", {})
        onnx_ok = deps.get("onnx") == "ok"
        faiss_ok = deps.get("faiss") == "ok"
        status = data.get("status")

        detail = f"status={status} onnx={deps.get('onnx')} faiss={deps.get('faiss')} llm={deps.get('llm')} rewrite={deps.get('rewrite_pipeline')}"
        self.record("Engine健康检查", onnx_ok and faiss_ok, detail, elapsed, input="GET /health", expected="HTTP 200 + onnx=ok + faiss=ok", actual=detail)

    # --------------------------------------------------------
    # [Engine] Rewrite SSE 流 - 无 OOV 词
    # --------------------------------------------------------
    def test_engine_rewrite_no_oov(self):
        """[Engine] POST /internal/rewrite - 词汇均在词表内"""
        t0 = time.perf_counter()
        r = self.engine.post("/internal/rewrite", json={"text": "我吃苹果", "context": ""})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Engine Rewrite(无OOV)", False, f"HTTP {r.status_code}", elapsed, input='POST /internal/rewrite {"text":"我吃苹果","context":""}', expected="HTTP 200 + SSE: preheat→first_pass→refined_pass→done", actual=f"HTTP {r.status_code}")
            return

        events = parse_sse_events(r.text)
        event_names = [e[0] for e in events]

        # 必须有 preheat、first_pass、refined_pass、done
        has_preheat = "preheat" in event_names
        has_first = "first_pass" in event_names
        has_refined = "refined_pass" in event_names
        has_done = "done" in event_names
        has_no_error = "error" not in event_names

        # 检查 first_pass
        first_data = next((d for n, d in events if n == "first_pass"), None)
        first_oov_ok = first_data and first_data.get("oov_status") is False

        # 检查 refined_pass
        refined_data = next((d for n, d in events if n == "refined_pass"), None)
        refined_text_ok = refined_data and len(refined_data.get("text", "")) > 0

        all_ok = has_preheat and has_first and has_refined and has_done and has_no_error and first_oov_ok
        detail = (f"事件={event_names} "
                  f"oov_status={first_data.get('oov_status') if first_data else 'N/A'} "
                  f"refined_text={refined_data.get('text') if refined_data else 'N/A'} "
                  f"oov_map={refined_data.get('oov_map') if refined_data else 'N/A'}")
        self.record("Engine Rewrite(无OOV)", all_ok, detail, elapsed, input='POST /internal/rewrite {"text":"我吃苹果","context":""}', expected="HTTP 200 + SSE: preheat/first_pass/refined_pass/done + oov_status=false", actual=detail)

    # --------------------------------------------------------
    # [Engine] Rewrite SSE 流 - 含 OOV 词
    # --------------------------------------------------------
    def test_engine_rewrite_with_oov(self):
        """[Engine] POST /internal/rewrite - 含 OOV 词'量子'"""
        t0 = time.perf_counter()
        r = self.engine.post("/internal/rewrite", json={"text": "我吃量子", "context": ""})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Engine Rewrite(含OOV)", False, f"HTTP {r.status_code}", elapsed, input='POST /internal/rewrite {"text":"我吃量子","context":""}', expected="HTTP 200 + oov_status=true + oov_map非空", actual=f"HTTP {r.status_code}")
            return

        events = parse_sse_events(r.text)
        event_names = [e[0] for e in events]

        first_data = next((d for n, d in events if n == "first_pass"), None)
        first_oov_ok = first_data and first_data.get("oov_status") is True

        refined_data = next((d for n, d in events if n == "refined_pass"), None)
        has_oov_map = refined_data and len(refined_data.get("oov_map", {})) > 0
        has_alignment_ops = refined_data and isinstance(refined_data.get("alignment_ops"), list)

        all_ok = first_oov_ok and has_oov_map and has_alignment_ops
        detail = (f"事件={event_names} "
                  f"oov_status={first_data.get('oov_status') if first_data else 'N/A'} "
                  f"oov_map={refined_data.get('oov_map') if refined_data else 'N/A'} "
                  f"alignment_ops数量={len(refined_data.get('alignment_ops', [])) if refined_data else 0}")
        self.record("Engine Rewrite(含OOV)", all_ok, detail, elapsed, input='POST /internal/rewrite {"text":"我吃量子","context":""}', expected="HTTP 200 + oov_status=true + oov_map非空 + alignment_ops", actual=detail)

    # --------------------------------------------------------
    # [Engine] Rewrite SSE 流 - 带 context
    # --------------------------------------------------------
    def test_engine_rewrite_with_context(self):
        """[Engine] POST /internal/rewrite - 带 context 参数"""
        t0 = time.perf_counter()
        r = self.engine.post("/internal/rewrite", json={"text": "今天天气", "context": "天气对话"})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Engine Rewrite(带Context)", False, f"HTTP {r.status_code}", elapsed,
                        input='POST /internal/rewrite {"text":"今天天气","context":"天气对话"}',
                        expected="HTTP 200 + SSE events",
                        actual=f"HTTP {r.status_code}")
            return

        events = parse_sse_events(r.text)
        event_names = [e[0] for e in events]
        has_refined = "refined_pass" in event_names
        self.record("Engine Rewrite(带Context)", has_refined, f"事件={event_names}", elapsed,
                    input='POST /internal/rewrite {"text":"今天天气","context":"天气对话"}',
                    expected="HTTP 200 + SSE events including refined_pass",
                    actual=f"事件={event_names}")

    # --------------------------------------------------------
    # [Engine] Rewrite SSE 流 - 验证 NMM hints
    # --------------------------------------------------------
    def test_engine_rewrite_nmm(self):
        """[Engine] POST /internal/rewrite - 验证 NMM 标记（否定词/疑问词）"""
        t0 = time.perf_counter()
        # CSL 语序：我不去 → 我 去 不
        r = self.engine.post("/internal/rewrite", json={"text": "我不去", "context": ""})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Engine Rewrite(NMM标记)", False, f"HTTP {r.status_code}", elapsed,
                        input='POST /internal/rewrite {"text":"我不去","context":""}',
                        expected="HTTP 200 + nmm_hints dict",
                        actual=f"HTTP {r.status_code}")
            return

        events = parse_sse_events(r.text)
        refined_data = next((d for n, d in events if n == "refined_pass"), None)
        nmm_hints = refined_data.get("nmm_hints", {}) if refined_data else {}

        # refined_text 中应该包含否定词"不"的位置标记
        has_nmm = isinstance(nmm_hints, dict)
        detail = f"nmm_hints={nmm_hints} refined_text={refined_data.get('text') if refined_data else 'N/A'}"
        self.record("Engine Rewrite(NMM标记)", has_nmm, detail, elapsed,
                    input='POST /internal/rewrite {"text":"我不去","context":""}',
                    expected="nmm_hints is dict",
                    actual=detail)

    # --------------------------------------------------------
    # [Engine] Rewrite SSE 流 - 验证 alignment_ops 结构
    # --------------------------------------------------------
    def test_engine_rewrite_alignment_ops(self):
        """[Engine] POST /internal/rewrite - 验证对齐操作字段完整"""
        t0 = time.perf_counter()
        r = self.engine.post("/internal/rewrite", json={"text": "我吃苹果", "context": ""})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Engine Rewrite(AlignmentOps结构)", False, f"HTTP {r.status_code}", elapsed)
            return

        events = parse_sse_events(r.text)
        refined_data = next((d for n, d in events if n == "refined_pass"), None)
        ops = refined_data.get("alignment_ops", []) if refined_data else []

        if not ops:
            # 无操作时 ops 应为空列表
            self.record("Engine Rewrite(AlignmentOps结构)", True, "无对齐操作（首尾 pass 相同）", elapsed)
            return

        for op in ops:
            if not isinstance(op, dict):
                self.record("Engine Rewrite(AlignmentOps结构)", False, f"op 不是 dict: {op}", elapsed)
                return
            if "type" not in op or "word" not in op:
                self.record("Engine Rewrite(AlignmentOps结构)", False, f"op 缺少必填字段: {op}", elapsed)
                return
            # POSTPONE 操作应有 source 字段
            if op["type"] == "postpone" and "source" not in op:
                self.record("Engine Rewrite(AlignmentOps结构)", False, f"POSTPONE 缺少 source: {op}", elapsed)
                return

        self.record("Engine Rewrite(AlignmentOps结构)", True, f"ops={ops}", elapsed)

    # --------------------------------------------------------
    # [Engine] Normalize 逆向归一化
    # --------------------------------------------------------
    def test_engine_normalize(self):
        """[Engine] POST /internal/normalize - CSL 逆向归一化为自然中文"""
        t0 = time.perf_counter()
        r = self.engine.post("/internal/normalize", json={"text": "苹果 我 吃", "num_options": 3})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Engine Normalize", False, f"HTTP {r.status_code}: {self.extract_error(r)}", elapsed,
                        input='POST /internal/normalize {"text":"苹果 我 吃","num_options":3}',
                        expected="HTTP 200 + options list with items",
                        actual=f"HTTP {r.status_code}: {self.extract_error(r)}")
            return

        data = r.json()
        options = data.get("options", [])
        is_list = isinstance(options, list)
        has_options = len(options) > 0
        self.record("Engine Normalize", is_list and has_options, f"返回{len(options)}个候选", elapsed,
                    input='POST /internal/normalize {"text":"苹果 我 吃","num_options":3}',
                    expected="HTTP 200 + options list with items",
                    actual=f"返回{len(options)}个候选")

    # --------------------------------------------------------
    # [Engine] Dynamic Fallback
    # --------------------------------------------------------
    def test_engine_dynamic_fallback(self):
        """[Engine] GET /internal/dynamic_fallback"""
        t0 = time.perf_counter()
        r = self.engine.get("/internal/dynamic_fallback")
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Engine 动态降级词", False, f"HTTP {r.status_code}", elapsed,
                        input='GET /internal/dynamic_fallback',
                        expected="HTTP 200 + items + count fields",
                        actual=f"HTTP {r.status_code}")
            return

        data = r.json()
        has_items = "items" in data
        has_count = "count" in data
        self.record("Engine 动态降级词", has_items and has_count, f"count={data.get('count')} items={len(data.get('items',[]))}", elapsed,
                    input='GET /internal/dynamic_fallback',
                    expected="HTTP 200 + items + count fields",
                    actual=f"count={data.get('count')} items={len(data.get('items',[]))}")

    # --------------------------------------------------------
    # [Backend] 健康检查
    # --------------------------------------------------------
    def test_backend_health(self):
        """[Backend] GET /health"""
        t0 = time.perf_counter()
        r = self.server.get("/health")
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Backend健康检查", False, f"HTTP {r.status_code}", elapsed,
                        input='GET /health',
                        expected="HTTP 200 + mysql=ok + redis=ok",
                        actual=f"HTTP {r.status_code}")
            return

        data = r.json()
        deps = data.get("dependencies", {})
        mysql_ok = deps.get("mysql") == "ok"
        redis_ok = deps.get("redis") == "ok"
        detail = f"MySQL={deps.get('mysql')} Redis={deps.get('redis')} Engine={deps.get('engine')}"
        self.record("Backend健康检查", mysql_ok and redis_ok, detail, elapsed,
                    input='GET /health',
                    expected="mysql=ok and redis=ok",
                    actual=detail)

    # --------------------------------------------------------
    # [Backend] 匿名接口 - AppConfig
    # --------------------------------------------------------
    def test_backend_app_config(self):
        """[Backend] GET /api/v1/app_config (无需认证)"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/app_config")
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("App配置(匿名)", False, f"HTTP {r.status_code}", elapsed,
                        input='GET /api/v1/app_config',
                        expected="HTTP 200 + enable_stream_masking + show_oov_map + show_nmm_hints + sse_timeout_ms",
                        actual=f"HTTP {r.status_code}")
            return

        data = r.json()
        keys = list(data.keys())
        has_stream_masking = "enable_stream_masking" in data
        has_oov_map = "show_oov_map" in data
        has_nmm_hints = "show_nmm_hints" in data
        has_timeout = "sse_timeout_ms" in data
        self.record("App配置(匿名)", has_stream_masking and has_oov_map and has_nmm_hints and has_timeout,
                    f"配置项={keys}", elapsed,
                    input='GET /api/v1/app_config',
                    expected="HTTP 200 + all config fields present",
                    actual=f"配置项={keys}")

    # --------------------------------------------------------
    # [Backend] 认证 - 注册
    # --------------------------------------------------------
    def test_auth_register(self):
        """[Backend] POST /api/v1/auth/register"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/auth/register", json={
            "username": self.username,
            "password": self.password,
            "age_group": "L1",
            "nickname": "E2E测试用户"
        })
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code == 400 and "exists" in r.text.lower():
            self.record("用户注册(新用户)", True, "用户已存在（残留），复用并登录", elapsed)
            self._do_login()
            return

        if r.status_code not in (200, 201):
            self.record("用户注册(新用户)", False, f"HTTP {r.status_code}: {self.extract_error(r)}", elapsed,
                        input='POST /api/v1/auth/register {"username":"...","password":"...","age_group":"L1","nickname":"E2E测试用户"}',
                        expected="HTTP 200/201 + access_token",
                        actual=f"HTTP {r.status_code}: {self.extract_error(r)}")
            return

        data = r.json()
        if "access_token" not in data:
            self.record("用户注册(新用户)", False, f"无access_token: {list(data.keys())}", elapsed,
                        input='POST /api/v1/auth/register {"username":"...","password":"...","age_group":"L1","nickname":"E2E测试用户"}',
                        expected="HTTP 200/201 + access_token",
                        actual=f"无access_token: {list(data.keys())}")
            return

        self.token = data["access_token"]
        self.server.set_token(self.token)
        self.record("用户注册(新用户)", True, f"user_id={data.get('user',{}).get('id')}", elapsed,
                    input='POST /api/v1/auth/register {"username":"...","password":"...","age_group":"L1","nickname":"E2E测试用户"}',
                    expected="HTTP 200/201 + access_token",
                    actual=f"user_id={data.get('user',{}).get('id')}")

    def _do_login(self):
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/auth/login", json={
            "username": self.username,
            "password": self.password
        })
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("用户登录", False, f"HTTP {r.status_code}: {self.extract_error(r)}", elapsed,
                        input='POST /api/v1/auth/login {"username":"...","password":"..."}',
                        expected="HTTP 200 + access_token",
                        actual=f"HTTP {r.status_code}: {self.extract_error(r)}")
            return

        data = r.json()
        if "access_token" not in data:
            self.record("用户登录", False, "无access_token", elapsed,
                        input='POST /api/v1/auth/login {"username":"...","password":"..."}',
                        expected="HTTP 200 + access_token",
                        actual="无access_token")
            return

        self.token = data["access_token"]
        self.server.set_token(self.token)
        self.record("用户登录", True, f"user={data.get('user',{}).get('username')}", elapsed,
                    input='POST /api/v1/auth/login {"username":"...","password":"..."}',
                    expected="HTTP 200 + access_token",
                    actual=f"user={data.get('user',{}).get('username')}")

    def test_auth_login(self):
        """[Backend] POST /api/v1/auth/login"""
        if self.token:
            self.record("用户登录", True, "已有token，跳过", 0)
            return
        self._do_login()

    def test_auth_duplicate_register(self):
        """[Backend] POST /api/v1/auth/register 重复注册"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/auth/register", json={
            "username": self.username,
            "password": self.password,
            "age_group": "L1"
        })
        elapsed = (time.perf_counter() - t0) * 1000
        passed = r.status_code == 400
        self.record("注册重复用户名(400)", passed, f"HTTP {r.status_code} {'正确' if passed else '应为400'}", elapsed,
                    input='POST /api/v1/auth/register {"username":"...","password":"...","age_group":"L1"}',
                    expected="HTTP 400",
                    actual=f"HTTP {r.status_code}")

    def test_auth_bad_password(self):
        """[Backend] POST /api/v1/auth/login 错误密码"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/auth/login", json={
            "username": self.username,
            "password": "wrongpassword123"
        })
        elapsed = (time.perf_counter() - t0) * 1000
        passed = r.status_code == 401
        self.record("登录错误密码(401)", passed, f"HTTP {r.status_code} {'正确' if passed else '应为401'}", elapsed,
                    input='POST /api/v1/auth/login {"username":"...","password":"wrongpassword123"}',
                    expected="HTTP 401",
                    actual=f"HTTP {r.status_code}")

    def test_auth_no_token_rejection(self):
        """[Backend] 无Token访问需认证接口"""
        t0 = time.perf_counter()
        anon = HTTPClient(DEFAULT_SERVER)
        r = anon.get("/api/v1/reading/books")
        elapsed = (time.perf_counter() - t0) * 1000
        passed = r.status_code in (401, 403)
        self.record("无Token拦截(401)", passed, f"HTTP {r.status_code} {'正确' if passed else '应为401/403'}", elapsed,
                    input='GET /api/v1/reading/books (no token)',
                    expected="HTTP 401 or 403",
                    actual=f"HTTP {r.status_code}")

    # --------------------------------------------------------
    # [Backend] Chat Rewrite SSE 流
    # --------------------------------------------------------
    def _do_stream(self, path: str, json_body: dict) -> tuple:
        """通用 SSE 流式请求，返回 (event_names, raw_text, elapsed_ms)"""
        t0 = time.perf_counter()
        with httpx.stream("POST", f"{self.server.base_url}{path}",
                          json=json_body,
                          headers=self.server._headers({"Accept": "text/event-stream"}),
                          timeout=30.0) as r:
            elapsed = (time.perf_counter() - t0) * 1000
            if r.status_code != 200:
                return [], f"HTTP {r.status_code}: {r.read().decode()[:200]}", elapsed
            text = r.read().decode("utf-8")
        events = parse_sse_events(text)
        return [e[0] for e in events], text, elapsed

    def test_chat_rewrite(self):
        """[Backend] POST /api/v1/chat/rewrite"""
        event_names, raw, elapsed = self._do_stream("/api/v1/chat/rewrite", {"text": "我吃苹果", "context": ""})

        has_preheat = "preheat" in event_names
        has_first = "first_pass" in event_names
        has_refined = "refined_pass" in event_names
        has_done = "done" in event_names
        all_ok = has_preheat and has_first and has_refined and has_done
        self.record("Chat Rewrite流", all_ok, f"事件={event_names}", elapsed,
                    input='POST /api/v1/chat/rewrite {"text":"我吃苹果","context":""}',
                    expected="HTTP 200 + SSE: preheat/first_pass/refined_pass/done",
                    actual=f"事件={event_names}")

    def test_chat_rewrite_with_oov(self):
        """[Backend] POST /api/v1/chat/rewrite 含OOV词"""
        event_names, raw, elapsed = self._do_stream("/api/v1/chat/rewrite", {"text": "我吃量子", "context": ""})

        events = parse_sse_events(raw)
        refined_data = next((d for n, d in events if n == "refined_pass"), None)
        has_oov_map = refined_data is not None and len(refined_data.get("oov_map", {})) > 0
        oov_map_size = len(refined_data.get("oov_map", {})) if refined_data else 0

        self.record("Chat Rewrite(含OOV)", has_oov_map, f"事件={event_names}", elapsed,
                    input='POST /api/v1/chat/rewrite {"text":"我吃量子","context":""}',
                    expected="HTTP 200 + SSE: oov_map non-empty in refined_pass",
                    actual=f"事件={event_names} oov_map_size={oov_map_size}")

    def test_chat_rewrite_with_context(self):
        """[Backend] POST /api/v1/chat/rewrite 带context"""
        event_names, raw, elapsed = self._do_stream("/api/v1/chat/rewrite", {"text": "今天天气很好", "context": "天气对话"})
        has_refined = "refined_pass" in event_names
        self.record("Chat Rewrite(带Context)", has_refined, f"事件={event_names}", elapsed,
                    input='POST /api/v1/chat/rewrite {"text":"今天天气很好","context":"天气对话"}',
                    expected="HTTP 200 + SSE: refined_pass present",
                    actual=f"事件={event_names}")

    def test_chat_rewrite_oov_event_sequence(self):
        """[Backend] 验证含OOV时 SSE 事件顺序正确"""
        event_names, raw, elapsed = self._do_stream("/api/v1/chat/rewrite", {"text": "量子区块链", "context": ""})

        # 顺序：preheat → first_pass → refined_pass → done
        preheat_idx = event_names.index("preheat") if "preheat" in event_names else -1
        first_idx = event_names.index("first_pass") if "first_pass" in event_names else -1
        refined_idx = event_names.index("refined_pass") if "refined_pass" in event_names else -1
        done_idx = event_names.index("done") if "done" in event_names else -1

        order_ok = 0 <= preheat_idx < first_idx < refined_idx < done_idx
        self.record("Chat Rewrite(事件顺序)", order_ok, f"顺序={event_names}", elapsed,
                    input='POST /api/v1/chat/rewrite {"text":"量子区块链","context":""}',
                    expected="HTTP 200 + SSE order: preheat < first_pass < refined_pass < done",
                    actual=f"顺序={event_names}")

    # --------------------------------------------------------
    # [Backend] TTS 语音合成
    # --------------------------------------------------------
    def test_chat_tts(self):
        """[Backend] POST /api/v1/chat/tts"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/chat/tts", json={"text": "你好世界", "speed": 1.0})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("TTS语音合成", False, f"HTTP {r.status_code}: {self.extract_error(r)}", elapsed,
                        input='POST /api/v1/chat/tts {"text":"你好世界","speed":1.0}',
                        expected="HTTP 200 + audio_url",
                        actual=f"HTTP {r.status_code}: {self.extract_error(r)}")
            return

        data = r.json()
        audio_url = data.get("audio_url", "")
        has_url = bool(audio_url) and ("tts_audio" in audio_url or "audio" in audio_url)
        self.record("TTS语音合成", has_url, f"audio_url={audio_url[:60]}...", elapsed,
                    input='POST /api/v1/chat/tts {"text":"你好世界","speed":1.0}',
                    expected="HTTP 200 + audio_url present",
                    actual=f"audio_url={audio_url[:60]}...")

    def test_chat_tts_speed(self):
        """[Backend] POST /api/v1/chat/tts 不同速度"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/chat/tts", json={"text": "测试速度", "speed": 0.8})
        elapsed = (time.perf_counter() - t0) * 1000
        data = r.json()
        has_url = bool(data.get("audio_url"))
        self.record("TTS语音合成(速度0.8)", has_url, f"HTTP {r.status_code}", elapsed,
                    input='POST /api/v1/chat/tts {"text":"测试速度","speed":0.8}',
                    expected="HTTP 200 + audio_url present",
                    actual=f"HTTP {r.status_code} audio_url={'present' if has_url else 'missing'}")

    # --------------------------------------------------------
    # [Backend] 建议回复
    # --------------------------------------------------------
    def test_chat_suggest(self):
        """[Backend] POST /api/v1/chat/suggest_reply"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/chat/suggest_reply", json={"text": "我要喝水", "context": ""})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("建议回复(Suggest)", False, f"HTTP {r.status_code}: {self.extract_error(r)}", elapsed,
                        input='POST /api/v1/chat/suggest_reply {"text":"我要喝水","context":""}',
                        expected="HTTP 200 + suggestions list",
                        actual=f"HTTP {r.status_code}: {self.extract_error(r)}")
            return

        data = r.json()
        suggestions = data.get("suggestions", [])
        is_list = isinstance(suggestions, list)
        self.record("建议回复(Suggest)", is_list, f"返回{len(suggestions)}条建议", elapsed,
                    input='POST /api/v1/chat/suggest_reply {"text":"我要喝水","context":""}',
                    expected="HTTP 200 + suggestions list",
                    actual=f"返回{len(suggestions)}条建议")

    # --------------------------------------------------------
    # [Backend] 逆向归一化
    # --------------------------------------------------------
    def test_chat_normalize(self):
        """[Backend] POST /api/v1/chat/normalize_options"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/chat/normalize_options", json={"text": "苹果 我 吃", "num_options": 3})
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("Chat Normalize", False, f"HTTP {r.status_code}: {self.extract_error(r)}", elapsed,
                        input='POST /api/v1/chat/normalize_options {"text":"苹果 我 吃","num_options":3}',
                        expected="HTTP 200 + options list with items",
                        actual=f"HTTP {r.status_code}: {self.extract_error(r)}")
            return

        data = r.json()
        options = data.get("options", [])
        self.record("Chat Normalize", isinstance(options, list) and len(options) > 0, f"返回{len(options)}个候选", elapsed,
                    input='POST /api/v1/chat/normalize_options {"text":"苹果 我 吃","num_options":3}',
                    expected="HTTP 200 + options list with items",
                    actual=f"返回{len(options)}个候选")

    # --------------------------------------------------------
    # [Backend] 意图不匹配日志
    # --------------------------------------------------------
    def test_chat_log_mismatch(self):
        """[Backend] POST /api/v1/chat/log_mismatch"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/chat/log_mismatch", json={
            "original_text": "苹果",
            "failed_options": ["水果", "食物"],
            "context": "E2E测试"
        })
        elapsed = (time.perf_counter() - t0) * 1000
        passed = r.status_code == 200
        self.record("意图不匹配日志", passed, f"HTTP {r.status_code}", elapsed,
                    input='POST /api/v1/chat/log_mismatch {"original_text":"苹果","failed_options":["水果","食物"],"context":"E2E测试"}',
                    expected="HTTP 200",
                    actual=f"HTTP {r.status_code}")

    # --------------------------------------------------------
    # [Backend] 读物 - 书籍列表
    # --------------------------------------------------------
    def test_reading_books(self):
        """[Backend] GET /api/v1/reading/books"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/reading/books")
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code == 401:
            self.record("读物书籍列表", False, "需要认证", elapsed,
                        input='GET /api/v1/reading/books',
                        expected="HTTP 200 + books list or 401 if no auth",
                        actual="HTTP 401 - 需要认证")
            return

        if r.status_code != 200:
            self.record("读物书籍列表", False, f"HTTP {r.status_code}", elapsed,
                        input='GET /api/v1/reading/books',
                        expected="HTTP 200 + books list",
                        actual=f"HTTP {r.status_code}")
            return

        books = r.json()
        is_list = isinstance(books, list)
        self.record("读物书籍列表", is_list, f"返回{len(books)}本书", elapsed,
                    input='GET /api/v1/reading/books',
                    expected="HTTP 200 + books list",
                    actual=f"返回{len(books)}本书")

    def test_reading_books_l1_filter(self):
        """[Backend] GET /api/v1/reading/books?age_group=L1"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/reading/books?age_group=L1")
        elapsed = (time.perf_counter() - t0) * 1000
        books = r.json() if r.status_code == 200 else []
        is_list = isinstance(books, list)
        self.record("读物书籍列表(L1筛选)", is_list, f"L1书籍{len(books)}本", elapsed,
                    input='GET /api/v1/reading/books?age_group=L1',
                    expected="HTTP 200 + books list (L1 filtered)",
                    actual=f"L1书籍{len(books)}本")

    def test_reading_books_l2_filter(self):
        """[Backend] GET /api/v1/reading/books?age_group=L2"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/reading/books?age_group=L2")
        elapsed = (time.perf_counter() - t0) * 1000
        books = r.json() if r.status_code == 200 else []
        is_list = isinstance(books, list)
        self.record("读物书籍列表(L2筛选)", is_list, f"L2书籍{len(books)}本", elapsed,
                    input='GET /api/v1/reading/books?age_group=L2',
                    expected="HTTP 200 + books list (L2 filtered)",
                    actual=f"L2书籍{len(books)}本")

    def test_reading_content(self):
        """[Backend] GET /api/v1/reading/books/1/content"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/reading/books/1/content")
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code == 404:
            self.record("读物内容(BookID=1)", True, "书籍不存在（种子数据未导入），跳过", elapsed,
                        input='GET /api/v1/reading/books/1/content',
                        expected="HTTP 200 + book_id + sentences or 404",
                        actual="HTTP 404 - 书籍不存在")
            return

        if r.status_code != 200:
            self.record("读物内容(BookID=1)", False, f"HTTP {r.status_code}", elapsed,
                        input='GET /api/v1/reading/books/1/content',
                        expected="HTTP 200 + book_id + sentences",
                        actual=f"HTTP {r.status_code}")
            return

        data = r.json()
        sentences = data.get("sentences", [])
        has_book_id = "book_id" in data
        has_sentences = isinstance(sentences, list)
        self.record("读物内容(BookID=1)", has_book_id and has_sentences,
                    f"book_id={data.get('book_id')} 句子数={len(sentences)}", elapsed,
                    input='GET /api/v1/reading/books/1/content',
                    expected="HTTP 200 + book_id + sentences",
                    actual=f"book_id={data.get('book_id')} 句子数={len(sentences)}")

    def test_reading_content_not_found(self):
        """[Backend] GET /api/v1/reading/books/9999/content - 不存在的书籍"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/reading/books/9999/content")
        elapsed = (time.perf_counter() - t0) * 1000
        passed = r.status_code == 404
        self.record("读物内容(不存在书籍)", passed, f"HTTP {r.status_code} {'正确' if passed else '应为404'}", elapsed,
                    input='GET /api/v1/reading/books/9999/content',
                    expected="HTTP 404",
                    actual=f"HTTP {r.status_code}")

    # --------------------------------------------------------
    # [Backend] 练习题 - 获取
    # --------------------------------------------------------
    def _collect_practice_question(self, level: str, qtype: str) -> Optional[int]:
        """获取一道练习题并缓存 question_id"""
        r = self.server.get(f"/api/v1/practice/question?level={level}&type={qtype}")
        if r.status_code != 200:
            return None
        data = r.json()
        qid = data.get("id", 0)
        if qid > 0:
            key = f"{level}_{qtype}"
            self._question_ids_collected[key] = (qid, data)
        return qid if qid > 0 else None

    def test_practice_question_word_match_l1(self):
        """[Backend] GET /api/v1/practice/question?level=L1&type=word_match"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/practice/question?level=L1&type=word_match")
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code == 401:
            self.record("练习题获取(L1-word_match)", False, "需要认证", elapsed,
                        input='GET /api/v1/practice/question?level=L1&type=word_match',
                        expected="HTTP 200 + question data or 401",
                        actual="HTTP 401 - 需要认证")
            return

        if r.status_code != 200:
            self.record("练习题获取(L1-word_match)", False, f"HTTP {r.status_code}", elapsed,
                        input='GET /api/v1/practice/question?level=L1&type=word_match',
                        expected="HTTP 200 + question data",
                        actual=f"HTTP {r.status_code}")
            return

        data = r.json()
        qid = data.get("id", 0)
        if qid == 0:
            self.record("练习题获取(L1-word_match)", True, "无练习题数据，跳过", elapsed,
                        input='GET /api/v1/practice/question?level=L1&type=word_match',
                        expected="HTTP 200 + question data or empty",
                        actual="无练习题数据")
            return

        has_fields = all(k in data for k in ("id", "level", "type"))
        self.record("练习题获取(L1-word_match)", has_fields,
                    f"id={qid} level={data.get('level')} type={data.get('type')}", elapsed,
                    input='GET /api/v1/practice/question?level=L1&type=word_match',
                    expected="HTTP 200 + id/level/type fields",
                    actual=f"id={qid} level={data.get('level')} type={data.get('type')}")

    def test_practice_question_sentence_order_l2(self):
        """[Backend] GET /api/v1/practice/question?level=L2&type=sentence_order"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/practice/question?level=L2&type=sentence_order")
        elapsed = (time.perf_counter() - t0) * 1000
        data = r.json() if r.status_code == 200 else {}
        qid = data.get("id", 0)
        if qid == 0:
            self.record("练习题获取(L2-sentence_order)", True, "无练习题数据，跳过", elapsed,
                        input='GET /api/v1/practice/question?level=L2&type=sentence_order',
                        expected="HTTP 200 + question data or empty",
                        actual="无练习题数据")
            return
        has_fields = all(k in data for k in ("id", "level", "type"))
        self.record("练习题获取(L2-sentence_order)", has_fields, f"id={qid}", elapsed,
                    input='GET /api/v1/practice/question?level=L2&type=sentence_order',
                    expected="HTTP 200 + id/level/type fields",
                    actual=f"id={qid}")

    def test_practice_question_sign_recognize_l3(self):
        """[Backend] GET /api/v1/practice/question?level=L3&type=sign_recognize"""
        t0 = time.perf_counter()
        r = self.server.get("/api/v1/practice/question?level=L3&type=sign_recognize")
        elapsed = (time.perf_counter() - t0) * 1000
        data = r.json() if r.status_code == 200 else {}
        qid = data.get("id", 0)
        if qid == 0:
            self.record("练习题获取(L3-sign_recognize)", True, "无练习题数据，跳过", elapsed,
                        input='GET /api/v1/practice/question?level=L3&type=sign_recognize',
                        expected="HTTP 200 + question data or empty",
                        actual="无练习题数据")
            return
        has_fields = all(k in data for k in ("id", "level", "type"))
        self.record("练习题获取(L3-sign_recognize)", has_fields, f"id={qid}", elapsed,
                    input='GET /api/v1/practice/question?level=L3&type=sign_recognize',
                    expected="HTTP 200 + id/level/type fields",
                    actual=f"id={qid}")

    # --------------------------------------------------------
    # [Backend] 练习题 - 提交答案
    # --------------------------------------------------------
    def _get_question_for_validate(self, level: str, qtype: str) -> Optional[tuple]:
        key = f"{level}_{qtype}"
        if key in self._question_ids_collected:
            return self._question_ids_collected[key]
        qid = self._collect_practice_question(level, qtype)
        if not qid:
            return None
        return self._question_ids_collected[key]

    def test_practice_validate_wrong_answer(self):
        """[Backend] POST /api/v1/practice/validate 错误答案"""
        t0 = time.perf_counter()
        q = self._get_question_for_validate("L1", "word_match")
        if not q:
            self.record("练习题验证(错误答案)", True, "无练习题，跳过", 0)
            return

        qid, question_data = q
        r = self.server.post("/api/v1/practice/validate", json={
            "question_id": qid,
            "answer": ["错误的答案"]
        })
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code == 401:
            self.record("练习题验证(错误答案)", False, "需要认证", elapsed,
                        input='POST /api/v1/practice/validate {"question_id":...,"answer":["错误的答案"]}',
                        expected="HTTP 200 + correct=false",
                        actual="HTTP 401 - 需要认证")
            return

        data = r.json()
        correct_is_false = data.get("correct") is False
        self.record("练习题验证(错误答案)", correct_is_false,
                    f"correct={data.get('correct')} (期望False) HTTP {r.status_code}", elapsed,
                    input='POST /api/v1/practice/validate {"question_id":...,"answer":["错误的答案"]}',
                    expected="correct=false",
                    actual=f"correct={data.get('correct')} HTTP {r.status_code}")

    def test_practice_validate_correct_answer(self):
        """[Backend] POST /api/v1/practice/validate 正确答案"""
        t0 = time.perf_counter()
        q = self._get_question_for_validate("L1", "word_match")
        if not q:
            self.record("练习题验证(正确答案)", True, "无练习题，跳过", 0)
            return

        qid, question_data = q
        answer = question_data.get("answer", [])
        if not answer:
            self.record("练习题验证(正确答案)", True, "答案为空，跳过", 0)
            return

        r = self.server.post("/api/v1/practice/validate", json={
            "question_id": qid,
            "answer": answer
        })
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code == 401:
            self.record("练习题验证(正确答案)", False, "需要认证", elapsed,
                        input='POST /api/v1/practice/validate {"question_id":...,"answer":["..."]}',
                        expected="HTTP 200 + correct=true",
                        actual="HTTP 401 - 需要认证")
            return

        data = r.json()
        correct_is_true = data.get("correct") is True
        self.record("练习题验证(正确答案)", correct_is_true,
                    f"correct={data.get('correct')} feedback={data.get('feedback','')[:20]}", elapsed,
                    input='POST /api/v1/practice/validate {"question_id":...,"answer":["..."]}',
                    expected="correct=true",
                    actual=f"correct={data.get('correct')} feedback={data.get('feedback','')[:20]}")

    def test_practice_validate_not_found(self):
        """[Backend] POST /api/v1/practice/validate 不存在的题目"""
        t0 = time.perf_counter()
        r = self.server.post("/api/v1/practice/validate", json={
            "question_id": 99999,
            "answer": ["答案"]
        })
        elapsed = (time.perf_counter() - t0) * 1000
        # 应该返回 404 或 400，不应该是 correct=true
        not_correct = r.status_code != 200 or r.json().get("correct") is not True
        self.record("练习题验证(不存在题目)", not_correct, f"HTTP {r.status_code}", elapsed,
                    input='POST /api/v1/practice/validate {"question_id":99999,"answer":["答案"]}',
                    expected="HTTP != 200 or correct!=true",
                    actual=f"HTTP {r.status_code}")

    # --------------------------------------------------------
    # [Backend] 内部接口
    # --------------------------------------------------------
    def test_internal_dynamic_fallback(self):
        """[Backend] GET /internal/dynamic_fallback"""
        t0 = time.perf_counter()
        r = self.server.get("/internal/dynamic_fallback")
        elapsed = (time.perf_counter() - t0) * 1000

        if r.status_code != 200:
            self.record("内部动态降级词接口", False, f"HTTP {r.status_code}", elapsed,
                        input='GET /internal/dynamic_fallback',
                        expected="HTTP 200 + items + count fields",
                        actual=f"HTTP {r.status_code}")
            return

        data = r.json()
        has_items = "items" in data
        has_count = "count" in data
        self.record("内部动态降级词接口", has_items and has_count,
                    f"count={data.get('count')} items={len(data.get('items',[]))}", elapsed,
                    input='GET /internal/dynamic_fallback',
                    expected="HTTP 200 + items + count fields",
                    actual=f"count={data.get('count')} items={len(data.get('items',[]))}")

    # --------------------------------------------------------
    # 运行全部测试
    # --------------------------------------------------------
    def run_all(self):
        print("\n" + "=" * 70)
        print("  SignVCB 完整业务 E2E 测试")
        print(f"  Backend: {DEFAULT_SERVER}   Engine: {DEFAULT_ENGINE}")
        print(f"  时间: {datetime.now().isoformat()}")
        print("=" * 70)

        print("\n━━ [Engine 服务] ━━")
        self.test_engine_health()
        self.test_engine_rewrite_no_oov()
        self.test_engine_rewrite_with_oov()
        self.test_engine_rewrite_with_context()
        self.test_engine_rewrite_nmm()
        self.test_engine_rewrite_alignment_ops()
        self.test_engine_normalize()
        self.test_engine_dynamic_fallback()

        print("\n━━ [Backend 服务 - 公开接口] ━━")
        self.test_backend_health()
        self.test_backend_app_config()

        print("\n━━ [Backend 服务 - 认证] ━━")
        self.test_auth_register()
        self.test_auth_login()
        self.test_auth_duplicate_register()
        self.test_auth_bad_password()
        self.test_auth_no_token_rejection()

        print("\n━━ [Backend 服务 - 聊天] ━━")
        self.test_chat_rewrite()
        self.test_chat_rewrite_with_oov()
        self.test_chat_rewrite_with_context()
        self.test_chat_rewrite_oov_event_sequence()
        self.test_chat_tts()
        self.test_chat_tts_speed()
        self.test_chat_suggest()
        self.test_chat_normalize()
        self.test_chat_log_mismatch()

        print("\n━━ [Backend 服务 - 读物] ━━")
        self.test_reading_books()
        self.test_reading_books_l1_filter()
        self.test_reading_books_l2_filter()
        self.test_reading_content()
        self.test_reading_content_not_found()

        print("\n━━ [Backend 服务 - 练习] ━━")
        self.test_practice_question_word_match_l1()
        self.test_practice_question_sentence_order_l2()
        self.test_practice_question_sign_recognize_l3()
        self.test_practice_validate_wrong_answer()
        self.test_practice_validate_correct_answer()
        self.test_practice_validate_not_found()

        print("\n━━ [Backend 服务 - 内部接口] ━━")
        self.test_internal_dynamic_fallback()

        self.print_report()

    def print_report(self):
        results = self.results
        passed = sum(1 for r in results if r.passed)
        failed = sum(1 for r in results if not r.passed)
        total = len(results)

        print("\n" + "=" * 80)
        print(f"  SignVCB E2E 测试结果  |  {passed}/{total} 通过  |  {failed} 失败  |  总延迟: {sum(r.latency_ms for r in results):.0f}ms")
        print("=" * 80)

        # 先输出所有用例的详细信息（按分组）
        current_group = ""
        for r in results:
            # 从名称提取分组
            if "Engine" in r.name:
                group = "[Engine]"
            elif "Backend" in r.name or "App配置" in r.name:
                group = "[Backend-公开]"
            elif "用户" in r.name or "注册" in r.name or "登录" in r.name or "Token" in r.name or "认证" in r.name:
                group = "[Backend-认证]"
            elif "Chat" in r.name or "TTS" in r.name or "Suggest" in r.name or "Normalize" in r.name or "意图" in r.name:
                group = "[Backend-聊天]"
            elif "读物" in r.name or "Reading" in r.name:
                group = "[Backend-读物]"
            elif "练习" in r.name or "Practice" in r.name:
                group = "[Backend-练习]"
            elif "内部" in r.name or "Internal" in r.name:
                group = "[Backend-内部]"
            else:
                group = "[Other]"

            if group != current_group:
                current_group = group
                print(f"\n{'=' * 80}")
                print(f"  {group}")
                print(f"{'=' * 80}")

            icon = "✓" if r.passed else "✗"
            status_str = f"\033[92m✓\033[0m" if r.passed else f"\033[91m✗\033[0m"

            print(f"\n  {status_str} [{r.latency_ms:>6.0f}ms] {r.name}")
            if r.input:
                print(f"      输入:   {r.input}")
            if r.expected:
                print(f"      预期:   {r.expected}")
            if r.actual:
                print(f"      实际:   {r.actual}")
            if r.detail:
                print(f"      详情:   {r.detail}")

        print(f"\n{'=' * 80}")
        print(f"  总计: {passed} 通过  {failed} 失败  总延迟: {sum(r.latency_ms for r in results):.0f}ms")
        print("=" * 80)

        if failed > 0:
            print("\n  [ 失败用例 ]")
            for r in results:
                if not r.passed:
                    print(f"\n  ✗ {r.name}")
                    if r.input:
                        print(f"      输入:   {r.input}")
                    if r.expected:
                        print(f"      预期:   {r.expected}")
                    if r.actual:
                        print(f"      实际:   {r.actual}")
                    if r.detail:
                        print(f"      详情:   {r.detail}")


# ============================================================
# 入口
# ============================================================
def main():
    parser = argparse.ArgumentParser(description="SignVCB E2E 测试")
    parser.add_argument("--server", default=DEFAULT_SERVER, help=f"后端地址 (默认: {DEFAULT_SERVER})")
    parser.add_argument("--engine", default=DEFAULT_ENGINE, help=f"算法引擎地址 (默认: {DEFAULT_ENGINE})")
    args = parser.parse_args()

    suite = TestSuite(args.server, args.engine)
    suite.run_all()

    failed = sum(1 for r in suite.results if not r.passed)
    sys.exit(1 if failed > 0 else 0)


if __name__ == "__main__":
    main()
