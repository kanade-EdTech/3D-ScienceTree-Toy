"""Keep the open-font glyphs used by the game; run after editing game text."""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT/'tools/.font-build-deps'))
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont
from fontTools import subset

font = TTFont(ROOT/'tools/font-source/NotoSansSC.ttf')
font = instantiateVariableFont(font, {'wght': 400}, inplace=True)
text = ''.join(chr(n) for n in range(32,127)) + '…＋－↔↑↓←→°'
for pattern in ['scripts/*.gd', 'scenes/*.tscn', 'tech_tree.json', 'web/*.html']:
    for path in ROOT.glob(pattern):
        text += path.read_text(encoding='utf-8')
options = subset.Options()
options.name_IDs = ['*']
subsetter = subset.Subsetter(options=options)
subsetter.populate(text=text)
subsetter.subset(font)
output = ROOT/'assets/fonts/TechnologyTreeSC.ttf'
font.save(output)
print('Chinese font subset:', output.stat().st_size, 'bytes;',len(set(text)),'requested characters')
