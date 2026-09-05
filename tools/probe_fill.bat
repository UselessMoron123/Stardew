@echo off
chcp 65001 >nul
setlocal EnableExtensions
title Stardew ground-probe filler
rem ==================================================================
rem  Stardew ground-probe filler
rem  ----------------------------------------------------------------
rem  Fills terrainFeatures with probes on every tile 0,0 .. maxX,maxY.
rem  On load the game validates them and marks/erases invalid tiles,
rem  so after one save the surviving probes = "nature ground" map.
rem
rem  IMPORTANT FINDING: the dirt validator (HoeDirt.checkForRemoval)
rem  only inspects tiles within ~30 tiles of the PLAYER - that is why
rem  one load only trims a patch around the spawn. Mode C sweeps the
rem  spawn in 61x61 boxes to cover the whole 151x151 grid in a few
rem  loads. Pruning happens for ALL locations at once (the gate uses
rem  tile coordinates, not the map name), so one pass sweeps a band
rem  across every map simultaneously.
rem
rem  Probe types:
rem   dirt : HoeDirt - invalid dirt is REMOVED (holes = non-ground)
rem   grass: Grass    - invalid grass is CONVERTED to a bush (nothing
rem          is lost: survivors=ground, new bushes=not ground) [BEST]
rem   tree : Tree     - invalid trees also get removed
rem
rem  Modes:
rem   [A] generate the whole terrainFeatures section into a txt file
rem       (+ clipboard) so you can paste it into a zone XML yourself
rem   [B] patch a save / zone-fragment XML file or folder in place
rem       (backup .probe_bak; clears litter/bushes/clumps/farmPatches
rem        so they cannot fake holes; optionally drops buildings)
rem   [C] sweep: moves the player spawn point in the save between
rem       loads, so repeated loads cover the entire grid
rem  Drag&drop a file/folder onto the .bat -> mode B directly.
rem  Needs Windows 10/11 only (PowerShell built in).
rem ==================================================================

set "PFBAT=%~f0"

if not "%~1"=="" (
  set "PF_MODE=B"
  set "PF_SRC=%~1"
  set "PF_ZONE="
  set "PF_CLEAR=Y"
  set "PF_DROPBLD=N"
  echo Dropped: %~1  - mode B, all locations, clear nature, keep buildings.
  goto :PROBE_TYPE
)

echo   [A] generate probe section .txt  (paste yourself + clipboard)
echo   [B] patch save / fragment XML file or folder in place
echo   [C] sweep: move player spawn between loads ^(cover the full map^)
set "PF_MODE="
set /p "PF_MODE=mode (A / B / C) [A]: "
if /I "%PF_MODE%"=="B" goto :B_MAIN
if /I "%PF_MODE%"=="C" goto :C_MAIN

:A_MAIN
set "PF_SRC=%CD%\terrainFeatures_probe.txt"
set /p "PF_SRC=output txt [%CD%\terrainFeatures_probe.txt]: "
set "PF_ZONE="
set "PF_CLEAR=Y"
set "PF_DROPBLD=N"
goto :PROBE_TYPE

:B_MAIN
set "PF_SRC="
set /p "PF_SRC=XML file or folder to patch: "
if "x%PF_SRC%"=="x" goto :B_MAIN
set "PF_ZONE="
set /p "PF_ZONE=GameLocation type, e.g. Farm Town Beach IslandWest (empty = every location in file): "
set "PF_ZONE=%PF_ZONE: =%"
set "PF_CLEAR=Y"
set /p "PF_CLEAR=clear old litter objects / bushes / clumps / farmPatches? (Y/n): "
set "PF_DROPBLD=N"
set /p "PF_DROPBLD=ALSO remove buildings (holes under them are known anyway) (y/N): "
goto :PROBE_TYPE

:PROBE_TYPE
set "PF_TYPE=dirt"
set /p "PF_TYPE=probe: dirt / grass / tree [dirt]: "
goto :GRID

:C_MAIN
set "PF_MODE=C"
set "PF_SRC="
set /p "PF_SRC=working file (the probe save you will keep overwriting): "
if "x%PF_SRC%"=="x" goto :C_MAIN
set "PF_ZONE="
set "PF_CLEAR=Y"
set "PF_DROPBLD=Y"
goto :PROBE_TYPE_C

:PROBE_TYPE_C
set "PF_TYPE=dirt"
set /p "PF_TYPE=probe type used in that save: dirt / grass / tree [dirt]: "
goto :C_PROMPT

:C_PROMPT
set "PFC_LOC="
set /p "PFC_LOC=spawn via homeLocation override, e.g. Town or FarmHouse (empty = keep current): "
set "PFC_X="
set /p "PFC_X=player tile X (empty = auto-sweep next of 6 grid passes): "
set "PFC_Y="
set /p "PFC_Y=player tile Y (empty = same as X rule): "
findstr /b /c:"::PS::" "%PFBAT%" | powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[Console]::In.ReadToEnd(); $s=$s -replace '::PS::',''; Invoke-Expression $s"
echo.
pause
exit /b

:GRID
set "PF_MAXX=150"
set /p "PF_MAXX=max X coordinate [150]: "
set "PF_MAXY=150"
set /p "PF_MAXY=max Y coordinate [150]: "
findstr /b /c:"::PS::" "%PFBAT%" | powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[Console]::In.ReadToEnd(); $s=$s -replace '::PS::',''; Invoke-Expression $s"
echo.
pause
exit /b

rem ================= embedded PowerShell (do not edit prefix) =================
::PS::$ErrorActionPreference='Stop'
::PS::$mode=$env:PF_MODE
::PS::$src=$env:PF_SRC
::PS::$zone=$env:PF_ZONE
::PS::$maxx=150; if($env:PF_MAXX -match '^[0-9]+$'){$maxx=[int]$env:PF_MAXX}
::PS::$maxy=150; if($env:PF_MAXY -match '^[0-9]+$'){$maxy=[int]$env:PF_MAXY}
::PS::$clear=$env:PF_CLEAR
::PS::$dropb=$env:PF_DROPBLD
::PS::$ptype=$env:PF_TYPE
::PS::if($ptype -match '^[gG]'){ $inner='<TerrainFeature xsi:type="Grass" />'; $ptxt='grass' }
::PS::elseif($ptype -match '^[tT]'){ $inner='<TerrainFeature xsi:type="Tree"><growthStage>4</growthStage><treeType>1</treeType><health>10</health></TerrainFeature>'; $ptxt='tree' }
::PS::else{ $inner='<TerrainFeature xsi:type="HoeDirt" />'; $ptxt='dirt' }
::PS::if($mode -eq 'C'){
::PS::  if(-not (Test-Path -LiteralPath $src)){ Write-Host 'file not found'; exit 1 }
::PS::  $t=[IO.File]::ReadAllText($src)
::PS::  $pi=$t.IndexOf('<player>')
::PS::  if($pi -lt 0){ Write-Host 'no player block found'; exit 1 }
::PS::  $m=[regex]::Match($t.Substring($pi),'(?s)<Position>.*?</Position>')
::PS::  if(-not $m.Success){ Write-Host 'no player Position element'; exit 1 }
::PS::  $state=$src + '.sweep'
::PS::  $i=0; if(Test-Path -LiteralPath $state){ $i=[int]((Get-Content -LiteralPath $state -TotalCount 1)) }
::PS::  if($i -eq 0 -and -not (Test-Path -LiteralPath ($src + '.baseline'))){ Copy-Item -LiteralPath $src ($src + '.baseline') -Force; Write-Host 'baseline snapshot saved: ' ($src + '.baseline') }
::PS::  $grid=@(@(24,24),@(80,24),@(136,24),@(24,82),@(80,82),@(136,82))
::PS::  $auto=$false
::PS::  $cx=$env:PFC_X; $cy=$env:PFC_Y
::PS::  if(("x$cx" -eq 'x') -or ("x$cy" -eq 'x')){
::PS::    if($i -ge $grid.Count){ Write-Host ('All ' + $grid.Count + ' sweep passes are done. Analyze:  python tools/probe_read.py FINAL.xml --baseline FILENAME.baseline'); exit 0 }
::PS::    $cx=$grid[$i][0]; $cy=$grid[$i][1]; $auto=$true
::PS::  }
::PS::  $px=[int]$cx*16+8; $py=[int]$cy*16+8
::PS::  $newp='<Position><X>' + $px + '</X><Y>' + $py + '</Y></Position>'
::PS::  $nt=$t.Remove($pi+$m.Index,$m.Length).Insert($pi+$m.Index,$newp)
::PS::  $loc=$env:PFC_LOC
::PS::  if($loc){
::PS::    if($nt -match '(?s)<homeLocation>.*?</homeLocation>'){
::PS::      $nt=[regex]::Replace($nt,'(?s)<homeLocation>.*?</homeLocation>','<homeLocation><string>' + $loc + '</string></homeLocation>',1)
::PS::    } else {
::PS::      $nt=[regex]::Replace($nt,'<Position>', '<homeLocation><string>' + $loc + '</string></homeLocation><Position>',1)
::PS::    }
::PS::  }
::PS::  [IO.File]::WriteAllText($src,$nt,(New-Object Text.UTF8Encoding($true)))
::PS::  if($auto){ Set-Content -LiteralPath $state -Value ($i+1) }
::PS::  $tag=''; if([int]$cx -gt 118 -or [int]$cy -gt 118){ $tag='  (far corner: on maps smaller than this the game clamps the player toward the edge - acceptable, boxes overlap)' }
::PS::  Write-Host ('spawn set to tile ' + $cx + ',' + $cy + ' (pixels ' + $px + ',' + $py + ')' + $tag)
::PS::  Write-Host ('pass: ' + ($i+1) + ' of ' + $grid.Count + ' auto-sweep' )
::PS::  Write-Host 'NOW: load this save -> wait ~10 seconds -> walk the map as far as you can within that box -> Save and quit (do NOT sleep).'
::PS::  Write-Host 'THEN: convert the save back to XML, overwrite the same working file, run this bat again for the next pass.'
::PS::  exit
::PS::}
::PS::$n=($maxx+1)*($maxy+1)
::PS::if($n -gt 20000000){ Write-Host 'range too big, abort'; exit 1 }
::PS::$sb=New-Object Text.StringBuilder
::PS::$null=$sb.Append('<terrainFeatures>')
::PS::for($y=0;$y -le $maxy;$y++){for($x=0;$x -le $maxx;$x++){$null=$sb.Append('<item><key><Vector2><X>').Append($x).Append('</X><Y>').Append($y).Append('</Y></Vector2></key><value>').Append($inner).Append('</value></item>')}}
::PS::$null=$sb.Append('</terrainFeatures>')
::PS::$section=$sb.ToString()
::PS::$enc=New-Object Text.UTF8Encoding($true)
::PS::Write-Host ('probe section: ' + $ptxt + ' x ' + $n + ' tiles, ' + ('{0:N1} MB' -f ($section.Length/1MB)))
::PS::if($mode -eq 'A'){
::PS::  $dir=[IO.Path]::GetDirectoryName($src); if($dir){ New-Item -ItemType Directory -Force -Path $dir | Out-Null }
::PS::  [IO.File]::WriteAllText($src,$section,$enc)
::PS::  Write-Host ('wrote: ' + $src)
::PS::  try{ Set-Clipboard -Value $section; Write-Host 'full section also copied to CLIPBOARD' }catch{ Write-Host 'clipboard not available - open the txt and copy manually' }
::PS::  Write-Host ''
::PS::  Write-Host 'PASTE IT: replace the whole terrainFeatures block of the zone XML:'
::PS::  Write-Host '  delete everything between <terrainFeatures> and </terrainFeatures>, then paste'
::PS::  Write-Host '  (keep exactly ONE such block per location).'
::PS::  Write-Host 'ALSO delete the old <objects>, <largeTerrainFeatures>, <resourceClumps>,'
::PS::  Write-Host '  <farmPatches> blocks of that location - leftover litter or bushes on probe'
::PS::  Write-Host '  tiles create false holes. <buildings> may stay (footprint holes are a feature).'
::PS::  Write-Host 'NEVER paste TerrainFeature entries into <objects> - the game cannot load that.'
::PS::  exit
::PS::}
::PS::$targets=@()
::PS::if(Test-Path -LiteralPath $src -PathType Container){
::PS::  $targets=@(Get-ChildItem -LiteralPath $src -Recurse -File | Where-Object {$_.Length -gt 500 -and $_.Name -notmatch 'SaveGameInfo|probe_bak|baseline|\.md$|\.csv$|\.txt$|\.sweep$'})
::PS::}else{
::PS::  $targets=@([IO.FileInfo]::new($src))
::PS::}
::PS::$tags=@('objects','largeTerrainFeatures','resourceClumps','farmPatches')
::PS::$done=0
::PS::foreach($f in $targets){
::PS::  if(-not $f.Exists){ Write-Host ('missing: ' + $f.FullName); continue }
::PS::  $t=[IO.File]::ReadAllText($f.FullName)
::PS::  if($t -notmatch '<GameLocation'){ continue }
::PS::  $orig=$t
::PS::  $ms=[regex]::Matches($t,'(?s)<GameLocation(?:\s[^>]*)?>.*?</GameLocation>')
::PS::  if($ms.Count -eq 0){ Write-Host ($f.Name + ': skip, no CLOSED </GameLocation> found'); continue }
::PS::  if($ms.Count -gt 1 -and -not $zone){ Write-Host ($f.Name + ': WARNING - ' + $ms.Count + ' locations in file, patching ALL (set a zone filter to be safe)') }
::PS::  $sbo=New-Object Text.StringBuilder
::PS::  $pos=0; $k=0
::PS::  foreach($b in $ms){
::PS::    $matched=$true
::PS::    if($zone){ $matched = ($b.Value -match ('<GameLocation[^>]*xsi:type="' + [regex]::Escape($zone) + '"')) }
::PS::    if(-not $matched){ $null=$sbo.Append($t.Substring($pos, $b.Index + $b.Length - $pos)); $pos=$b.Index + $b.Length; continue }
::PS::    $blk=$b.Value
::PS::    if($clear -notmatch '^[nN]'){
::PS::      foreach($tg in $tags){
::PS::        $blk=[regex]::Replace($blk, '<' + $tg + '[^>]*/>', '<' + $tg + '></' + $tg + '>')
::PS::        $blk=[regex]::Replace($blk, '(?s)<' + $tg + '(?:\s[^>]*)?>.*?</' + $tg + '>', '<' + $tg + ' />')
::PS::      }
::PS::    }
::PS::    if($dropb -match '^[yY]'){
::PS::      $blk=[regex]::Replace($blk,'<buildings[^>]*/>','<buildings></buildings>')
::PS::      $blk=[regex]::Replace($blk,'(?s)<buildings(?:\s[^>]*)?>.*?</buildings>','<buildings />')
::PS::    }
::PS::    if([regex]::IsMatch($blk,'(?s)<terrainFeatures(?:\s[^>]*)?>.*?</terrainFeatures>')){
::PS::      $blk=[regex]::Replace($blk,'(?s)<terrainFeatures(?:\s[^>]*)?>.*?</terrainFeatures>',$section,1)
::PS::    }elseif([regex]::IsMatch($blk,'<terrainFeatures[^>]*/>')){
::PS::      $blk=[regex]::Replace($blk,'<terrainFeatures[^>]*/>',$section)
::PS::    }elseif($blk.Contains('<waterColor>')){
::PS::      $blk=[regex]::Replace($blk,'<waterColor>', $section + '<waterColor>', 1)
::PS::    }else{
::PS::      Write-Host ($f.Name + ': WARN no terrainFeatures/waterColor anchor - location unchanged')
::PS::    }
::PS::    $null=$sbo.Append($t.Substring($pos, $b.Index - $pos)).Append($blk)
::PS::    $pos=$b.Index+$b.Length; $k++
::PS::  }
::PS::  $null=$sbo.Append($t.Substring($pos))
::PS::  $nt=$sbo.ToString()
::PS::  if($k -eq 0){ Write-Host ($f.Name + ': no location matched filter (' + $zone + '), untouched'); continue }
::PS::  if($ms.Count -eq 1){
::PS::    if(([regex]::Matches($nt,'<player>')).Count -gt ([regex]::Matches($nt,'</player>')).Count){ $nt=$nt + '</player>' }
::PS::    if(([regex]::Matches($nt,'<SaveGame')).Count -gt ([regex]::Matches($nt,'</SaveGame>')).Count){ $nt=$nt + '</SaveGame>' }
::PS::  }
::PS::  if($nt -eq $orig){ Write-Host ($f.Name + ': unchanged'); continue }
::PS::  [IO.File]::Copy($f.FullName, $f.FullName + '.probe_bak', $true)
::PS::  [IO.File]::WriteAllText($f.FullName, $nt, $enc)
::PS::  Write-Host ($f.Name + ': patched ' + $k + ' location(s), now ' + ('{0:N1}' -f ($nt.Length/1MB)) + ' MB, backup .probe_bak')
::PS::  $done++
::PS::}
::PS::Write-Host ('DONE: ' + $done + ' file(s) patched with ' + $ptxt + ' probes.')
::PS::Write-Host 'Play loop: load -> ~10s wait -> walk the box around you -> save and quit (never sleep).'
::PS::Write-Host 'Then convert back to XML and run:  python tools/probe_read.py played.xml --baseline probeNN.xml'
::PS::Write-Host 'The reader explains what got pruned, what became bushes, and the gate shape. Then use mode C sweeps.'
