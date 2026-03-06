import xml.etree.ElementTree as ET
import json, re, os

FONT_PATH = os.path.join(os.path.dirname(__file__), "EMSCapitol.svg")
OUTPUT_PATH = os.path.join(os.path.dirname(__file__),
                           "..", "CursiveTrace", "Resources", "cursive_paths.json")
VIEWBOX_W, VIEWBOX_H = 200, 300
PAD_X, PAD_Y = 10, 20

def parse_path(d):
    """Return list of {type, x, y} for M and L commands only."""
    commands = []
    for m in re.finditer(r'([ML])\s*([-\d.]+)\s+([-\d.]+)', d):
        cmd, x, y = m.group(1), float(m.group(2)), float(m.group(3))
        commands.append({'type': 'moveTo' if cmd == 'M' else 'lineTo',
                         'x': x, 'y': y})
    return commands

def normalize(commands):
    xs = [c['x'] for c in commands]
    ys = [c['y'] for c in commands]
    min_x, max_x = min(xs), max(xs)
    min_y, max_y = min(ys), max(ys)
    gw, gh = max_x - min_x, max_y - min_y

    scale = min((VIEWBOX_W - 2*PAD_X) / gw, (VIEWBOX_H - 2*PAD_Y) / gh)
    ox = (VIEWBOX_W - gw * scale) / 2       # horizontal center offset
    oy = (VIEWBOX_H - gh * scale) / 2       # vertical center offset

    segments = []
    for c in commands:
        # Flip y: font y-up -> iOS y-down
        x_ios = round((c['x'] - min_x) * scale + ox, 2)
        y_ios = round((max_y - c['y']) * scale + oy, 2)
        segments.append({
            'type': c['type'],
            'point': {'x': x_ios, 'y': y_ios},
            'control1': None,
            'control2': None
        })
    return segments

tree = ET.parse(FONT_PATH)
glyphs = {g.get('unicode'): g.get('d', '')
          for g in tree.iter()
          if g.tag.endswith('glyph') and g.get('unicode', '') in 'abcdefghijklmnopqrstuvwxyz'}

letters = []
for char in 'abcdefghijklmnopqrstuvwxyz':
    d = glyphs.get(char, '')
    if not d:
        print(f"  MISSING: {char}"); continue
    cmds = parse_path(d)
    segs = normalize(cmds)
    letters.append({'character': char,
                    'viewBox': {'width': VIEWBOX_W, 'height': VIEWBOX_H},
                    'segments': segs})
    print(f"  {char}: {len(segs)} segments")

with open(OUTPUT_PATH, 'w') as f:
    json.dump(letters, f, indent=2)
print(f"\nWrote {len(letters)} letters -> {OUTPUT_PATH}")
