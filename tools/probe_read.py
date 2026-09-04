#!/usr/bin/env python3
"""Read back a "ground probe" save and rebuild the occupied-coordinate maps.

Input: one or more XML save files produced after playing probe_experiment saves
(convert the game's save back to XML the same way your other files were made).

For every location it reads:
  - surviving terrainFeatures of type HoeDirt   = valid natural ground
  - objects named 'Artifact Spot' (590)         = water conversion / diggable dig spots
  - objects named 'Seed Spot' (88)              = desert sand tiles
  - litter (Stone/Weeds/Twig) + clumps          = game-side ground confirmation
Outputs per zone:
  <out>/probes_<zone>.png     visual tile map
  <out>/probes_<zone>.csv     every surviving coordinate
  <out>/probe_summary.md      sizes: content bbox, per-row spans, fill

Usage: python3 tools/probe_read.py SAVE1.xml [SAVE2.xml ...] [--out DIR] [--probed-only] [--rect 151x151]
"""
import argparse, os, re, sys, zlib, struct
import xml.etree.ElementTree as ET

XSI = '{http://www.w3.org/2001/XMLSchema-instance}type'

def png_write(path, w, h, pixels):
    raw = b''.join(b'\x00' + bytes(row) for row in pixels)
    def chunk(tag, data):
        c = tag + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
    png = (b'\x89PNG\r\n\x1a\n'
           + chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
           + chunk(b'IDAT', zlib.compress(raw, 6))
           + chunk(b'IEND', b''))
    open(path, 'wb').write(png)

def render_zone(name, ground, water, seed, litter, probes_rect, outdir, scale=4):
    maxx = max([x for x, y in ground] + [x for x, y in water] + [x for x, y in seed]
               + [x for x, y in litter] + [probes_rect[0] - 1, 0])
    maxy = max([y for x, y in ground] + [y for x, y in water] + [y for x, y in seed]
               + [y for x, y in litter] + [probes_rect[1] - 1, 0])
    w, h = (maxx + 1) * scale, (maxy + 1) * scale
    g = set(ground); wa = set(water); se = set(seed); li = set(litter)
    rows = []
    for ty in range(maxy + 1):
        row = bytearray()
        for tx in range(maxx + 1):
            t = (tx, ty)
            if t in g:    col = (74, 179, 74)
            elif t in li: col = (200, 90, 40)
            elif t in wa: col = (50, 110, 220)
            elif t in se: col = (230, 200, 90)
            elif tx < probes_rect[0] and ty < probes_rect[1]: col = (35, 35, 40)
            else: col = (16, 16, 18)
            row.extend(col * scale)
        rows.append(bytes(row))
    png_write(os.path.join(outdir, f'probes_{name}.png'), w, h, rows)

def analyze(path, probes_rect_default):
    root = ET.parse(path).getroot()
    res = {}
    for gl in root.find('locations'):
        name = gl.findtext('name') or '?'
        ground, other_tf = [], 0
        tf = gl.find('terrainFeatures')
        if tf is not None:
            for it in tf:
                k = it.find('key'); v = it.find('value')
                if k is None or v is None or not len(v): continue
                vv = v[0]
                t = vv.get(XSI) or vv.tag
                if t == 'HoeDirt':
                    kk = k[0]
                    ground.append((int(kk.findtext('X')), int(kk.findtext('Y'))))
                else:
                    other_tf += 1
        water, seed, litter, clumps = [], [], [], 0
        objs = gl.find('objects')
        if objs is not None:
            for it in objs:
                v = it.find('value'); k = it.find('key')
                if v is None or k is None or not len(v) or not len(k): continue
                vv = v[0]
                nm = (vv.findtext('name') or '').strip()
                try:
                    kk = k[0]; x, y = int(kk.findtext('X')), int(kk.findtext('Y'))
                except Exception:
                    continue
                if nm == 'Artifact Spot': water.append((x, y))
                elif nm == 'Seed Spot': seed.append((x, y))
                elif nm in ('Stone', 'Weeds', 'Twig'): litter.append((x, y))
        rc = gl.find('resourceClumps')
        if rc is not None:
            clumps = len(list(rc))
        total = len(ground)
        if total == 0 and other_tf == 0 and not water and not seed and not litter and not clumps:
            continue
        res[name] = dict(ground=ground, water=water, seed=seed, litter=litter,
                        clumps=clumps, other_tf=other_tf, probes=probes_rect_default)
    return res

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('saves', nargs='+')
    ap.add_argument('--out', default='probe_results')
    ap.add_argument('--rect', default='151x151', help='probe rectangle WxH used by probe_save.py (max+1)')
    ap.add_argument('--probed-only', action='store_true', help='only zones where ground survived')
    a = ap.parse_args()
    RW, RH = map(int, a.rect.lower().split('x'))
    os.makedirs(a.out, exist_ok=True)

    lines = ['# Probe results\n']
    for p in a.saves:
        res = analyze(p, (RW, RH))
        tag = os.path.basename(p)
        lines.append(f"\n## {tag}\n")
        lines.append("| zone | ground tiles | ground bbox | area (W×H) | pruned | fill % | artifact spots (water) | seed spots (sand) | fresh litter | clumps |")
        lines.append("|---|--:|---|---|--:|--:|--:|--:|--:|--:|")
        for name, r in sorted(res.items(), key=lambda kv: -len(kv[1]['ground'])):
            g = r['ground']
            if a.probed_only and len(g) == 0:
                continue
            if g:
                x0 = min(x for x, y in g); x1 = max(x for x, y in g)
                y0 = min(y for x, y in g); y1 = max(y for x, y in g)
                bbox = f"X {x0}–{x1}, Y {y0}–{y1}"; w, h = x1 - x0 + 1, y1 - y0 + 1
            else:
                bbox, w, h = '—', 0, 0
            rect = r['probes'][0] * r['probes'][1]
            probed = len(g) >= 500 or len(g) == rect
            pruned = f"{rect - len(g)}" if probed else '—'
            fill = f"{100.0 * len(g) / rect:.1f}%" if probed else '—'
            note = ' **NO PRUNING HAPPENED**' if len(g) == rect else ''
            lines.append(f"| {name} | {len(g)} | {bbox} | {w}×{h}{note} | {pruned} | {fill} | {len(r['water'])} | {len(r['seed'])} | {len(r['litter'])} | {r['clumps']} |")
            if g:
                render_zone(name, set(g), set(r['water']), set(r['seed']), set(r['litter']), r['probes'], a.out)
                with open(os.path.join(a.out, f'probes_{name}.csv'), 'w') as f:
                    f.write('x,y\n')
                    for x, y in sorted(g, key=lambda t: (t[1], t[0])):
                        f.write(f'{x},{y}\n')
                    for x, y in sorted(set(r['water'])): f.write(f'{x},{y},water\n')
                    for x, y in sorted(set(r['seed'])): f.write(f'{x},{y},sand\n')
                    for x, y in sorted(set(r['litter'])): f.write(f'{x},{y},litter\n')
    txt = '\n'.join(lines)
    open(os.path.join(a.out, 'probe_summary.md'), 'w').write(txt + '\n')
    print(txt)

if __name__ == '__main__':
    main()
