<# LORWIN Legacy Edition ultrawide patch - no Python required.
Uses only built-in Windows PowerShell 5.1+.
Aspect table becomes 16:9 | 21:9 (2560x1080) | UW 3440x1440 | 32:9 (5120x1440).
Drops legacy 16:10/4:3/5:4 from the list (revert restores them).
Run: powershell -ExecutionPolicy Bypass -File LORWIN_ultrawide_patch.ps1 [-CheckOnly] [-Revert] [-Exe PATH] [-Settings PATH]
Or double-click Run_Patch.bat.
#>
param(
  [string]$Exe = "",
  [string]$Settings = "",
  [switch]$Revert,
  [switch]$CheckOnly
)
$ErrorActionPreference = "Stop"

$TABLE = 0xA46C50
# v2 popular table bytes: 16:9 | 21:9 (2560x1080) | UW (3440x1440) | 32:9 (5120x1440)
$NEW_TABLE = [byte[]](0x39,0x8E,0xE3,0x3F, 0x26,0xB4,0x17,0x40, 0x8E,0xE3,0x18,0x40, 0x39,0x8E,0x63,0x40)
# accepted "before" states: v1.0 original and v1.1 (single-3440 patch)
$V10_TABLE = [byte[]](0x39,0x8E,0xE3,0x3F, 0xCD,0xCC,0xCC,0x3F, 0xAB,0xAA,0xAA,0x3F, 0x00,0x00,0xA0,0x3F)
$V11_TABLE = [byte[]](0x39,0x8E,0xE3,0x3F, 0xCD,0xCC,0xCC,0x3F, 0xAB,0xAA,0xAA,0x3F, 0x8E,0xE3,0x18,0x40)
$W_OFF = 0x2C; $H_OFF = 0x30

function Find-Exe {
  $cands = @()
  foreach ($base in @("C:\Program Files (x86)\Steam","C:\Program Files\Steam")) {
    $vdf = Join-Path $base "steamapps\libraryfolders.vdf"
    if (Test-Path -LiteralPath $vdf) {
      foreach ($m in [regex]::Matches((Get-Content -LiteralPath $vdf -Raw), '"path"\s+"([^"]+)"')) {
        $lib = $m.Groups[1].Value -replace '\\\\','\'
        $cands += (Join-Path $lib "steamapps\common\LORWIN\witn.exe")
      }
    }
  }
  $cands += "C:\Program Files (x86)\Steam\steamapps\common\LORWIN\witn.exe"
  $cands += "C:\Program Files\Steam\steamapps\common\LORWIN\witn.exe"
  foreach ($d in @("C:","D:","E:","F:","G:")) {
    $cands += "$d\SteamLibrary\steamapps\common\LORWIN\witn.exe"
    $cands += "$d\Program Files (x86)\Steam\steamapps\common\LORWIN\witn.exe"
    $cands += "$d\Steam\steamapps\common\LORWIN\witn.exe"
  }
  foreach ($c in $cands) {
    if ((Test-Path -LiteralPath $c) -and ((Get-Item -LiteralPath $c).Length -gt 10000000)) { return $c }
  }
  return $null
}
function Find-Settings {
  $p = Join-Path $env:LOCALAPPDATA "Aspyr\War in the North\GameSettings.dat"
  if (Test-Path -LiteralPath $p) { return $p }
  return $null
}
function Get-Floats([byte[]]$b, [int]$off) {
  return @(
    [BitConverter]::ToSingle($b, $off),
    [BitConverter]::ToSingle($b, $off+4),
    [BitConverter]::ToSingle($b, $off+8),
    [BitConverter]::ToSingle($b, $off+12)
  )
}

if (-not $Exe) { $Exe = Find-Exe }
if (-not $Settings) { $Settings = Find-Settings }
if (-not $Exe -or -not (Test-Path -LiteralPath $Exe)) { Write-Output "witn.exe not found. Use -Exe PATH"; exit 2 }
if (-not $Settings -or -not (Test-Path -LiteralPath $Settings)) { Write-Output "GameSettings.dat not found. Use -Settings PATH"; exit 2 }
$exeBak = "$Exe.bak_1080p"
$setBak = "$Settings.bak_1080p"
Write-Output "EXE: $Exe"
Write-Output "Settings: $Settings"

if ($Revert) {
  if (Test-Path -LiteralPath $exeBak) { Copy-Item -LiteralPath $exeBak -Destination $Exe -Force; Write-Output "restored exe" }
  if (Test-Path -LiteralPath $setBak) { Copy-Item -LiteralPath $setBak -Destination $Settings -Force; Write-Output "restored settings" }
  exit 0
}

$data = [IO.File]::ReadAllBytes($Exe)
$floats = Get-Floats $data $TABLE
Write-Output ("table @{0:X}: {1} -> {2}" -f $TABLE, (($data[$TABLE..($TABLE+15)] | ForEach-Object { $_.ToString("X2") }) -join " "), ($floats -join ", "))
$cur = $data[$TABLE..($TABLE+15)]
$already = (@(Compare-Object $cur $NEW_TABLE -SyncWindow 0).Length -eq 0)
if (-not $already) {
  $isV10 = (@(Compare-Object $cur $V10_TABLE -SyncWindow 0).Length -eq 0)
  $isV11 = (@(Compare-Object $cur $V11_TABLE -SyncWindow 0).Length -eq 0)
  if (-not ($isV10 -or $isV11)) { Write-Output "Unexpected table - wrong exe version?"; exit 3 }
}

if ($CheckOnly) {
  $s = [IO.File]::ReadAllBytes($Settings)
  $w = [BitConverter]::ToUInt32($s, $W_OFF); $h = [BitConverter]::ToUInt32($s, $H_OFF)
  Write-Output "settings: ${w}x${h} patched=$($already -and $w -eq 3440 -and $h -eq 1440)"
  exit 0
}

if (-not (Test-Path -LiteralPath $exeBak)) { Copy-Item -LiteralPath $Exe -Destination $exeBak -Force; Write-Output "backup exe -> $exeBak" }
if (-not (Test-Path -LiteralPath $setBak)) { Copy-Item -LiteralPath $Settings -Destination $setBak -Force; Write-Output "backup settings -> $setBak" }
if (-not $already) {
  for ($i=0; $i -lt 16; $i++) { $data[$TABLE+$i] = $NEW_TABLE[$i] }
  [IO.File]::WriteAllBytes($Exe, $data)
  Write-Output "patched exe table -> 16:9 / 21:9 / UW-3440 / 32:9"
} else { Write-Output "exe already patched" }

$s = [IO.File]::ReadAllBytes($Settings)
if ($s.Length -ne 512) { Write-Output "Unexpected GameSettings.dat length $($s.Length)"; exit 3 }
[Array]::Copy([BitConverter]::GetBytes([UInt32]3440), 0, $s, $W_OFF, 4)
[Array]::Copy([BitConverter]::GetBytes([UInt32]1440), 0, $s, $H_OFF, 4)
[IO.File]::WriteAllBytes($Settings, $s)
Write-Output "patched settings to 3440x1440. Done. Select it in-game under PC Change Resolution."
