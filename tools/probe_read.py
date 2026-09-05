#!/usr/bin/env python3
"""Read back a "ground probe" save and rebuild the occupied-coordinate maps.

Basic mode (works on any save):
  per location: surviving probes (HoeDirt/Grass/Tree terrainFeatures),
  bushes (grass->bush conversions), water artifact spots, sand seed spots,
  litter, clumps -> PNG tile map + CSV + summary table.

Compare mode (--baseline ORIGINAL_PROBE.xml):
  given the un-played probe file, classifies EVERY probe coordinate of the
  baseline into: kept / removed / converted-to-bush / converted-to-*, and
  prints the pruning gate shape relative to the played player position
  (this reveals the ~30-tile player-distance gate of HoeDirt.checkForRemoval
  and lets you plan spawn sweeps - mode C of tools/probe_fill.bat).

Usage:
  python3 tools/probe_read.py played.xml [played2.xml ...] [--out DIR]
         [--baseline probeNN.xml [probeNN2.xml ...]] [--rect 151x151] [--probed-only]
"""
import argparse, os, re, sys, zlib, struct
import xml.etree.ElementTree as ET

XSI = '{http://www.w3.org/2001/XMLSchema-instance}type'
PROBE_TYPES = ('HoeDirt', 'Grass', 'Tree')

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

def render_zone(name, kept, lost, converted, extra, probes_rect, outdir, scale=4):
    maxx = probes_rect[0] - 1
    maxy = probes_rect[1] - 1
    w, h = (maxx + 1) * scale, (maxy + 1) * scale
    k = set(kept); l = set(lost); c = set(converted); e = set(extra)
    rows = []
    for ty in range(maxy + 1):
        row = bytearray()
        for tx in range(maxx + 1):
            t = (tx, ty)
            if t in k:    col = (74, 179, 74)     # ground, kept
            elif t in c:  col = (185, 122, 48)    # probe -> bush/conversion
            elif t in l:  col = (70, 70, 82)       # probe pruned (not ground)
            elif t in e:  col = (50, 110, 220)    # extra marker (water spot/sand/litter)
            else:         col = (16, 16, 18)
            row.extend(col * scale)
        rows.append(bytes(row))
    png_write(os.path.join(outdir, f'probes_{name}.png'), w, h, rows)

def grab_locations(root):
    out = {}
    for gl in root.find('locations'):
        name = gl.findtext('name') or '?'
        d = dict(probes={t: set() for t in PROBE_TYPES}, bushes=set(), water=set(), seed=set(),
                  litter=set(), clumps=set(), other_tf=set(), objects={})
        tf = gl.find('terrainFeatures')
        if tf is not None:
            for it in tf:
                k, v = it.find('key'), it.find('value')
                if k is None or v is None or not len(v): continue
                try: kk = k[0]; x, y = int(kk.findtext('X')), int(kk.findtext('Y'))
                except Exception: continue
                t = v[0].get(XSI) or v[0].tag
                if t in PROBE_TYPES: d['probes'][t].add((x, y))
                else: d['other_tf'].add((x, y))
        for tag, key in (('largeTerrainFeatures', 'bushes'),):
            el = gl.find(tag)
            if el is not None:
                for v in el:
                    tp = v.find('tilePosition')
                    if tp is None: continue
                    t = v.get(XSI) or v.tag
                    if t == 'Bush':
                        d[key].add((int(tp.findtext('X')), int(tp.findtext('Y'))))
        objs = gl.find('objects')
        if objs is not None:
            for it in objs:
                v, k = it.find('value'), it.find('key')
                if v is None or k is None or not len(v) or not len(k): continue
                try: kk = k[0]; x, y = int(kk.findtext('X')), int(kk.findtext('Y'))
                except Exception: continue
                nm = (v[0].findtext('name') or '').strip()
                if nm == 'Artifact Spot': d['water'].add((x, y))
                elif nm == 'Seed Spot': d['seed'].add((x, y))
                elif nm in ('Stone', 'Weeds', 'Twig'): d['litter'].add((x, y))
        rc = gl.find('resourceClumps')
        if rc is not None:
            for v in rc:
                tl = v.find('tile')
                if tl is not None:
                    d['clumps'].add((int(tl.findtext('X')), int(tl.findtext('Y'))))
        out[name] = d
    return out

def player_tile(root, src_text):
    m = re.search(r'<Position>\s*<X>\s*(-?[\d.]+)</X>\s*<Y>\s*(-?[\d.]+)</Y>\s*</Position>', src_text)
    if not m: return None
    return (int(float(m.group(1)) // 16), int(float(m.group(2)) // 16))

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('saves', nargs='+')
    ap.add_argument('--baseline', nargs='*', default=[], help='un-played probe XML(s) for exact diff')
    ap.add_argument('--out', default='probe_results')
    ap.add_argument('--rect', default='151x151')
    ap.add_argument('--probed-only', action='store_true')
    a = ap.parse_args()
    RW, RH = map(int, a.rect.lower().split('x'))
    os.makedirs(a.out, exist_ok=True)

    base = {}
    for bp in a.baseline:
        txt = open(bp, encoding='utf-8-sig').read()
        for name, d in grab_locations(ET.fromstring(txt)).items():
            base.setdefault(name, d)
    comparing = bool(base)

    lines = ['# Probe results\n']
    for p in a.saves:
        txt = open(p, encoding='utf-8-sig').read()
        root = ET.fromstring(txt)
        res = grab_locations(root)
        ptile = player_tile(root, txt)
        tag = os.path.basename(p)
        gate_stats = {}
        lines.append(f"\n## {tag}" + (f"  (player at tile {ptile[0]},{ptile[1]})" if ptile else "") + "\n")
        hdr = ("| zone | probe | kept | lost | ->bush | water spots | sand spots | litter | clumps | kept bbox | area |"
               if comparing else
               "| zone | ground tiles | ground bbox | area (W×H) | fill % | water spots | sand spots | litter | clumps |")
        lines.append(hdr)
        lines.append('|---' * hdr.count('|') + '|')
        for name, r in sorted(res.items(), key=lambda kv: -max(len(kv[1]['probes']['HoeDirt']) + len(kv[1]['probes']['Grass']) + len(kv[1]['probes']['Tree']), len(kv[1]['litter']))):
            if comparing:
                b = base.get(name)
                ptype = next((t for t in PROBE_TYPES if b and len(b['probes'][t]) > 0), None)
                if ptype is None or len(b['probes'][ptype]) < 500:
                    continue
                probes = b['probes'][ptype]
                kept = probes & r['probes'][ptype]
                vanished = probes - r['probes'][ptype]
                to_bush = vanished & r['bushes']
                lost = vanished - to_bush
                if a.probed_only and len(kept) == 0:
                    continue
                if kept:
                    x0 = min(x for x, y in kept); x1 = max(x for x, y in kept)
                    y0 = min(y for x, y in kept); y1 = max(y for x, y in kept)
                    bbox = f'X {x0}-{x1}, Y {y0}-{y1}'; area = f'{x1-x0+1}×{y1-y0+1}'
                else:
                    bbox, area = '—', '0×0'
                lines.append(f"| {name} | {ptype} | {len(kept)} | {len(lost)} | {len(to_bush)} | {len(r['water'])} | {len(r['seed'])} | {len(r['litter'])} | {len(r['clumps'])} | {bbox} | {area} |")
                render_zone(name, kept, lost, to_bush, r['water'] | r['seed'] | r['litter'], (RW, RH), a.out)
                with open(os.path.join(a.out, f'probes_{name}.csv'), 'w') as f:
                    f.write('x,y,kind\n')
                    for x, y in sorted(kept, key=lambda t: (t[1], t[0])): f.write(f'{x},{y},kept\n')
                    for x, y in sorted(to_bush): f.write(f'{x},{y},bush\n')
                    for x, y in sorted(lost): f.write(f'{x},{y},lost\n')
                # gate diagnostics vs player (aggregate over all zones of this file)
                if ptile and lost:
                    gate = gate_stats.setdefault(name, [])
                    gate.extend((x - ptile[0], y - ptile[1]) for x, y in lost)
            else:
                g = r['probes']['HoeDirt'] or r['probes']['Grass']
                if a.probed_only and len(g) == 0:
                    continue
                rect = RW * RH
                if g:
                    x0 = min(x for x, y in g); x1 = max(x for x, y in g)
                    y0 = min(y for x, y in g); y1 = max(y for x, y in g)
                    bbox = f"X {x0}–{x1}, Y {y0}–{y1}"; w, h = x1 - x0 + 1, y1 - y0 + 1
                else:
                    bbox, w, h = '—', 0, 0
                probed = len(g) >= 500
                fill = f"{100.0 * len(g) / rect:.1f}%" if probed else '—'
                note = ' **NO PRUNING HAPPENED**' if len(g) == rect else ''
                lines.append(f"| {name} | {len(g)} | {bbox}{note} | {w}×{h} | {fill} | {len(r['water'])} | {len(r['seed'])} | {len(r['litter'])} | {len(r['clumps'])} |")
                if g:
                    render_zone(name, set(g), set(), set(), r['water'] | r['seed'] | r['litter'], (RW, RH), a.out)
                    with open(os.path.join(a.out, f'probes_{name}.csv'), 'w') as f:
                        f.write('x,y\n')
                        for x, y in sorted(g, key=lambda t: (t[1], t[0])): f.write(f'{x},{y}\n')
        if comparing and gate_stats:
            alloffs = [o for offs in gate_stats.values() for o in offs]
            mnx = min(o[0] for o in alloffs); mxx = max(o[0] for o in alloffs)
            mny = min(o[1] for o in alloffs); mxy = max(o[1] for o in alloffs)
            far = sum(1 for dx, dy in alloffs if abs(dx) > 33 or abs(dy) > 33)
            lines.append(f"\n**Gate check vs player {ptile}:** pruned tiles span offsets X {mnx}..{mxx}, Y {mny}..{mxy} "
                         f"({len(alloffs)} pruned in {len(gate_stats)} zone(s); {far} of them farther than 33 tiles). "
                         + ("Consistent with the ~±30-tile player gate of checkForRemoval - run mode C sweeps and repeat-diff."
                            if far == 0 else
                            "Pruning reached far beyond the player - this game version already sweeps wide areas; more sweeps only refine edges."))
            lines.append(f"\nGate detail per zone (offset spans of pruned tiles):")
            for zn, offs in gate_stats.items():
                x0 = min(o[0] for o in offs); x1 = max(o[0] for o in offs)
                y0 = min(o[1] for o in offs); y1 = max(o[1] for o in offs)
                lines.append(f"- {zn}: dx {x0}..{x1}, dy {y0}..{y1}, n={len(offs)}")
        txt_out = '\n'.join(lines)
    open(os.path.join(a.out, 'probe_summary.md'), 'w').write(txt_out + '\n')
    print(txt_out)

if __name__ == '__main__':
    main()
