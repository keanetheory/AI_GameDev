"""Offline GLB auditor: empty meshes, holes (open boundary loops), degenerate triangles, size and texture cost.

Pure Python + numpy, no engine and no network. "Hollow / empty spot" is approximated three ways:
  - empty primitives, or meshes with no node using them (nothing to draw / dead weight),
  - hole loops: after welding vertices, every closed ring of open (single-use) edges. The game's generated meshes
    are closed shells, so ANY loop is a place you can see through the surface. A mesh that is open on purpose
    (a terrain slab with a rim) shows the rim as one loop: allow it with max_hole_loops = 1,
  - degenerate (zero-area) triangles, which render as cracks or sparkles.
Load time is a PROXY (file MB, triangles, texture memory); real timing needs Godot (see the objectives).
"""
import hashlib
import json
import struct
from pathlib import Path

import numpy as np

CT = {5120: np.int8, 5121: np.uint8, 5122: np.int16, 5123: np.uint16, 5125: np.uint32, 5126: np.float32}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}


def _read_glb(path: Path):
    data = path.read_bytes()
    magic, _ver, _len = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF":
        raise ValueError("not a GLB")
    off, js, binc = 12, None, b""
    while off < len(data):
        clen, ctype = struct.unpack_from("<II", data, off)
        body = data[off + 8: off + 8 + clen]
        if ctype == 0x4E4F534A:
            js = json.loads(body)
        elif ctype == 0x004E4942 and not binc:
            binc = body
        off += 8 + clen
    return js, binc


def _accessor(js, binc, idx):
    a = js["accessors"][idx]
    if "bufferView" not in a:
        return np.zeros((a["count"], NC[a["type"]]), dtype=CT[a["componentType"]])
    bv = js["bufferViews"][a["bufferView"]]
    dt, n = np.dtype(CT[a["componentType"]]), NC[a["type"]]
    stride = bv.get("byteStride") or dt.itemsize * n
    start = bv.get("byteOffset", 0) + a.get("byteOffset", 0)
    if stride == dt.itemsize * n:
        return np.frombuffer(binc, dtype=dt, count=a["count"] * n, offset=start).reshape(a["count"], n)
    raw = np.frombuffer(binc, dtype=np.uint8, count=stride * a["count"], offset=start).reshape(a["count"], stride)
    return raw[:, : dt.itemsize * n].copy().view(dt).reshape(a["count"], n)


def _image_size(js, binc, img):
    if "bufferView" not in img:
        return None
    bv = js["bufferViews"][img["bufferView"]]
    b = binc[bv.get("byteOffset", 0): bv.get("byteOffset", 0) + bv["byteLength"]]
    if b[:8] == b"\x89PNG\r\n\x1a\n":
        return struct.unpack(">II", b[16:24])
    if b[:2] == b"\xff\xd8":
        i = 2
        while i < len(b) - 9:
            if b[i] != 0xFF:
                i += 1
                continue
            m = b[i + 1]
            if m in (0xC0, 0xC1, 0xC2):
                h, w = struct.unpack(">HH", b[i + 5: i + 9])
                return w, h
            i += 2 + struct.unpack(">H", b[i + 2: i + 4])[0]
    return None


def _components(edges: np.ndarray) -> list[int]:
    """Sizes (in edges) of connected rings of boundary edges, largest first."""
    parent: dict[int, int] = {}

    def find(x):
        while parent.setdefault(x, x) != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    pairs = edges.tolist()
    for a, b in pairs:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb
    counts: dict[int, int] = {}
    for a, _ in pairs:
        r = find(a)
        counts[r] = counts.get(r, 0) + 1
    return sorted(counts.values(), reverse=True)


def audit(path: Path, cache_dir: Path | None = None) -> dict:
    path = Path(path)
    st = path.stat()
    key = hashlib.sha1(f"{path.resolve()}|{st.st_size}|{st.st_mtime_ns}".encode()).hexdigest()[:16]
    cf = None
    if cache_dir:
        cf = cache_dir / f"{path.stem}.{key}.json"
        if cf.exists():
            return json.loads(cf.read_text())
    js, binc = _read_glb(path)
    meshes = js.get("meshes", [])
    used = {n["mesh"] for n in js.get("nodes", []) if "mesh" in n}
    res = {"file": path.name, "size_mb": round(st.st_size / 1e6, 2), "nodes": len(js.get("nodes", [])),
           "meshes": len(meshes), "empty_meshes": [], "unreferenced_meshes": [], "non_triangle_prims": 0,
           "tris": 0, "verts": 0, "degenerate_tris": 0, "boundary_edges": 0, "nonmanifold_edges": 0,
           "boundary_loops": [], "hole_loops": 0, "boundary_ratio": 0.0, "textures": [], "vram_mb": 0.0,
           "materials": len(js.get("materials", [])), "bounds_min": None, "bounds_max": None}
    all_pos, all_idx, voff = [], [], 0
    for mi, m in enumerate(meshes):
        prims = m.get("primitives", [])
        good = 0
        for p in prims:
            if p.get("mode", 4) != 4:
                res["non_triangle_prims"] += 1
                continue
            if "POSITION" not in p.get("attributes", {}):
                continue
            pos = _accessor(js, binc, p["attributes"]["POSITION"]).astype(np.float32)
            if len(pos) == 0:
                continue
            idx = (_accessor(js, binc, p["indices"]).reshape(-1).astype(np.int64) if "indices" in p
                   else np.arange(len(pos), dtype=np.int64))
            if len(idx) < 3:
                continue
            good += 1
            if mi in used or not used:
                all_pos.append(pos)
                all_idx.append(idx[: len(idx) // 3 * 3] + voff)
                voff += len(pos)
        if not prims or good == 0:
            res["empty_meshes"].append(m.get("name", f"mesh{mi}"))
        if used and mi not in used:
            res["unreferenced_meshes"].append(m.get("name", f"mesh{mi}"))
    if all_pos:
        pos = np.concatenate(all_pos)
        tri = np.concatenate(all_idx).reshape(-1, 3)
        res["verts"], res["tris"] = int(len(pos)), int(len(tri))
        res["bounds_min"] = np.round(pos.min(0), 3).tolist()
        res["bounds_max"] = np.round(pos.max(0), 3).tolist()
        diag = float(np.linalg.norm(pos.max(0) - pos.min(0))) or 1.0
        a, b, c = pos[tri[:, 0]], pos[tri[:, 1]], pos[tri[:, 2]]
        area = 0.5 * np.linalg.norm(np.cross(b - a, c - a), axis=1)
        res["degenerate_tris"] = int((area < (diag * 1e-7) ** 2).sum())
        q = np.round(pos / (diag * 1e-5)).astype(np.int64)
        _, inv = np.unique(q, axis=0, return_inverse=True)
        inv = inv.reshape(-1)
        t = inv[tri]
        t = t[(t[:, 0] != t[:, 1]) & (t[:, 1] != t[:, 2]) & (t[:, 0] != t[:, 2])]
        e = np.concatenate([t[:, [0, 1]], t[:, [1, 2]], t[:, [2, 0]]])
        e.sort(axis=1)
        m_ = int(e.max()) + 1
        keys, counts = np.unique(e[:, 0] * m_ + e[:, 1], return_counts=True)
        bkeys = keys[counts == 1]
        res["boundary_edges"] = int(len(bkeys))
        res["boundary_ratio"] = round(len(bkeys) / max(1, len(keys)), 4)
        res["nonmanifold_edges"] = int((counts > 2).sum())
        if len(bkeys):
            loops = _components(np.stack([bkeys // m_, bkeys % m_], axis=1))
            res["boundary_loops"] = loops[:12]
            res["hole_loops"] = len(loops)
    for img in js.get("images", []):
        s = _image_size(js, binc, img)
        if s:
            res["textures"].append(list(s))
            res["vram_mb"] += s[0] * s[1] * 4 * 1.33 / 1e6
    res["vram_mb"] = round(res["vram_mb"], 1)
    res["max_texture_px"] = max((max(t) for t in res["textures"]), default=0)
    if cf:
        cache_dir.mkdir(parents=True, exist_ok=True)
        cf.write_text(json.dumps(res))
    return res


def summarise(r: dict) -> str:
    return (f"{r['file']}: {r['size_mb']} MB, {r['tris']:,} tris, {r['meshes']} meshes "
            f"(empty {len(r['empty_meshes'])}, unreferenced {len(r['unreferenced_meshes'])}), "
            f"hole loops {r['hole_loops']} (open edges {r['boundary_ratio']:.1%}), degenerate {r['degenerate_tris']}, "
            f"textures {r['textures']} (~{r['vram_mb']} MB VRAM)")
