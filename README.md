# LORWIN Legacy Edition — ultrawide patch (2560x1080 and up)

Static-only fix, game not run during development. Replaces the legacy aspect
filter table with popular widescreen aspects above 1920x1080.

## What it does
- `witn.exe` aspect table at file offset `0xA46C50` (16 bytes) becomes:
  1.77778 (16:9 — 1920x1080, 2560x1440, 3840x2160) /
  2.37037 (21:9 — 2560x1080, 5120x2160) /
  2.38889 (UW — 3440x1440) /
  3.55556 (32:9 — 3840x1080, 5120x1440)
- Drops legacy 16:10 / 4:3 / 5:4 from the resolution list (revert restores them).
- `%LOCALAPPDATA%\Aspyr\War in the North\GameSettings.dat` offsets `0x2C`/`0x30`:
  1920x1080 → 3440x1440

## Before you start

1. Close the game fully (Steam must not show it Running).
2. Set Windows desktop to 3440x1440.

## OPTION A — No Python (recommended, Windows built-in)

Easiest. Uses only built-in PowerShell. If you get access denied, re-open PowerShell as Administrator and re-run.

Get the files one of these two ways:

- `git clone`:
  ```powershell
  git clone https://github.com/vektorprime/LORWIN-Ultrawide-Patch.git
  cd LORWIN-Ultrawide-Patch
  ```
- Or no git: download this zip in your browser and extract it:
  https://github.com/vektorprime/LORWIN-Ultrawide-Patch/archive/refs/heads/main.zip

Then run:

```powershell
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

Get the files one of these two ways:

- `git clone`:
  ```powershell
  git clone https://github.com/vektorprime/LORWIN-Ultrawide-Patch.git
  cd LORWIN-Ultrawide-Patch
  ```
- Or no git: download this zip in your browser and extract it:
  https://github.com/vektorprime/LORWIN-Ultrawide-Patch/archive/refs/heads/main.zip
  then:
  ```powershell
  cd "$env:USERPROFILE\Desktop\LORWIN-Ultrawide-Patch-main"
  ```

Then run:

```powershell
python .\LORWIN_ultrawide_patch.py --check-only   # before: confirms game found, shows 1920x1080
python .\LORWIN_ultrawide_patch.py              # apply patch
python .\LORWIN_ultrawide_patch.py --check-only   # after: confirms 3440x1440
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
