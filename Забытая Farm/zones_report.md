# Zone sizes & natural clutter — save `Забытая Farm / Забытая`

Parsed from the XML `SaveGame` file `Забытая` (game version 1.6.14, farmer *Рэй*,
Spring 1, Year 1 — a fresh standard-farm start, `whichFarm=0`). No `_old` slot in this folder.

Same method as [`../a_448211473/zones_report.md`](../a_448211473/zones_report.md): stones/weeds/twigs = litter
`objects` (`category -999`, `type Litter`); grass & trees = `terrainFeatures` (`Grass`/`Tree`); bushes =
`largeTerrainFeatures` `Bush`; chunks = `resourceClumps` (all 2×2 tiles; sheet 600 = stone, 602 = twig, 672 = weed/garbage).
A save does not store a map's full dimensions, so **extent = bounding box of everything the save stores** for that zone
(objects, terrain features, clump footprints, buildings). 1 tile = 16 px.

**24 of 80 locations contain any saved data; 18 of those contain the clutter types you asked about.**
(These are the maps your `Папка Stardew/01…23` export covers — the two `IslL` folders hold the small island maps.)

## Zones with stones / weeds / grass / twigs / trees / bushes / chunks

| # | Zone | stones | weeds | twigs | grass | trees | bushes | clumps (2×2) | **Extent (tiles)** | Bounding box X / Y | Area |
|--:|---|--:|--:|--:|--:|--:|--:|--:|---|---|--:|
| 1 | **Farm** | 320 | 533 | 156 | 406 | 130 | 5 | 39 | **75 × 56** | X 3–77, Y 6–61 | 4 200 |
| 2 | **Forest** | 3 | 113 | 40 | 13 | 55 | 227 | 1 | **119 × 95** | X 1–119, Y 5–99 | 11 305 |
| 3 | **Island West** | 62 | 110 | 51 | 0 | 27 | 73 | 17 | **90 × 83** | X 15–104, Y 3–85 | 7 470 |
| 4 | **Town** | 1 | 91 | 1 | 0 | 17 | 156 | 4 | **127 × 94** | X 0–126, Y 8–101 | 11 938 |
| 5 | **Bug Land** | 36 | 140 | 0 | 0 | 0 | 0 | 0 | **43 × 47** | X 11–53, Y 6–52 | 2 021 |
| 6 | **Mountain** | 49 | 0 | 0 | 0 | 13 | 47 | 0 | **125 × 33** | X 3–127, Y 5–37 | 4 125 |
| 7 | **Railroad** | 29 | 45 | 3 | 0 | 6 | 14 | 0 | **65 × 36** | X 2–66, Y 22–57 | 2 340 |
| 8 | **Woods** (Secret Woods) | 0 | 0 | 0 | 0 | 0 | 70 | 6 | **53 × 27** | X 3–55, Y 4–30 | 1 431 |
| 9 | **Island North** | 10 | 1 | 0 | 0 | 10 | 30 | 0 | **62 × 67** | X 0–61, Y 18–84 | 4 154 |
| 10 | **Backwoods** | 0 | 0 | 0 | 0 | 3 | 35 | 0 | **39 × 26** | X 11–49, Y 8–33 | 1 014 |
| 11 | **Bus Stop** | 0 | 0 | 0 | 0 | 4 | 20 | 0 | **61 × 20** | X 1–61, Y 1–20 | 1 220 |
| 12 | **Island East** | 0 | 1 | 0 | 0 | 0 | 14 | 0 | **18 × 16** | X 11–28, Y 28–43 | 288 |
| 13 | **Desert** | 0 | 0 | 0 | 0 | 11 | 0 | 0 | **40 × 45** | X 1–40, Y 8–52 | 1 800 |
| 14 | **Desert Festival** | 0 | 0 | 0 | 0 | 4 | 0 | 0 | **20 × 39** | X 18–37, Y 22–60 | 780 |
| 15 | **Caldera** | 0 | 0 | 0 | 0 | 0 | 2 | 0 | **20 × 3** | X 9–28, Y 34–36 | 60 |
| 16 | **Island South** | 0 | 0 | 0 | 0 | 0 | 1 | 0 | **1 × 1** | X 31–31, Y 5–5 | 1 |
| 17 | **Island Shrine** | 0 | 0 | 0 | 0 | 0 | 1 | 0 | **7 × 10** | X 21–27, Y 25–34 | 70 |
| 18 | **Captain Room** | 0 | 0 | 0 | 0 | 0 | 1 | 0 | **1 × 1** | X 2–2, Y 4–4 | 1 |

### Chunk (resource clump) breakdown — every clump footprint is 2×2 tiles

| Zone | stone (600) | twig (602) | weed/garbage (672) | total | tiles covered |
|---|--:|--:|--:|--:|--:|
| Farm | 19 | 6 | 14 | 39 | 156 |
| Island West | 9 | 3 | 5 | 17 | 68 |
| Woods | 6 | 0 | 0 | 6 | 24 |
| Town | 2 | 1 | 1 | 4 | 16 |
| Forest | 0 | 1 | 0 | 1 | 4 |

### Other locations that have saved data but no clutter

| Zone | stored entries | what |
|---|--:|---|
| FarmHouse | 10 | furniture |
| Cellar | 33 | 33 Casks |
| Beach | 2 | misc object(s) |
| IslandNorthCave1 | 5 | chests/forage (Chanterelle, Common Mushroom…) |
| IslandFarmHouse | 11 | furniture |
| Mine | 1 | ladder/object |

Cross-check vs raw grep on the file: 1 034 `Weeds` + 510 `Stone` + 251 `Twig` name tags = exactly the totals
counted per-zone above ✓.

### Comparison with the `a_448211473` save

Both saves are Spring-1, Year-1 standard-farm starts, so the structure is nearly identical: the same 18 cluttered
zones and the same extents (Farm 75×56, Forest 119×95, Town 127×94 …), and even the same clump counts/footprints
per zone. Per-object counts differ slightly because debris spawns from each save's own random seed
(Farm weeds 533 vs 505, stones 320 vs 314, grass 406 vs 437). Desert/IslandSouth extents differ a bit because the
`a_448211473` save happens to store a few more entities there.

Machine-readable version: [`zones_report.csv`](zones_report.csv) (same numbers + pixel bounds).
