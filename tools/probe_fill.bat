@echo off
chcp 65001 >nul
setlocal EnableExtensions
title Stardew ground-probe filler
rem ==================================================================
rem  Stardew ground-probe filler
rem  ----------------------------------------------------------------
rem  Fills <terrainFeatures> with a HoeDirt (tilled dirt) probe on
rem  every tile 0,0 .. maxX,maxY. On save load the game validates
rem  every dirt tile (HoeDirt.checkForRemoval) and DELETES dirt that
rem  is not on valid diggable ground / off-map / under a building /
rem  covered by an object, bush, clump.  Surviving dirt afterwards =
rem  exact "nature ground" coordinate map of the zone.
rem
rem  Mode A: write the whole terrainFeatures section into a .txt and
rem          copy it to clipboard - you paste it into a zone XML.
rem  Mode B: patch XML file or folder IN PLACE (backup .probe_bak):
rem          - replaces each <GameLocation>'s <terrainFeatures>
rem          - clears <objects>/<largeTerrainFeatures>/<resourceClumps>/
rem            <farmPatches> so nothing covers the probes
rem          - optionally empties <buildings> (they also make holes;
rem            keep them if you want building footprints visible)
rem          - closes unclosed <player>/<SaveGame> in your fragments
rem
rem  NOTE: dirt MUST live in terrainFeatures - pasting TerrainFeature
rem  entries into <objects> breaks the save (game cannot deserialize).
rem
rem  You can also drag&drop a file/folder onto this .bat -> mode B.
rem  Needs: Windows 10/11 (PowerShell 5 comes with it).
rem ==================================================================

set "PFBAT=%~f0"

if not "%~1"=="" (
  set "PF_MODE=B"
  set "PF_SRC=%~1"
  set "PF_ZONE="
  set "PF_CLEAR=Y"
  set "PF_DROPBLD=N"
  echo Dropped: %~1  - mode B, all locations, clear nature, keep buildings.
  goto :GRID
)

echo   [A] generate terrainFeatures_probe.txt (manual paste + clipboard)
echo   [B] patch a save / zone-fragment XML file or folder in place
set "PF_MODE="
set /p "PF_MODE=mode (A or B) [A]: "
if /I "%PF_MODE%"=="B" goto :B_MAIN

:A_MAIN
set "PF_SRC=%CD%\terrainFeatures_probe.txt"
set /p "PF_SRC=output txt [%CD%\terrainFeatures_probe.txt]: "
set "PF_ZONE="
set "PF_CLEAR=Y"
set "PF_DROPBLD=N"
goto :GRID

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

:GRID
set "PF_MAXX=150"
set /p "PF_MAXX=max X coordinate [150]: "
set "PF_MAXY=150"
set /p "PF_MAXY=max Y coordinate [150]: "
echo.

findstr /b /c:"::PS::" "%PFBAT%" | powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=[Console]::In.ReadToEnd(); $s=$s -replace '::PS::',''; Invoke-Expression $s"
if errorlevel 1 echo (PowerShell reported a problem - see messages above)
echo.
pause
exit /b

::PS::$ErrorActionPreference='Stop'
::PS::$mode=$env:PF_MODE
::PS::$src=$env:PF_SRC
::PS::$zone=$env:PF_ZONE
::PS::$maxx=150; if($env:PF_MAXX -match '^[0-9]+$'){$maxx=[int]$env:PF_MAXX}
::PS::$maxy=150; if($env:PF_MAXY -match '^[0-9]+$'){$maxy=[int]$env:PF_MAXY}
::PS::$clear=$env:PF_CLEAR
::PS::$dropb=$env:PF_DROPBLD
::PS::$n=($maxx+1)*($maxy+1)
::PS::if($n -gt 20000000){Write-Host 'range too big, abort'; exit 1}
::PS::$sb=New-Object Text.StringBuilder
::PS::$null=$sb.Append('<terrainFeatures>')
::PS::for($y=0;$y -le $maxy;$y++){for($x=0;$x -le $maxx;$x++){$null=$sb.Append('<item><key><Vector2><X>').Append($x).Append('</X><Y>').Append($y).Append('</Y></Vector2></key><value><TerrainFeature xsi:type="HoeDirt" /></value></item>')}}
::PS::$null=$sb.Append('</terrainFeatures>')
::PS::$section=$sb.ToString()
::PS::$enc=New-Object Text.UTF8Encoding($true)
::PS::Write-Host ('probe section: ' + $n + ' dirt tiles, ' + ('{0:N1} MB' -f ($section.Length/1MB)))
::PS::if($mode -eq 'A'){
::PS::  $dir=[IO.Path]::GetDirectoryName($src); if($dir){New-Item -ItemType Directory -Force -Path $dir | Out-Null}
::PS::  [IO.File]::WriteAllText($src,$section,$enc)
::PS::  Write-Host ('wrote: ' + $src)
::PS::  try{ Set-Clipboard -Value $section; Write-Host 'full section also copied to CLIPBOARD' }catch{ Write-Host 'clipboard not available - open the txt and copy manually' }
::PS::  Write-Host ''
::PS::  Write-Host 'PASTE IT: replace the whole terrainFeatures block in the zone XML:'
::PS::  Write-Host '   delete everything between <terrainFeatures> and </terrainFeatures>,'
::PS::  Write-Host '   then paste (keep only ONE such block per location).'
::PS::  Write-Host 'ALSO in that location delete old: <objects>, <largeTerrainFeatures>,'
::PS::  Write-Host '  <resourceClumps>, <farmPatches> blocks (or replace them with <objects /> etc).'
::PS::  Write-Host '  <buildings> may stay - dirt under them will be pruned on load, that is a feature.'
::PS::  Write-Host 'DO NOT paste dirt into <objects> - TerrainFeature there = broken save.'
::PS::  exit
::PS::}
::PS::$targets=@()
::PS::if(Test-Path -LiteralPath $src -PathType Container){
::PS::  $targets=@(Get-ChildItem -LiteralPath $src -Recurse -File | Where-Object {$_.Length -gt 500 -and $_.Name -notmatch 'SaveGameInfo|probe_bak|\.md$|\.csv$|\.txt$'})
::PS::}else{
::PS::  $targets=@([IO.FileInfo]::new($src))
::PS::}
::PS::$tags=@('objects','largeTerrainFeatures','resourceClumps','farmPatches')
::PS::$done=0
::PS::foreach($f in $targets){
::PS::  if(-not $f.Exists){Write-Host ('missing: ' + $f.FullName); continue}
::PS::  $t=[IO.File]::ReadAllText($f.FullName)
::PS::  if($t -notmatch '<GameLocation'){continue}
::PS::  $orig=$t
::PS::  $ms=[regex]::Matches($t,'(?s)<GameLocation(?:\s[^>]*)?>.*?</GameLocation>')
::PS::  if($ms.Count -eq 0){Write-Host ($f.Name + ': skip, no CLOSED </GameLocation> found'); continue}
::PS::  if($ms.Count -gt 1 -and -not $zone){Write-Host ($f.Name + ': WARNING - ' + $ms.Count + ' locations in file, patching ALL (set a zone filter to be safe)')}
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
::PS::  if($k -eq 0){Write-Host ($f.Name + ': no location matched filter (' + $zone + '), untouched'); continue}
::PS::  if($ms.Count -eq 1){
::PS::    if(([regex]::Matches($nt,'<player>')).Count -gt ([regex]::Matches($nt,'</player>')).Count){$nt=$nt + '</player>'}
::PS::    if(([regex]::Matches($nt,'<SaveGame')).Count -gt ([regex]::Matches($nt,'</SaveGame>')).Count){$nt=$nt + '</SaveGame>'}
::PS::  }
::PS::  if($nt -eq $orig){Write-Host ($f.Name + ': unchanged'); continue}
::PS::  [IO.File]::Copy($f.FullName, $f.FullName + '.probe_bak', $true)
::PS::  [IO.File]::WriteAllText($f.FullName, $nt, $enc)
::PS::  Write-Host ($f.Name + ': patched ' + $k + ' location(s), now ' + ('{0:N1}' -f ($nt.Length/1MB)) + ' MB, backup: .probe_bak')
::PS::  $done++
::PS::}
::PS::Write-Host ('DONE: ' + $done + ' file(s) patched.')
::PS::Write-Host 'Play: load the save (or assemble fragments first), wait ~10s, SAVE AND QUIT without sleeping.'
::PS::Write-Host 'Then convert back to XML and check with:  python tools/probe_read.py result.xml --out probe_results'
