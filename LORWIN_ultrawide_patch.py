"""LORWIN Legacy Edition (Steam App 2523770) ultrawide patch.
Replaces the legacy aspect filter table with popular >1080p aspects:
  16:9 (1920x1080, 2560x1440, 3840x2160), 21:9 (2560x1080, 5120x2160),
  UW 3440x1440, 32:9 (3840x1080, 5120x1440).
Drops legacy 16:10/4:3/5:4 from the resolution list (revert restores them).
Does NOT distribute game files - patches the user's own install.

Usage:
  python LORWIN_ultrawide_patch.py [--exe PATH] [--settings PATH] [--revert] [--check-only]
  Close the game first. Run from admin shell if SteamLibrary needs elevation.

Defaults (auto-detected if not given):
  exe: <steam>/steamapps/common/LORWIN/witn.exe (searches all steam libraries)
  settings: %LOCALAPPDATA%/Aspyr/War in the North/GameSettings.dat
"""
import argparse, hashlib, os, pathlib, shutil, struct, sys

TABLE_OFFSET = 0xA46C50
# v2 popular table: 16:9 | 21:9 (2560x1080) | UW (3440x1440) | 32:9 (5120x1440)
NEW_TABLE = struct.pack('<4f', 1.7777778, 2560/1080, 3440/1440, 5120/1440)
# accepted "before" states: v1.0 original and v1.1 (single-3440 patch)
V10_TABLE = struct.pack('<4f', 1.7777778, 1.6, 1.3333334, 1.25)
V11_TABLE = struct.pack('<4f', 1.7777778, 1.6, 1.3333334, 3440/1440)
WIDTH_OFFSET, HEIGHT_OFFSET = 0x2C, 0x30
NEW_W, NEW_H = struct.pack('<I', 3440), struct.pack('<I', 1440)

def find_exe():
    cands = []
    # steam libraryfolders.vdf
    for base in [pathlib.Path("C:/Program Files (x86)/Steam"), pathlib.Path("C:/Program Files/Steam")]:
        vdf = base / "steamapps/libraryfolders.vdf"
        if vdf.exists():
            try:
                txt = vdf.read_text(errors="ignore")
                import re
                for m in re.finditer(r'"path"\s+"([^"]+)"', txt):
                    cands.append(pathlib.Path(m.group(1)) / "steamapps/common/LORWIN/witn.exe")
            except Exception:
                pass
    # Default Steam install location first (most users)
    cands.append(pathlib.Path("C:/Program Files (x86)/Steam/steamapps/common/LORWIN/witn.exe"))
    cands.append(pathlib.Path("C:/Program Files/Steam/steamapps/common/LORWIN/witn.exe"))
    for drive in ["C:", "D:", "E:", "F:", "G:"]:
        cands.append(pathlib.Path(f"{drive}/SteamLibrary/steamapps/common/LORWIN/witn.exe"))
        cands.append(pathlib.Path(f"{drive}/Program Files (x86)/Steam/steamapps/common/LORWIN/witn.exe"))
        cands.append(pathlib.Path(f"{drive}/Steam/steamapps/common/LORWIN/witn.exe"))
    for c in cands:
        if c.exists() and c.stat().st_size > 10_000_000:
            return c
    return None

def find_settings():
    local = os.environ.get("LOCALAPPDATA", "")
    p = pathlib.Path(local) / "Aspyr/War in the North/GameSettings.dat"
    return p if p.exists() else None

def sha(p): return hashlib.sha256(pathlib.Path(p).read_bytes()).hexdigest()[:16]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--exe", default=None)
    ap.add_argument("--settings", default=None)
    ap.add_argument("--revert", action="store_true")
    ap.add_argument("--check-only", action="store_true")
    a = ap.parse_args()
    exe = pathlib.Path(a.exe) if a.exe else find_exe()
    settings = pathlib.Path(a.settings) if a.settings else find_settings()
    if not exe or not exe.exists():
        print("witn.exe not found. Pass --exe PATH"); sys.exit(2)
    if not settings or not settings.exists():
        print("GameSettings.dat not found. Pass --settings PATH"); sys.exit(2)
    exe_bak = exe.with_suffix(".exe.bak_1080p")
    set_bak = settings.with_suffix(".dat.bak_1080p")
    print(f"EXE: {exe}\nSettings: {settings}")
    if a.revert:
        if exe_bak.exists(): shutil.copy2(exe_bak, exe); print(f"restored exe")
        if set_bak.exists(): shutil.copy2(set_bak, settings); print(f"restored settings")
        return
    data = exe.read_bytes()
    tbl = data[TABLE_OFFSET:TABLE_OFFSET+16]
    floats = struct.unpack('<4f', tbl)
    print(f"table @{hex(TABLE_OFFSET)}: {tbl.hex(' ')} -> {floats}")
    already = tbl == NEW_TABLE
    if not already:
        assert tbl in (V10_TABLE, V11_TABLE), "unexpected table - wrong exe version?"
    if a.check_only:
        s = settings.read_bytes()
        w, h = struct.unpack('<2I', s[WIDTH_OFFSET:HEIGHT_OFFSET+4])
        print(f"settings: {w}x{h} patched={already and (w,h)==(3440,1440)}")
        return
    if not exe_bak.exists(): shutil.copy2(exe, exe_bak); print(f"backup exe -> {exe_bak} {sha(exe_bak)}")
    if not set_bak.exists(): shutil.copy2(settings, set_bak); print(f"backup settings -> {set_bak}")
    if not already:
        patched = bytearray(data); patched[TABLE_OFFSET:TABLE_OFFSET+16] = NEW_TABLE
        exe.write_bytes(patched)
        print(f"patched exe table {hex(TABLE_OFFSET)} -> 16:9 / 21:9 / UW-3440 / 32:9")
    else: print("exe already patched")
    s = bytearray(settings.read_bytes())
    assert len(s) == 512
    s[WIDTH_OFFSET:WIDTH_OFFSET+4] = NEW_W; s[HEIGHT_OFFSET:HEIGHT_OFFSET+4] = NEW_H
    settings.write_bytes(s)
    print("patched settings to 3440x1440. Done. Select it in-game under PC Change Resolution.")

if __name__ == "__main__":
    main()
