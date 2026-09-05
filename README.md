# LORWIN Legacy Edition — 3440x1440 ultrawide patch

Static-only fix, game not run during development. Replaces the unused 5:4 aspect
entry with the 3440/1440 aspect so the mode passes the game's filter.

## What it does
- `witn.exe` file offset `0xA46C5C`: `00 00 A0 3F` (1.25) → `8E E3 18 40` (2.3888889)
  Table at `0xA46C50`: 1.7777 / 1.6 / 1.3333 / **2.38888**
- `%LOCALAPPDATA%\Aspyr\War in the North\GameSettings.dat` offsets `0x2C`/`0x30`:
  1920x1080 → 3440x1440

## Use
1. Close the game fully (Steam must not show it Running).
2. `python LORWIN_ultrawide_patch.py` (admin shell if SteamLibrary denies writes).
3. Set Windows desktop to 3440x1440, launch, pick 3440x1440 in PC Change Resolution.
4. Revert: `python LORWIN_ultrawide_patch.py --revert`.
5. Check only: `python LORWIN_ultrawide_patch.py --check-only`.

## Example

```powershell
cd "C:\Users\vicha\Desktop\LORWIN_Ultrawide_Patch"
python .\LORWIN_ultrawide_patch.py --check-only
python .\LORWIN_ultrawide_patch.py
python .\LORWIN_ultrawide_patch.py --check-only
```

Custom paths / revert:

```powershell
python .\LORWIN_ultrawide_patch.py --exe "E:\SteamLibrary\steamapps\common\LORWIN\witn.exe" --settings "$env:LOCALAPPDATA\Aspyr\War in the North\GameSettings.dat"
python .\LORWIN_ultrawide_patch.py --revert
```

If access denied, re-open PowerShell as Administrator and re-run.

Backups are created next to originals (`*.bak_1080p`). Steam Verify/updates revert the exe — just re-run. Videos pillarbox, 3D is Hor+.
Only send this script + README, never the patched exe.
