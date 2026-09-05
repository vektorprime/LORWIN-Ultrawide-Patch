# LORWIN Legacy Edition — 3440x1440 ultrawide patch

Static-only fix, game not run during development. Replaces the unused 5:4 aspect
entry with the 3440/1440 aspect so the mode passes the game's filter.

## What it does
- `witn.exe` file offset `0xA46C5C`: `00 00 A0 3F` (1.25) → `8E E3 18 40` (2.3888889)
  Table at `0xA46C50`: 1.7777 / 1.6 / 1.3333 / **2.38888**
- `%LOCALAPPDATA%\Aspyr\War in the North\GameSettings.dat` offsets `0x2C`/`0x30`:
  1920x1080 → 3440x1440

## Never used git? No git needed

1. Download this zip in your browser and extract it to your Desktop:
   https://github.com/vektorprime/LORWIN-Ultrawide-Patch/archive/refs/heads/main.zip
2. Open the extracted folder (`LORWIN-Ultrawide-Patch-main`).
3. Double-click `Run_Patch.bat`.

Single files, right-click Save link as:
- https://raw.githubusercontent.com/vektorprime/LORWIN-Ultrawide-Patch/main/LORWIN_ultrawide_patch.ps1
- https://raw.githubusercontent.com/vektorprime/LORWIN-Ultrawide-Patch/main/Run_Patch.bat
- https://raw.githubusercontent.com/vektorprime/LORWIN-Ultrawide-Patch/main/LORWIN_ultrawide_patch.py

## Before you start

1. Close the game fully (Steam must not show it Running).
2. Set Windows desktop to 3440x1440.

## OPTION A — No Python (recommended, Windows built-in)

Easiest. Uses only built-in PowerShell. If you get access denied, re-open PowerShell as Administrator and re-run.

Get the files either way: `git clone` below, or download the zip / single files in "Never used git?" above, then run from the extracted folder.

```powershell
git clone https://github.com/vektorprime/LORWIN-Ultrawide-Patch.git
cd LORWIN-Ultrawide-Patch
powershell -ExecutionPolicy Bypass -File .\LORWIN_ultrawide_patch.ps1 -CheckOnly   # before: confirms game found
powershell -ExecutionPolicy Bypass -File .\LORWIN_ultrawide_patch.ps1              # apply patch
```

Or just double-click `Run_Patch.bat`.

Custom paths / revert:

```powershell
powershell -ExecutionPolicy Bypass -File .\LORWIN_ultrawide_patch.ps1 -Exe "C:\Program Files (x86)\Steam\steamapps\common\LORWIN\witn.exe" -Settings "$env:LOCALAPPDATA\Aspyr\War in the North\GameSettings.dat"
powershell -ExecutionPolicy Bypass -File .\LORWIN_ultrawide_patch.ps1 -Revert
```

Then launch the game and pick 3440x1440 in PC Change Resolution.

## OPTION B — Python (same fix, if you prefer Python)

Get the files either way: `git clone` below, or download the zip / single files in "Never used git?" above, then run from the extracted folder.

```powershell
git clone https://github.com/vektorprime/LORWIN-Ultrawide-Patch.git
cd LORWIN-Ultrawide-Patch
python .\LORWIN_ultrawide_patch.py --check-only   # before: confirms game found, shows 1920x1080
python .\LORWIN_ultrawide_patch.py              # apply patch
python .\LORWIN_ultrawide_patch.py --check-only   # after: confirms 3440x1440
```

Or if you downloaded the zip to your Desktop:

```powershell
cd "$env:USERPROFILE\Desktop\LORWIN_Ultrawide_Patch"
```

Custom paths / revert:

```powershell
python .\LORWIN_ultrawide_patch.py --exe "C:\Program Files (x86)\Steam\steamapps\common\LORWIN\witn.exe" --settings "$env:LOCALAPPDATA\Aspyr\War in the North\GameSettings.dat"
python .\LORWIN_ultrawide_patch.py --revert
```

Then launch the game and pick 3440x1440 in PC Change Resolution.

## Notes

Backups are created next to originals (`*.bak_1080p`). Steam Verify/updates revert the exe — just re-run. Videos pillarbox, 3D is Hor+.
Only share these scripts + README, never the patched exe.
