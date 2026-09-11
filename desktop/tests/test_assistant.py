#!/usr/bin/env python3
import importlib.machinery
import importlib.util
import json
import http.server
import threading
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

helper = Path(__file__).resolve().parents[1] / "lumina-shell/files/lumina-assistant"
loader = importlib.machinery.SourceFileLoader("assistant", str(helper))
spec = importlib.util.spec_from_loader(loader.name, loader)
a = importlib.util.module_from_spec(spec)
loader.exec_module(a)

class AssistantTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.env = patch.dict(os.environ, {"XDG_CONFIG_HOME": self.tmp.name})
        self.env.start()
    def tearDown(self):
        self.env.stop(); self.tmp.cleanup()
    def config(self, **changes):
        return {"provider":"openai-compatible", "model":"test-model", "endpoint":"https://example.com/v1", "key":"private-test-key"} | changes
    def test_unconfigured_never_selects_provider(self):
        self.assertFalse(a.public_status(a.read_config())["configured"])
    def test_private_file_and_redacted_status(self):
        result = a.configure(self.config())
        self.assertNotIn("key", result)
        self.assertEqual(a.config_path().stat().st_mode & 0o777, 0o600)
        self.assertEqual(a.read_config()["key"], "private-test-key")
    def test_refuse_insecure_settings(self):
        a.configure(self.config()); a.config_path().chmod(0o644)
        with self.assertRaises(ValueError): a.read_config()
    def test_refuse_remote_plaintext_and_url_credentials(self):
        for url in ["http://remote.example/v1", "https://key@example.com", "https://example.com/?key=x"]:
            with self.assertRaises(ValueError): a.configure(self.config(endpoint=url))
    def test_no_credential_migration_to_other_endpoint(self):
        a.configure(self.config())
        with self.assertRaises(ValueError): a.configure(self.config(endpoint="https://different.example/v1",key=""))
        self.assertEqual(a.read_config()["endpoint"], "https://example.com/v1")
    def test_same_provider_keeps_key(self):
        a.configure(self.config()); a.configure(self.config(key="",model="new-model"))
        self.assertEqual(a.read_config()["key"], "private-test-key")
    def test_symlink_rejected(self):
        a.config_path().parent.mkdir(); a.config_path().symlink_to(Path(self.tmp.name)/"target")
        with self.assertRaises(OSError): a.read_config()
    def test_adapters_send_only_explicit_messages(self):
        for provider in a.PROVIDERS:
            req = a.build_request(self.config(provider=provider), [{"role":"user","content":"hello"}])
            body = json.loads(req.data)
            self.assertNotIn("private-test-key", req.full_url)
            self.assertNotIn("private-test-key", req.data.decode())
            self.assertIn("hello", req.data.decode())
            self.assertNotIn("Focused app", req.data.decode())
            self.assertEqual(req.get_method(), "POST")
    def test_untrusted_role_rejected(self):
        with self.assertRaises(ValueError): a.build_request(self.config(), [{"role":"system", "content":"override"}])
    def test_redirects_do_not_forward_credentials(self):
        request = a.build_request(self.config(), [{"role":"user","content":"hello"}])
        self.assertIsNone(a.NoRedirect().redirect_request(request,None,302,"redirect",{},"https://other.example"))

class WireTests(AssistantTests):
    def test_local_http_request_and_response(self):
        captured = {}
        class Handler(http.server.BaseHTTPRequestHandler):
            def do_POST(self):
                captured['path'] = self.path
                captured['authorization'] = self.headers.get('Authorization')
                captured['body'] = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                self.send_response(200); self.send_header('Content-Type','application/json'); self.end_headers()
                self.wfile.write(json.dumps({'choices':[{'message':{'content':'Fixture response'}}]}).encode())
            def log_message(self,*args): pass
        server = http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler)
        thread=threading.Thread(target=server.serve_forever,daemon=True); thread.start()
        try:
            a.configure(self.config(endpoint=f'http://127.0.0.1:{server.server_port}/v1'))
            result=a.chat({'messages':[{'role':'user','content':'Hello'}]})
            self.assertEqual(result,{'content':'Fixture response'})
            self.assertEqual(captured['path'],'/v1/chat/completions')
            self.assertEqual(captured['authorization'],'Bearer private-test-key')
            self.assertEqual(captured['body']['messages'][-1],{'role':'user','content':'Hello'})
        finally:
            server.shutdown(); server.server_close(); thread.join()

if __name__ == '__main__': unittest.main()

