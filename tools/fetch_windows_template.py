"""Fetch only the official Windows release executable from Godot's template ZIP."""
import io
import urllib.request
import zipfile
from pathlib import Path

URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'
class RemoteZip(io.RawIOBase):
    def __init__(self):
        request = urllib.request.Request(URL, method='HEAD')
        with urllib.request.urlopen(request, timeout=60) as response:
            self.url = response.url
            self.length = int(response.headers['Content-Length'])
        self.position = 0
    def seekable(self): return True
    def readable(self): return True
    def tell(self): return self.position
    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else (self.position if whence == 1 else self.length) + offset
        return self.position
    def read(self, size=-1):
        end = self.length if size < 0 else min(self.length, self.position + size)
        if end <= self.position: return b''
        request = urllib.request.Request(self.url, headers={'Range': f'bytes={self.position}-{end-1}'})
        with urllib.request.urlopen(request, timeout=180) as response:
            if response.status != 206: raise RuntimeError('Server did not honor range request')
            data = response.read()
        if len(data) != end-self.position: raise RuntimeError('Incomplete ZIP range')
        self.position=end
        return data

destination=Path(__file__).resolve().parents[1]/'builds/template-4.7.2'
destination.mkdir(parents=True, exist_ok=True)
with zipfile.ZipFile(RemoteZip()) as archive:
    candidates=[n for n in archive.namelist() if n.endswith('/windows_release_x86_64.exe')]
    if len(candidates)!=1: raise RuntimeError(f'Expected Windows template: {candidates}')
    data=archive.read(candidates[0])  # zipfile verifies the entry CRC.
    (destination/'windows_release_x86_64.exe').write_bytes(data)
    print('WINDOWS_RELEASE_BYTES=',len(data),flush=True)
