# Zone sizes & natural clutter — save `a_448211473`

Parsed from the XML `SaveGame` file `a_448211473` (game version 1.6.15, farmer *a*).
The `_old` slot was checked too — same 18 cluttered zones, only minor count drift (see bottom).

**What counts as what (as stored in the save):**

| Category | Where it lives in the save |
|---|---|
| stones / weeds / twigs | `objects` dict entries named `Stone` / `Weeds` / `Twig` (debris, `category -999`, `type Litter`) |
| grass | `terrainFeatures` entries of type `Grass` |
| trees | `terrainFeatures`/`largeTerrainFeatures` of type `Tree`/`FruitTree` (incl. palms, moss trees) |
| bushes | `largeTerrainFeatures` of type `Bush` (incl. town bushes) |
| chunks (clumps) | `resourceClumps` — all are **2×2 tiles**; type by `parentSheetIndex`: 600 = stone, 602 = twig, 672 = weed/garbage |

**Note on "size":** a Stardew save does **not** store a location's full map dimensions (those come from the game's `.tmx` files). The "extent" below is the bounding box of *everything the save actually stores* for that zone (objects, terrain features, clumps incl. their footprint, buildings) — i.e. the area you must recreate to cover all saved data. 1 tile = 16 px.

## Zones containing stones / weeds / grass / twigs / trees / bushes / chunks

18 of 80 locations in this save contain them (sorted by total count):

| # | Zone | stones | weeds | twigs | grass | trees | bushes | clumps (2×2) | **Extent (tiles)** | Bounding box X / Y | Area |
|--:|---|--:|--:|--:|--:|--:|--:|--:|---|---|--:|
| 1 | **Farm** | 314 | 505 | 162 | 437 | 133 | 5 | 39 | **75 × 56** | X 3–77, Y 6–61 | 4 200 |
| 2 | **Forest** | 8 | 124 | 45 | 13 | 55 | 227 | 1 | **119 × 95** | X 1–119, Y 5–99 | 11 305 |
| 3 | **Island West** | 64 | 110 | 51 | 0 | 27 | 73 | 17 | **90 × 83** | X 15–104, Y 3–85 | 7 470 |
| 4 | **Town** | 0 | 79 | 3 | 0 | 17 | 156 | 4 | **127 × 94** | X 0–126, Y 8–101 | 11 938 |
| 5 | **Bug Land** | 36 | 140 | 0 | 0 | 0 | 0 | 0 | **43 × 47** | X 11–53, Y 6–52 | 2 021 |
| 6 | **Mountain** | 61 | 0 | 0 | 0 | 11 | 47 | 0 | **125 × 33** | X 3–127, Y 5–37 | 4 125 |
| 7 | **Railroad** | 26 | 42 | 5 | 0 | 6 | 14 | 0 | **65 × 36** | X 2–66, Y 22–57 | 2 340 |
| 8 | **Woods** (Secret Woods) | 0 | 0 | 0 | 0 | 0 | 70 | 6 | **53 × 27** | X 3–55, Y 4–30 | 1 431 |
| 9 | **Island North** | 22 | 3 | 0 | 0 | 12 | 30 | 0 | **62 × 67** | X 0–61, Y 18–84 | 4 154 |
| 10 | **Backwoods** | 0 | 0 | 0 | 0 | 3 | 35 | 0 | **39 × 26** | X 11–49, Y 8–33 | 1 014 |
| 11 | **Bus Stop** | 0 | 0 | 0 | 0 | 4 | 20 | 0 | **61 × 20** | X 1–61, Y 1–20 | 1 220 |
| 12 | **Island East** | 0 | 1 | 0 | 0 | 0 | 14 | 0 | **18 × 16** | X 11–28, Y 28–43 | 288 |
| 13 | **Desert** | 0 | 0 | 0 | 0 | 11 | 0 | 0 | **39 × 42** | X 6–44, Y 8–49 | 1 638 |
| 14 | **Desert Festival** | 0 | 0 | 0 | 0 | 4 | 0 | 0 | **20 × 39** | X 18–37, Y 22–60 | 780 |
| 15 | **Caldera** | 0 | 0 | 0 | 0 | 0 | 2 | 0 | **20 × 3** | X 9–28, Y 34–36 | 60 |
| 16 | **Island South** | 0 | 0 | 0 | 0 | 0 | 1 | 0 | **13 × 16** | X 19–31, Y 5–20 | 208 |
| 17 | **Island Shrine** | 0 | 0 | 0 | 0 | 0 | 1 | 0 | **7 × 10** | X 21–27, Y 25–34 | 70 |
| 18 | **Captain Room** | 0 | 0 | 0 | 0 | 0 | 1 | 0 | **1 × 1** | X 2–2, Y 4–4 | 1 |

All other 62 locations (all indoor maps, Mine, Sewer, Witch Swamp, Summit, Greenhouse, Skull Cave, etc.)
contain **no** stones/weeds/twigs/grass/trees/bushes/clumps in this save.

### Chunk (resource clump) breakdown, footprint = 2×2 tiles each

| Zone | stone (600) | twig (602) | weed/garbage (672) | total clumps | tiles covered |
|---|--:|--:|--:|--:|--:|
| Farm | 19 | 6 | 14 | 39 | 156 |
| Island West | 9 | 3 | 5 | 17 | 68 |
| Woods | 6 | 0 | 0 | 6 | 24 |
| Town | 2 | 1 | 1 | 4 | 16 |
| Forest | 0 | 1 | 0 | 1 | 4 |

### Details worth knowing

- **Farm**: clutter spans X 3–77, Y 6–61 (75×56 tiles = 1200×896 px). The real farm map is somewhat bigger —
  the edges simply have no saved entities. Biggest clump/grass/weed area by far
  (505 weeds + 437 grass + 314 stones + 162 twigs + 39 clumps).
- **Town**: mostly bushes (156) + weeds (79); extent X 0–126, Y 8–101 (nearly the full map width).
- **Forest**: the most bushes (227) and biggest total extent besides Town.
- **Mountain**: wide strip X 3–127 but only 33 rows of saved content (Y 5–37) — clutter stops below the mine entrance rows.
- **Bug Land**: only litter (36 stones + 140 weeds), no plants — extent 43×47.
- `objects` also hold non-natural things (33 Casks, forage, Artifact/Seed Spots, pedestal…); they widen the
  "extent" but are **not** included in the count columns.

### `a_448211473` vs `a_448211473_old`

Same 18 zones, same extents (±1 tile: Island South 12→13 wide). Counts barely move — e.g. Farm weeds 534→505,
grass 414→437, Mountain stones 56→61, Island North stones 8→22 (new litter spawned/moved during the day).

Machine-readable version: [`zones_report.csv`](zones_report.csv) (same numbers + pixel bounds).
