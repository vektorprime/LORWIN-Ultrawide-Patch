<# LORWIN Legacy Edition 3440x1440 ultrawide patch - no Python required.
Uses only built-in Windows PowerShell 5.1+.
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
$PATCH = 0xA46C5C
$OLD_BYTES = [byte[]](0x00,0x00,0xA0,0x3F)   # 1.25f
$NEW_BYTES = [byte[]](0x8E,0xE3,0x18,0x40)   # 2.3888889f (3440/1440)
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
$already = [Math]::Abs($floats[3] - 2.3888889) -lt 0.001
if (-not $already) {
  if (-not ([Math]::Abs($floats[0]-1.7777778) -lt 0.01 -and [Math]::Abs($floats[1]-1.6) -lt 0.01 -and [Math]::Abs($floats[2]-1.3333334) -lt 0.01 -and [Math]::Abs($floats[3]-1.25) -lt 0.01)) {
    Write-Output "Unexpected table - wrong exe version?"; exit 3
  }
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
  for ($i=0; $i -lt 4; $i++) { $data[$PATCH+$i] = $NEW_BYTES[$i] }
  [IO.File]::WriteAllBytes($Exe, $data)
  Write-Output ("patched exe 0x{0:X}: 1.25 -> {1}" -f $PATCH, (3440/1440))
} else { Write-Output "exe already patched" }

$s = [IO.File]::ReadAllBytes($Settings)
if ($s.Length -ne 512) { Write-Output "Unexpected GameSettings.dat length $($s.Length)"; exit 3 }
[Array]::Copy([BitConverter]::GetBytes([UInt32]3440), 0, $s, $W_OFF, 4)
[Array]::Copy([BitConverter]::GetBytes([UInt32]1440), 0, $s, $H_OFF, 4)
[IO.File]::WriteAllBytes($Settings, $s)
Write-Output "patched settings to 3440x1440. Done. Select it in-game under PC Change Resolution."
