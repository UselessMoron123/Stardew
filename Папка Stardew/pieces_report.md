# Map pieces (`Папка Stardew`) — zone sizes & clutter per piece

Each of the 23 folders is **one zone (map)**, and each file inside it is a **complete `GameLocation` XML
snapshot** of that zone — *not* a spatial slice. All pieces were reconstructed (wrapped in `</player></SaveGame>`)
and parsed with the same rules as the save reports: stones/weeds/twigs = litter objects (`category -999`),
grass/trees = `terrainFeatures`, bushes = `largeTerrainFeatures/Bush`, chunks = `resourceClumps` (footprint in tiles).
1 tile = 16 px. "Extent" = bounding box of everything stored in that snapshot.

**What the 21 pieces are:** 21 slightly different states of the same map (21 export runs of farmer *Рэй*'s saves).
Piece **#07 equals the `Забытая Farm/Забытая` save exactly** (Farm07: 320 stones / 533 weeds / 156 twigs /
406 grass / 130 trees / 5 bushes / 39 clumps, extent 75×56 — identical to the save report; Town07 = 270 entries ✓).

## Per-zone summary (min–max across the 21 pieces)

| Folder | Zone (location) | Extent (tiles) | stable? | stones | weeds | twigs | grass | trees | bushes | chunks | chunk tiles |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 01Farm | Farm | **75×56** (X 3–77, Y 6–61) | ✓ all 21 | 308–326 | 533–565 | 151–166 | 402–453 | 124–147 | 5 | 39 | 156 |
| 02FarmHo | FarmHouse | 1×1 (sparse furniture only) | – | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 03Town | Town | **127×94** (X 0–126, Y 8–101) | ✓ all 21 | 0–5 | 80–97 | 1–4 | 0 | 17 | 156 | 4 | 16 |
| 04Beach | Beach | 1×1 … 78×8 (varies wildly) | ✗ | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 05Mount | Mountain | **124–125×33** (Y 5–37) | ≈ | 49–69 | 0 | 0 | 0 | 9–15 | 47 | 0 | 0 |
| 06Forest | Forest | **119×95** (X 1–119, Y 5–99) | ✓ all 21 | 1–10 | 101–146 | 40–49 | 13 | 55 | 227 | 1 | 4 |
| 07BusSt | BusStop | **61×20–23** | ≈ | 0 | 0 | 0 | 0 | 4 | 20 | 0 | 0 |
| 08Mine | Mine | 1×1 (1 saved entry) | – | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 09Bug | BugLand | **43×47** (X 11–53, Y 6–52) | ✓ all 21 | 36 | 140 | 0 | 0 | 0 | 0 | 0 | 0 |
| 10Desert | Desert | 33×42 … 43×47 (varies) | ✗ | 0 | 0 | 0 | 0 | 11 | 0 | 0 | 0 |
| 11Wood | Woods (Secret Woods) | **53×27** (X 3–55, Y 4–30) | ✓ all 21 | 0 | 0 | 0 | 0 | 0 | 70 | 6 | 24 |
| 12Rail | Railroad | **65×36–38** (X 2–66, Y 22–57) | ≈ | 23–29 | 33–58 | 1–6 | 0 | 6 | 14 | 0 | 0 |
| 13BackW | Backwoods | **39×26** (X 11–49, Y 8–33) | ✓ all 21 | 0 | 0 | 0 | 0 | 3 | 35 | 0 | 0 |
| 14Cellar | Cellar | 11×5 (33 casks, no clutter) | – | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 15IslS | IslandSouth | 1×1 … 28×25 (varies) | ✗ | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| 16IslE | IslandEast | **18–23×16–21** | ≈ | 0 | 0–7 | 0 | 0 | 0 | 14 | 0 | 0 |
| 17IslW | IslandWest | **90×80–84** (X 15–104) | ≈ | 62–66 | 110 | 51 | 0 | 27 | 73 | 17 | 68 |
| 18IslN | IslandNorth | **62×67** (X 0–61, Y 18–84) | ✓ all 21 | 5–31 | 0–4 | 0 | 0 | 10–11 | 30 | 0 | 0 |
| 19IslL | IslandNorthCave1 | 2×2 … 6×5 (varies) | ✗ | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 20IslL | CaptainRoom | 1×1 | ✓ | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| 21IslSh | IslandShrine | **7×10** | ✓ | 0 | 0 | 0 | 0 | 0 | 1 | 0 | 0 |
| 22Caldera | Caldera | **20×3** (Y 34–36) | – (1 file) | 0 | 0 | 0 | 0 | 0 | 2 | 0 | 0 |
| 23DesertF | DesertFestival | 20×39 … 39×53 (varies) | ✗ | 0 | 0 | 0 | 0 | 4 | 0 | 0 | 0 |

Chunk footprint in every snapshot = 2×2 tiles per clump; counts per type are stable across pieces
(Farm: 19 stone + 14 weed + 6 twig = 39 everywhere; IslandWest: 9+5+3 = 17; Woods: 6 stone; Town: 2+1+1 = 4; Forest: 1 twig).

## Reading the "varies" rows

For **content-rich zones** (Farm, Town, Forest, Mountain, IslandWest, BugLand, Woods, Railroad, …) the extent is
essentially the same in all 21 pieces → those are the zone sizes to reproduce. For **sparse zones** (Beach, Desert,
IslandSouth, IslandNorthCave1, DesertFestival, BusStop, FarmHouse, Mine) the bounding box only covers whatever few
objects happened to be stored that day, so it bounces around; it is *not* the real map size.

## Differences between pieces (what changes between the 21 snapshots)

- Only **litter counts** move: weeds/twigs/stones spawn & re-grow between days (Farm weeds 533–565, stones 308–326,
  Town weeds 80–97, Forest weeds 101–146). Mountain stones swing 49–69, IslandNorth stones 5–31.
- **Static scenery never changes**: trees (Forest 55, Town 17, IslandWest 27), bushes (Forest 227, Town 156,
  Woods 70, IslandWest 73), grass base counts, and all chunk (clump) placements are identical in every piece.
- `IslL17` (IslandNorthCave1) is an empty snapshot — nothing stored in that one.

### Comparison with the `a_448211473` save

That save is *not* part of this 21-piece set (its Farm had 505 weeds / 314 stones / 437 grass, outside the pieces'
533–565 / 308–326 / 402–453 ranges), but the zone extents match for every zone that appears in both
(Farm 75×56, Town 127×94, Forest 119×95, IslandWest 90×83, BugLand 43×47, Woods 53×27, Backwoods 39×26, Caldera 20×3, …).

Machine-readable, one row per piece: [`pieces_report.csv`](pieces_report.csv).
