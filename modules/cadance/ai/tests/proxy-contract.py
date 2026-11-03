#!/usr/bin/env python3
"""Contract tests for the litellm proxy this module configures.

The proxy is the translation layer between five upstreams and clients that
speak three different dialects, and every guarantee we rely on is litellm's to
keep or to break silently between releases:

  - a parameter an upstream cannot express is dropped, and only that parameter
  - a client's `thinking` block reaches Anthropic unchanged
  - a deployment's `cache_control` becomes Anthropic's automatic caching
  - `/v1/responses` stays on the Responses API, `/v1/chat/completions` does not
    get translated onto it behind the client's back

So this pins them. A stub upstream records exactly what the proxy sends, and
each case asserts on that record rather than on the proxy's reply: what matters
is the request that leaves, not the answer that comes back.

    python3 proxy-contract.py --litellm /path/to/litellm

Everything is local -- the stub is on loopback and the cost map is the packaged
one -- so it runs inside the Nix sandbox with no network.
"""

import argparse
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ANTHROPIC_MODEL = "anthropic/claude-haiku-5-5"
OPENAI_MODEL = "openai/gpt-6-luna"


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


class Stub:
    """An upstream that records what it was sent and answers plausibly."""

    def __init__(self):
        self.requests = []
        self.lock = threading.Lock()
        stub = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *args):
                pass

            def do_POST(self):
                length = int(self.headers.get("content-length") or 0)
                raw = self.rfile.read(length).decode("utf-8", "replace")
                with stub.lock:
                    stub.requests.append(
                        {"path": self.path, "body": json.loads(raw or "{}")}
                    )
                if "responses" in self.path:
                    payload = {
                        "id": "resp_1",
                        "object": "response",
                        "created_at": 0,
                        "model": "stub",
                        "status": "completed",
                        "output": [
                            {
                                "type": "message",
                                "id": "m1",
                                "role": "assistant",
                                "status": "completed",
                                "content": [
                                    {
                                        "type": "output_text",
                                        "text": "ok",
                                        "annotations": [],
                                    }
                                ],
                            }
                        ],
                        "usage": {
                            "input_tokens": 1,
                            "output_tokens": 1,
                            "total_tokens": 2,
                        },
                    }
                elif "messages" in self.path:
                    payload = {
                        "id": "msg_1",
                        "type": "message",
                        "role": "assistant",
                        "model": "stub",
                        "content": [{"type": "text", "text": "ok"}],
                        "stop_reason": "end_turn",
                        "usage": {"input_tokens": 1, "output_tokens": 1},
                    }
                else:
                    payload = {
                        "id": "chatcmpl-1",
                        "object": "chat.completion",
                        "created": 0,
                        "model": "stub",
                        "choices": [
                            {
                                "index": 0,
                                "message": {"role": "assistant", "content": "ok"},
                                "finish_reason": "stop",
                            }
                        ],
                        "usage": {
                            "prompt_tokens": 1,
                            "completion_tokens": 1,
                            "total_tokens": 2,
                        },
                    }
                body = json.dumps(payload).encode()
                self.send_response(200)
                self.send_header("content-type", "application/json")
                self.send_header("content-length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

        self.server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        self.port = self.server.server_address[1]
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()

    @property
    def url(self):
        return f"http://127.0.0.1:{self.port}"

    def take(self):
        with self.lock:
            taken = self.requests[:]
            self.requests.clear()
        return taken

    def close(self):
        self.server.shutdown()


def fixture_config(stub):
    """The deployment shapes the module generates, pointed at the stub."""

    def anthropic(**extra):
        return {
            "model": ANTHROPIC_MODEL,
            "api_key": "sk-dummy",
            "api_base": stub.url,
            **extra,
        }

    return {
        "litellm_settings": {"drop_params": False},
        "model_list": [
            {
                "model_name": "drop",
                "litellm_params": anthropic(additional_drop_params=["store"]),
            },
            {"model_name": "plain", "litellm_params": anthropic()},
            {
                "model_name": "pinned",
                "litellm_params": anthropic(
                    thinking={"type": "adaptive"}, output_config={"effort": "high"}
                ),
            },
            {
                "model_name": "cache-auto",
                "litellm_params": anthropic(cache_control={"type": "ephemeral"}),
            },
            {
                "model_name": "openai",
                "litellm_params": {
                    "model": OPENAI_MODEL,
                    "api_key": "sk-dummy",
                    "api_base": f"{stub.url}/v1",
                },
            },
        ],
    }


class Proxy:
    def __init__(self, litellm, config, workdir):
        self.port = free_port()
        self.url = f"http://127.0.0.1:{self.port}"
        cfg = os.path.join(workdir, "config.json")
        with open(cfg, "w") as f:
            json.dump(config, f)
        self.log = open(os.path.join(workdir, "proxy.log"), "wb")
        env = dict(
            os.environ,
            HOME=workdir,
            LITELLM_DANGEROUSLY_PERMIT_WEAK_OR_UNSET_MASTER_KEY="true",
            # Pin to the packaged cost map so the check needs no network and
            # does not drift with litellm's remote map.
            LITELLM_LOCAL_MODEL_COST_MAP="True",
            **{
                key: "sk-dummy"
                for key in (
                    "ANTHROPIC_API_KEY",
                    "OPENAI_API_KEY",
                    "XAI_API_KEY",
                    "DEEPSEEK_API_KEY",
                    "FIREWORKS_AI_API_KEY",
                )
            },
        )
        self.proc = subprocess.Popen(
            [litellm, "--config", cfg, "--host", "127.0.0.1", "--port", str(self.port)],
            stdout=self.log,
            stderr=subprocess.STDOUT,
            env=env,
        )
        self._await_ready()

    def _await_ready(self, timeout=120):
        deadline = time.time() + timeout
        while time.time() < deadline:
            if self.proc.poll() is not None:
                raise SystemExit(f"litellm exited with {self.proc.returncode}")
            try:
                with urllib.request.urlopen(
                    f"{self.url}/health/readiness", timeout=2
                ):
                    return
            except (urllib.error.URLError, ConnectionError):
                time.sleep(0.5)
        raise SystemExit("litellm did not become ready")

    def post(self, path, payload):
        request = urllib.request.Request(
            f"{self.url}{path}",
            data=json.dumps(payload).encode(),
            headers={"content-type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=60) as response:
                return response.status, json.loads(response.read() or b"{}")
        except urllib.error.HTTPError as error:
            return error.code, json.loads(error.read() or b"{}")

    def stop(self):
        self.proc.terminate()
        try:
            self.proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            self.proc.kill()
        self.log.close()


CHAT = "/v1/chat/completions"


def chat(model, system=False, **extra):
    messages = [{"role": "user", "content": "hi"}]
    if system:
        messages.insert(0, {"role": "system", "content": "You are terse."})
    return (CHAT, {"model": model, "messages": messages, **extra})


def cases():
    """(name, request, check) where check(status, upstream_requests) -> problems."""

    def one(requests):
        return requests[0]["body"] if requests else None

    def expect_upstream(status, requests, path, predicate, description):
        problems = []
        if status != 200:
            problems.append(f"client got HTTP {status}, expected 200")
        if len(requests) != 1:
            problems.append(f"upstream saw {len(requests)} requests, expected 1")
            return problems
        if not requests[0]["path"].startswith(path):
            problems.append(f"upstream path {requests[0]['path']}, expected {path}")
        if not predicate(requests[0]["body"]):
            problems.append(f"{description}: {json.dumps(requests[0]['body'])[:300]}")
        return problems

    def effort_is(level):
        def check(body):
            return (
                (body.get("thinking") or {}).get("type") == "adaptive"
                and (body.get("output_config") or {}).get("effort") == level
            )
        return check

    return [
        (
            "store is dropped for an upstream that lacks it",
            chat("drop", store=True),
            lambda status, requests: expect_upstream(
                status, requests, "/v1/messages", lambda b: "store" not in b, "store reached the upstream"
            ),
        ),
        (
            "a parameter nobody can express is still refused",
            chat("drop", seed=42),
            lambda status, requests: (
                [] if status == 400 and not requests else [f"client got HTTP {status} with {len(requests)} upstream requests, expected 400 and none"]
            ),
        ),
        # Adaptive models take no `budget_tokens`: litellm rewrites a client's
        # enabled-budget block into adaptive thinking plus an effort derived from
        # the budget. 1024 lands on the lowest one.
        (
            "a client thinking budget becomes adaptive thinking on an adaptive model",
            chat("plain", thinking={"type": "enabled", "budget_tokens": 1024}),
            lambda status, requests: expect_upstream(
                status,
                requests,
                "/v1/messages",
                lambda b: (b.get("thinking") or {}).get("type") == "adaptive"
                and (b.get("output_config") or {}).get("effort") == "low",
                "client budget not translated to adaptive thinking",
            ),
        ),
        (
            "reasoning_effort high becomes adaptive thinking at effort high",
            chat("plain", reasoning_effort="high"),
            lambda status, requests: expect_upstream(
                status, requests, "/v1/messages", effort_is("high"), "thinking/effort not derived from reasoning_effort"
            ),
        ),
        (
            "a deployment-level cache_control becomes Anthropic automatic caching",
            chat("cache-auto"),
            lambda status, requests: expect_upstream(
                status,
                requests,
                "/v1/messages",
                lambda b: b.get("cache_control") == {"type": "ephemeral"},
                "no top-level cache_control upstream",
            ),
        ),
        # The other half of the same rewrite: on an adaptive model the effort a
        # deployment pins outranks the one derived from the client's budget, so
        # a pinned thinking block is closer to a constraint than to a default.
        (
            "a deployment's pinned effort outranks the client's thinking budget",
            chat("pinned", thinking={"type": "enabled", "budget_tokens": 1024}),
            lambda status, requests: expect_upstream(
                status,
                requests,
                "/v1/messages",
                lambda b: (b.get("thinking") or {}).get("type") == "adaptive"
                and (b.get("output_config") or {}).get("effort") == "high",
                "client budget displaced the pinned effort",
            ),
        ),
        (
            "the messages endpoint reaches the upstream unchanged",
            (
                "/v1/messages",
                {
                    "model": "plain",
                    "max_tokens": 64,
                    "cache_control": {"type": "ephemeral"},
                    "messages": [{"role": "user", "content": "hi"}],
                },
            ),
            lambda status, requests: expect_upstream(
                status,
                requests,
                "/v1/messages",
                lambda b: b.get("cache_control") == {"type": "ephemeral"},
                "top-level cache_control not forwarded",
            ),
        ),
        (
            "the responses endpoint stays on the Responses API",
            ("/v1/responses", {"model": "openai", "input": "hi"}),
            lambda status, requests: expect_upstream(
                status, requests, "/v1/responses", lambda b: True, ""
            ),
        ),
        (
            "chat completions is not translated onto Responses",
            chat("openai"),
            lambda status, requests: expect_upstream(
                status, requests, "/v1/chat/completions", lambda b: True, ""
            ),
        ),
    ]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--litellm", default=shutil.which("litellm"))
    args = parser.parse_args()
    if not args.litellm:
        raise SystemExit("litellm not found; pass --litellm")

    workdir = tempfile.mkdtemp(prefix="litellm-contract-")
    stub = Stub()
    proxy = None
    failures = []
    try:
        proxy = Proxy(args.litellm, fixture_config(stub), workdir)
        for name, (path, payload), check in cases():
            stub.take()
            status, _ = proxy.post(path, payload)
            problems = check(status, stub.take())
            if problems:
                failures.append((name, problems))
                print(f"FAIL  {name}")
            else:
                print(f"ok    {name}")
    finally:
        if proxy:
            proxy.stop()
        stub.close()
        if failures:
            with open(os.path.join(workdir, "proxy.log"), "rb") as log:
                print("\n--- proxy log (tail) ---")
                print(log.read()[-4000:].decode("utf-8", "replace"))

    if failures:
        print(f"\n{len(failures)} case(s) failed:")
        for name, problems in failures:
            for problem in problems:
                print(f"  {name}: {problem}")
        return 1
    print("\nall cases passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
