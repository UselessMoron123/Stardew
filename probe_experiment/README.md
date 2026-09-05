# Ground probe experiment (v2 — with sweep)

Goal: turn each zone's *exact playable-ground coordinates* into the
`terrainFeatures` XML you use in your custom maps.

## How it works

1. Every tile in `0,0 .. 150,150` of a location gets a **probe** entry.
2. On load the game validates probes against the real map collision grid:
   * `HoeDirt` probes on invalid tiles are **deleted** → holes = non-ground;
   * `Grass` probes on invalid tiles are **converted to bushes** → nothing
     is lost: surviving grass = ground, new bushes = not ground.
3. After a save+quit, the returned file *is* the occupied-coordinate map.

### The catch found in v1 (why one load was not enough)

Load-time validation is **gated by player distance** (≈±30 tiles around the
farmer, tile coordinates — same box applied in *every* location at once).
That is exactly the observed result: "small uneven patches" of pruned dirt
around the spawn, the rest untouched.

So we **sweep**: move the spawn, load again. The 6-pass grid
`(24,24) (80,24) (136,24) (24,82) (80,82) (136,82)` covers the full
0..150 × 0..150 area. Walking around inside the current pass also extends
coverage — the more you walk, the less the next sweep pass has to fix.

## Protocol (all with `tools/probe_fill.bat`, no Python needed)

0. Convert your save to XML (your converter).
1. **Run `probe_fill.bat`, mode B** on the XML file, zone = e.g. `Farm`,
   probe type = **grass**, clear litter = Y, drop buildings = N.
2. **Mode C** on the same file, pass 1 (empty X/Y = auto-sweep; it also
   snapshots `FILE.baseline` — keep it, it is what we diff against).
3. Put the file back where saves live → load → wait ~10 s → **walk around**
   (that expands the validated box) → *Save and quit* (never sleep; sleeping
   starts a new day and re-copies litter).
4. Convert the played save, overwrite the working XML, run **mode C** again
   → pass 2 … repeat until it says all 6 passes done.
5. Analysis (either by me — hand back the final XML — or yourself with
   `python tools/probe_read.py FINAL.xml --baseline FILE.baseline`):
   the table shows kept / lost / →bush per zone and the **gate check** that
   proves the ±30-tile behavior on your game version.

If the gate check says "pruning reached far beyond the player", one pass
was enough and the rest are just refinements.

## Notes

* `probe01..05` folders are v1 batches (dirt probes, no sweep). Their
  played results taught us the gate behavior; you can re-do them with the
  new protocol for complete maps.
* Spawn locations outside a map's walkable area are clamped by the game —
  harmless (boxes overlap), analysis only counts what actually changed.
* Interiors: `FarmHouse`/cellars/barns will show "all probes lost" — that
  is real: their 0..150 ground under the buildings is already defined by
  building warps; skip interior sweeps. Mine-shaft floors are not dirt-able
  by design — the mod must keep its own collision for the mine network.
