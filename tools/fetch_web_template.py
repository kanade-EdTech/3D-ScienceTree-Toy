"""Extract only the missing official template using HTTP byte ranges."""
import io
import urllib.request
import zipfile
from pathlib import Path

URL = 'https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'

class RemoteArchive(io.RawIOBase):
    def __init__(self):
        response = urllib.request.urlopen(urllib.request.Request(URL, method='HEAD'), timeout=40)
        self.url = response.url
        self.size = int(response.headers['Content-Length'])
        self.position = 0

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.size + offset
        return self.position

    def tell(self):
        return self.position

    def seekable(self):
        return True

    def read(self, size=-1):
        size = min(size if size >= 0 else self.size-self.position, self.size-self.position)
        if size <= 0:
            return b''
        request = urllib.request.Request(self.url, headers={'Range':f'bytes={self.position}-{self.position+size-1}'})
        with urllib.request.urlopen(request, timeout=90) as response:
            if response.status != 206:
                raise RuntimeError('Download server did not honor byte ranges')
            data = response.read(size)
        self.position += len(data)
        return data

archive = zipfile.ZipFile(RemoteArchive())
member = next(n for n in archive.namelist() if n.endswith('/web_nothreads_release.zip'))
destination = Path(__file__).resolve().parent/'export_templates/web_nothreads_release.zip'
destination.parent.mkdir(parents=True, exist_ok=True)
destination.write_bytes(archive.read(member))
with zipfile.ZipFile(destination) as template:
    assert 'godot.wasm' in template.namelist()
print('Official single-threaded release template saved:', destination.stat().st_size, 'bytes')
