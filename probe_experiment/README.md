# Ground-probe experiment

Goal: recover the **exact playable-ground coordinate map** of every zone — i.e. which tiles
the game treats as valid ground for natural objects (stone/weed/twig litter, forage like coral
and clams, grass, trees, bushes, resource clumps).

## Why HoeDirt instead of Stone

The game does **not** re-validate plain objects (`Stone`, `Twig`, …) when loading a save —
they persist even on water (that's why probing with them keeps everything).
But it *does* validate tilled dirt: on load, every `HoeDirt` terrainFeature is checked by
`HoeDirt.checkForRemoval()` and removed if the tile is:

- not on a `Diggable` "Back"-layer tile (water, pavement, cliffs, bridges, floors, off the map),
- covered by an object, a clump, or a tree/bush,
- under a building.

`Diggable` is exactly the ground predicate the game uses when spawning litter, forage, grass,
trees, bushes and clumps — so surviving dirt after one load = perfect "nature ground" map.

## The 5 probe saves

Built by `tools/probe_save.py` from `Забытая Farm/Забытая`. Each target location had its
`objects`, `terrainFeatures`, `largeTerrainFeatures`, `resourceClumps`, `farmPatches` and
`buildings` wiped and refilled with a `HoeDirt` probe on every tile of `0,0 .. 150,150`
(22,801 probes/zone). All other 57 locations are untouched.

| folder | zones | size |
|---|---|---|
| probe01 | Farm, FarmHouse, Town, Beach, Mountain | ~14 MB |
| probe02 | Forest, BusStop, Mine, BugLand, Desert | ~16 MB |
| probe03 | Woods, Railroad, Backwoods, Cellar, IslandSouth | ~16 MB |
| probe04 | IslandEast, IslandWest, IslandNorth, IslandNorthCave1, CaptainRoom | ~16 MB |
| probe05 | IslandShrine, Caldera, DesertFestival | ~11 MB |

## Procedure (per save)

1. Copy the `probeNN` folder into `%APPDATA%\StardewValley\Saves` (Proton/Linux: the game's
   `…/drive_c/users/…/AppData/Roaming/StardewValley/Saves`).
2. In-game: load `probeNN`, wait ~10 s (location load + dirt pruning happen while loading);
   walk around briefly. To be thorough, warp through each probed zone once.
3. **Do NOT sleep** — unwatered dry dirt reverts on day change and you'd lose the evidence.
4. Esc → Save and quit.
5. Export the resulting save to XML (same way the other files in this repo were made; if you
   can only produce the raw 1.6 binary save, upload that instead — it can be parsed too).

Optionally run the reader yourself:

```
python3 tools/probe_read.py results/probe01.xml results/probe02.xml ... --out probe_results
```

It writes per-zone `probes_<zone>.png` (green = ground survived · dark = pruned · blue =
artifact spot on water · orange = fresh litter), `probes_<zone>.csv` (all surviving
coordinates) and `probe_summary.md` with bbox/area/fill% per zone. If a zone shows
`NO PRUNING HAPPENED`, its save was not actually loaded by the game.

Expected sanity anchors: Farm ≈ a 70×45ish block with the pond hole + house footprint punched
out; Town = 128-wide rect with pavement holes; Beach = sand strip; interiors (FarmHouse,
Cellar, CaptainRoom, caves…) ≈ 0 surviving tiles.

Then hand over the pruned files and the consolidated area-size map gets assembled from them.

## Regenerating

```
python3 tools/probe_save.py --save "Забытая Farm/Забытая" --max-x 150 --max-y 150 --batch 5
```
