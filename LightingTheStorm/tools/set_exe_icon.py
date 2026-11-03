"""Replace the icon of a Windows .exe with the images in an .ico, using the Win32 resource API (what rcedit does).

  python -I tools/set_exe_icon.py ../build/windows/LightingTheStorm.exe Assets/UI/app_icon.ico

Godot does this itself with rcedit when it is installed (Editor Settings > Export > Windows > rcedit); it is not, so run this after
every Windows export (requirements.md, "Building the download").

Every icon group in the exe (Godot ships one) is pointed at the new images; the old images are deleted.
"""
import ctypes
import struct
import sys
from ctypes import wintypes

RT_ICON, RT_GROUP_ICON = 3, 14
k32 = ctypes.WinDLL("kernel32", use_last_error=True)
k32.LoadLibraryExW.restype = wintypes.HMODULE
k32.LoadLibraryExW.argtypes = [wintypes.LPCWSTR, wintypes.HANDLE, wintypes.DWORD]
k32.BeginUpdateResourceW.restype = wintypes.HANDLE
k32.BeginUpdateResourceW.argtypes = [wintypes.LPCWSTR, wintypes.BOOL]
k32.UpdateResourceW.argtypes = [wintypes.HANDLE, wintypes.LPVOID, wintypes.LPVOID, wintypes.WORD, wintypes.LPVOID, wintypes.DWORD]
k32.EndUpdateResourceW.argtypes = [wintypes.HANDLE, wintypes.BOOL]
k32.FreeLibrary.argtypes = [wintypes.HMODULE]
ENUMNAME = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HMODULE, wintypes.LPVOID, wintypes.LPVOID, wintypes.LPARAM)
ENUMLANG = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HMODULE, wintypes.LPVOID, wintypes.LPVOID, wintypes.WORD, wintypes.LPARAM)
k32.EnumResourceNamesW.argtypes = [wintypes.HMODULE, wintypes.LPVOID, ENUMNAME, wintypes.LPARAM]
k32.EnumResourceLanguagesW.argtypes = [wintypes.HMODULE, wintypes.LPVOID, wintypes.LPVOID, ENUMLANG, wintypes.LPARAM]


def name_key(p):
    v = p if isinstance(p, int) else (p or 0)
    return v if v < 0x10000 else ctypes.wstring_at(v)   # an integer id, or a string name


def existing(exe):
    h = k32.LoadLibraryExW(exe, None, 0x2)              # LOAD_LIBRARY_AS_DATAFILE
    if not h:
        raise OSError(ctypes.get_last_error(), "cannot open " + exe)
    found = {RT_ICON: [], RT_GROUP_ICON: []}
    for rt in found:
        names = []
        k32.EnumResourceNamesW(h, rt, ENUMNAME(lambda m, t, n, l: names.append(name_key(n)) or True), 0)
        for n in names:
            langs = []
            nm = ctypes.c_void_p(n) if isinstance(n, int) else ctypes.c_wchar_p(n)
            k32.EnumResourceLanguagesW(h, rt, nm, ENUMLANG(lambda m, t, nn, lang, l: langs.append(lang) or True), 0)
            found[rt] += [(n, lang) for lang in langs]
    k32.FreeLibrary(h)
    return found


def res_name(n):
    return ctypes.c_void_p(n) if isinstance(n, int) else ctypes.c_wchar_p(n)


def main(exe, ico):
    data = open(ico, "rb").read()
    _, kind, count = struct.unpack_from("<HHH", data, 0)
    assert kind == 1, "not an .ico"
    images = []
    for i in range(count):
        w, h, colours, res, planes, bpp, size, offset = struct.unpack_from("<BBBBHHII", data, 6 + 16 * i)
        images.append(((w, h, colours, res, planes, bpp, size), data[offset:offset + size]))
    found = existing(exe)
    groups = found[RT_GROUP_ICON] or [(1, 1033)]
    lang = groups[0][1]
    first_id = max([n for n, _ in found[RT_ICON] if isinstance(n, int)] + [0]) + 1
    upd = k32.BeginUpdateResourceW(exe, False)
    if not upd:
        raise OSError(ctypes.get_last_error(), "BeginUpdateResource failed")
    for n, lg in found[RT_ICON]:                          # drop the old images
        k32.UpdateResourceW(upd, RT_ICON, res_name(n), lg, None, 0)
    grp = struct.pack("<HHH", 0, 1, len(images))
    for i, (hdr, img) in enumerate(images):
        rid = first_id + i
        buf = ctypes.create_string_buffer(img, len(img))
        if not k32.UpdateResourceW(upd, RT_ICON, ctypes.c_void_p(rid), lang, buf, len(img)):
            raise OSError(ctypes.get_last_error(), "UpdateResource RT_ICON failed")
        grp += struct.pack("<BBBBHHIH", *hdr, rid)
    gbuf = ctypes.create_string_buffer(grp, len(grp))
    for n, lg in groups:                                  # every group shows the new images
        if not k32.UpdateResourceW(upd, RT_GROUP_ICON, res_name(n), lg, gbuf, len(grp)):
            raise OSError(ctypes.get_last_error(), "UpdateResource RT_GROUP_ICON failed")
    if not k32.EndUpdateResourceW(upd, False):
        raise OSError(ctypes.get_last_error(), "EndUpdateResource failed")
    print(f"{exe}: {len(images)} icon images in {len(groups)} group(s) {[g[0] for g in groups]}, ids {first_id}..{first_id + len(images) - 1}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
