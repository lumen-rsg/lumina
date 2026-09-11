#!/usr/bin/env python3
"""Exercise the real QML -> stdin helper -> local HTTP -> QML path."""
import http.server
import json
import os
from pathlib import Path
import subprocess
import shutil
import tempfile
import threading

class Handler(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body=json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        assert body['messages'][-1]['content']=='Hello from QML'
        assert self.headers.get('Authorization')=='Bearer fixture-key'
        self.send_response(200); self.send_header('Content-Type','application/json'); self.end_headers()
        self.wfile.write(b'{"choices":[{"message":{"content":"Fixture response"}}]}')
    def log_message(self,*args): pass

root=Path(__file__).resolve().parent
server=http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler)
thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
try:
    with tempfile.TemporaryDirectory(prefix='lumina-assistant-qa-') as tmp:
        fixture=Path(tmp)/'shell'
        (fixture/'services').mkdir(parents=True)
        shutil.copyfile(root/'AssistantFixture.qml',fixture/'shell.qml')
        shutil.copyfile(root.parent/'lumina-shell/shell/services/Assistant.qml',fixture/'services/Assistant.qml')
        env=os.environ | {'XDG_CONFIG_HOME':tmp, 'XDG_RUNTIME_DIR':tmp, 'QT_QPA_PLATFORM':'offscreen', 'LANG':'C.UTF-8', 'LC_ALL':'C.UTF-8', 'LUMINA_ASSISTANT_HELPER':str(root.parent/'lumina-shell/files/lumina-assistant'), 'LUMINA_QA_AI_ENDPOINT':f'http://127.0.0.1:{server.server_port}/v1'}
        try:
            result=subprocess.run(['quickshell','-p',str(fixture)],env=env,text=True,capture_output=True,timeout=15)
        except subprocess.TimeoutExpired as error:
            raise SystemExit((error.stdout or b'').decode() + (error.stderr or b'').decode())
        output=result.stdout+result.stderr
        if result.returncode or 'ASSISTANT_FIXTURE_PASS' not in output: raise SystemExit(output)
        assert 'fixture-key' not in output
        saved=Path(tmp)/'lumina/assistant.json'
        assert saved.stat().st_mode & 0o777 == 0o600
        print('QML assistant integration passed')
finally:
    server.shutdown();server.server_close();thread.join()
