#!/usr/bin/env python3
"""Build "ground probe" experiment saves for Stardew Valley (XML save format).

Idea:
  Every candidate tile gets a HoeDirt (tilled soil) terrainFeature. On save load the
  game runs HoeDirt.checkForRemoval() for every location and REMOVES dirt that is:
    - outside the map bounds              (reveals true map size)
    - not on a Diggable tile              (water, bridges, cliffs, pavement, floors...)
    - under a building / on its doorstep
    - covered by an object / clump / tree / bush
  Diggable ground is exactly the predicate the game uses to place natural clutter
  (stone/weed/twig litter, forage like coral & clams, grass, trees, bushes, resource
  clumps), so surviving dirt = "tiles that can hold nature stuff".

  Plain litter objects (Stone etc.) are NOT re-validated on load, so probing with them
  would keep everything — this tool probes with HoeDirt instead.

Output: probe_experiment/probeNN/probeNN  (+SaveGameInfo) — copy each folder into
%Saves% and play. Do NOT sleep overnight (dry dirt reverts on day change):
load -> a few seconds -> save & quit.

Usage:
  python3 tools/probe_save.py [--save SAVE.xml] [--out DIR] [--zones A,B | --folders DIR]
                              [--max-x 150] [--max-y 150] [--batch 5] [--keep-buildings]
"""
import argparse, os, re

def dirt_xml(x, y):
    return (f'<item><key><Vector2><X>{x}</X><Y>{y}</Y></Vector2></key>'
            f'<value><TerrainFeature xsi:type="HoeDirt" /></value></item>')

def dirt_for_range(max_x, max_y):
    rows = []
    for y in range(max_y + 1):
        rows.append(''.join(dirt_xml(x, y) for x in range(max_x + 1)))
    return ''.join(rows)

# Папка Stardew folder -> GameLocation name in the save
FOLDER_ZONE = {
    '01Farm': 'Farm', '02FarmHo': 'FarmHouse', '03Town': 'Town', '04Beach': 'Beach',
    '05Mount': 'Mountain', '06Forest': 'Forest', '07BusSt': 'BusStop', '08Mine': 'Mine',
    '09Bug': 'BugLand', '10Desert': 'Desert', '11Wood': 'Woods', '12Rail': 'Railroad',
    '13BackW': 'Backwoods', '14Cellar': 'Cellar', '15IslS': 'IslandSouth', '16IslE': 'IslandEast',
    '17IslW': 'IslandWest', '18IslN': 'IslandNorth', '19IslL': 'IslandNorthCave1',
    '20IslL': 'CaptainRoom', '21IslSh': 'IslandShrine', '22Caldera': 'Caldera', '23DesertF': 'DesertFestival',
}

CLEAR_TAGS = ('objects', 'largeTerrainFeatures', 'resourceClumps', 'farmPatches')

def build_patched(src, zone_names, max_x, max_y, keep_buildings):
    """String surgery: for each target <GameLocation>...</GameLocation> drop nature
    collections and inject the probe grid as <terrainFeatures>. Game-style formatting.
    Locations are identified by document order (the <GameLocation> blocks appear in the
    same order as SaveGame/locations children; per-block <name> tags are unreliable)."""
    import xml.etree.ElementTree as ET
    names = [gl.findtext('name') for gl in ET.fromstring(src).find('locations')]
    probes = dirt_for_range(max_x, max_y)
    out, pos, li = [], 0, 0
    for m in re.finditer(r'<GameLocation(?: xsi:type="[^"]*")?\s*>', src):
        end = src.find('</GameLocation>', m.end())
        if end == -1:
            continue
        name = names[li] if li < len(names) else ''
        li += 1
        if name not in zone_names:
            continue
        nb = src[m.end():end]
        for tag in CLEAR_TAGS:
            nb = re.sub(rf'<{tag}\s*/>|<{tag}>.*?</{tag}>', f'<{tag} />', nb, flags=re.S)
        if re.search(r'<terrainFeatures\s*/>', nb):
            nb = re.sub(r'<terrainFeatures\s*/>', f'<terrainFeatures>{probes}</terrainFeatures>', nb)
        elif '<terrainFeatures>' in nb:
            nb = re.sub(r'<terrainFeatures>.*?</terrainFeatures>',
                        f'<terrainFeatures>{probes}</terrainFeatures>', nb, count=1, flags=re.S)
        else:
            # no terrainFeatures element: insert before <waterColor> (direct child, right after <name>)
            nb = nb.replace('<waterColor>', f'<terrainFeatures>{probes}</terrainFeatures><waterColor>', 1)
        if not keep_buildings:
            nb = re.sub(r'<buildings>.*?</buildings>', '<buildings />', nb, flags=re.S)
        out.append(src[pos:m.end()])
        out.append(nb)
        pos = end
    out.append(src[pos:])
    return (''.join(out)).encode('utf-8-sig')

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--save', default='Забытая Farm/Забытая')
    ap.add_argument('--out', default='probe_experiment')
    ap.add_argument('--folders', default='Папка Stardew')
    ap.add_argument('--zones', default=None, help='comma list of GameLocation names (overrides --folders)')
    ap.add_argument('--max-x', type=int, default=150)
    ap.add_argument('--max-y', type=int, default=150)
    ap.add_argument('--batch', type=int, default=5)
    ap.add_argument('--keep-buildings', action='store_true')
    a = ap.parse_args()

    if a.zones:
        zones = a.zones.split(',')
    else:
        present = [d for d in sorted(os.listdir(a.folders)) if os.path.isdir(os.path.join(a.folders, d))]
        zones = [FOLDER_ZONE[f] for f in present if f in FOLDER_ZONE]
    print(f'target zones ({len(zones)}): {", ".join(zones)}')

    src = open(a.save, encoding='utf-8-sig').read()
    os.makedirs(a.out, exist_ok=True)
    batches = [zones[i:i + a.batch] for i in range(0, len(zones), a.batch)]
    manifest = []
    for bi, bz in enumerate(batches, 1):
        fname = f'probe{bi:02d}'
        outdir = os.path.join(a.out, fname)
        os.makedirs(outdir, exist_ok=True)
        patched = build_patched(src, bz, a.max_x, a.max_y, a.keep_buildings)
        with open(os.path.join(outdir, fname), 'wb') as f:
            f.write(patched)
        gi = os.path.join(os.path.dirname(a.save), 'SaveGameInfo')
        if os.path.exists(gi):
            gi_text = open(gi, encoding='utf-8-sig').read()
            with open(os.path.join(outdir, 'SaveGameInfo'), 'wb') as f:
                f.write(('\ufeff' + gi_text).encode('utf-8'))
        sz = os.path.getsize(os.path.join(outdir, fname)) / 1e6
        manifest.append((fname, bz, sz))
        print(f'  wrote {outdir}/{fname}  ({sz:.1f} MB)  zones: {", ".join(bz)}')

    with open(os.path.join(a.out, 'manifest.txt'), 'w') as f:
        for fname, bz, sz in manifest:
            f.write(f'{fname}\t{sz:.1f} MB\t{", ".join(bz)}\n')
    print(f'\nProbes per zone: {(a.max_x + 1) * (a.max_y + 1)} (rect 0..{a.max_x} x 0..{a.max_y})')
    print('Copy probe01.. folders into  %APPDATA%\\StardewValley\\Saves , load, wait a few')
    print('seconds, save & quit (do NOT sleep), convert the save back to XML, hand me the files.')

if __name__ == '__main__':
    main()
