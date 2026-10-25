"""Local Toy-like subpath/iframe preview, without COOP or COEP headers."""
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

ROOT = Path(__file__).resolve().parents[1]/'build/toy-web'
PREFIX = '/toy/technology-tree/'

class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT), **kwargs)

    def translate_path(self, path):
        if path.startswith(PREFIX):
            path = '/' + path[len(PREFIX):]
        return super().translate_path(path)

    def do_GET(self):
        if urlsplit(self.path).path == '/preview.html':
            html = ('<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
                    '<title>Toy 内嵌预览</title><link rel="icon" href="' + PREFIX + 'index.icon.png"><style>html,body{margin:0;height:100%;background:#090d16}iframe{display:block;width:100%;height:100%;border:0}</style>'
                    '<iframe title="3D 科技树" allow="fullscreen; autoplay" src="' + PREFIX + 'index.html"></iframe></html>').encode()
            self.send_response(200)
            self.send_header('Content-Type', 'text/html; charset=utf-8')
            self.send_header('Content-Length', str(len(html)))
            self.end_headers()
            self.wfile.write(html)
            return
        super().do_GET()

print('Local preview: http://127.0.0.1:8876/preview.html', flush=True)
ThreadingHTTPServer(('127.0.0.1',8876),Handler).serve_forever()
