"""Isolated local HTTP fixture: valid, corrupt, interrupted and retried downloads."""
import http.server, subprocess, threading, time
from pathlib import Path
from build_small_packs import OUT
GODOT=Path('C:/Users/rlagk/Documents/Codex/2026-09-23/d-codex/work/godot_4_7_2/Godot_v4.7.2-stable_win64_console.exe')
class Handler(http.server.BaseHTTPRequestHandler):
 def log_message(self,*_):pass
 def do_GET(self):
  if self.path not in ['/good','/corrupt','/slow']:self.send_error(404);return
  path=OUT/'animal-packs/pet-otter.pck'
  self.send_response(200);self.send_header('Content-Length',str(path.stat().st_size));self.end_headers()
  try:
   with path.open('rb') as f:
    first=True
    while data:=f.read(65536):
     if self.path=='/corrupt' and first:data=bytes([data[0]^1])+data[1:]
     first=False;self.wfile.write(data)
     if self.path=='/slow':time.sleep(.1)
  except (ConnectionError,OSError):pass
if __name__=='__main__':
 server=http.server.ThreadingHTTPServer(('127.0.0.1',0),Handler)
 threading.Thread(target=server.serve_forever,daemon=True).start()
 cache=OUT/('download-test-'+str(time.time_ns()))
 result=subprocess.run([str(GODOT),'--headless','--main-pack',str(OUT/'DesktopFriends.pck'),'--script','res://tests/animal_pack_download_test.gd','--','--test-url=http://127.0.0.1:'+str(server.server_port),'--test-cache='+str(cache)],cwd=OUT,timeout=180,capture_output=True,text=True,encoding='utf-8',errors='replace')
 log=result.stdout+result.stderr
 (OUT/'DOWNLOAD-TEST.txt').write_text(log,encoding='utf-8');print(log,flush=True)
 server.shutdown()
 raise SystemExit(result.returncode or (1 if 'ERROR:' in log else 0))
