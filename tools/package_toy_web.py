"""Package only the exported Web runtime, with index.html at ZIP root."""
import hashlib
import json
import re
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
version_match = re.search(r'^config/version="([0-9A-Za-z.+-]+)"$', (ROOT/'project.godot').read_text(encoding='utf-8'), re.MULTILINE)
assert version_match, 'Project version is missing'
version = version_match.group(1)
web = ROOT/'build/toy-web'
html = (web/'index.html').read_text(encoding='utf-8')
assert len(html.encode('utf-8')) < 1_000_000
assert 'const GODOT_THREADS_ENABLED = false;' in html
assert not list(web.glob('*.service.worker.js')), 'Unexpected service worker in output'
for required in ['index.html','index.js','index.wasm','index.pck']:
    assert (web/required).is_file(), required
shutil.copyfile(ROOT/'assets/fonts/OFL.txt',web/'FONT-LICENSE.txt')
destination = ROOT/f'dist/3D-TechnologyTree-{version}-Toy-Web.zip'
destination.parent.mkdir(exist_ok=True)
files = sorted(f for f in web.glob('index.*') if f.suffix != '.import') + [web/'FONT-LICENSE.txt']
entries = [(path, path.name) for path in files]
# Model credits and runtime licenses must travel with the exported game.
for relative in [
    'LICENSE', 'LICENSE-CC-BY-4.0.txt', 'LICENSES.md', 'COPYRIGHT.md',
    'assets/models/poly_pizza/CREDITS.md',
    'assets/models/poly_pizza/licenses/CC-BY-3.0.txt',
    'assets/models/poly_pizza/licenses/CC0-1.0.txt',
]:
    source = ROOT/relative
    assert source.is_file(), f'Missing distribution notice: {relative}'
    entries.append((source, relative))
with zipfile.ZipFile(destination,'w',zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
    for path, name in entries:
        archive.write(path,name)
manifest = {'version':version,'archive':destination.name,'zip_bytes':destination.stat().st_size,
            'sha256':hashlib.sha256(destination.read_bytes()).hexdigest(),
            'files':{name:path.stat().st_size for path,name in entries},'threads':False,'service_worker':False}
(destination.parent/'toy-web-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
print(json.dumps(manifest,indent=2))
