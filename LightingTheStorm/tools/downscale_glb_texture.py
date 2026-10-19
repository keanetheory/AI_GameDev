"""Downscale the embedded textures of a .glb (FAL Hunyuan3D v3 ships 4096 PNGs) and keep the original.

  python tools/downscale_glb_texture.py Assets/Models/dock/dock_harbour.glb [--size 2048]

The original is moved to <model folder>/source/<name>_4k_texture.glb (that folder has a .gdignore so
Godot does not import it) and the .glb is rewritten in place with every image no larger than --size.
"""
import argparse
import io
import json
import shutil
import struct
from pathlib import Path

from PIL import Image


def read_glb(path: Path):
    data = path.read_bytes()
    magic, _version, _length = struct.unpack_from("<III", data, 0)
    if magic != 0x46546C67:
        raise SystemExit(f"{path} is not a .glb")
    off, js, binary = 12, None, b""
    while off < len(data):
        n, kind = struct.unpack_from("<II", data, off)
        chunk = data[off + 8: off + 8 + n]
        if kind == 0x4E4F534A:
            js = json.loads(chunk)
        elif kind == 0x004E4942:
            binary = chunk
        off += 8 + n
    return js, binary


def write_glb(path: Path, js: dict, binary: bytes) -> None:
    j = json.dumps(js, separators=(",", ":")).encode()
    j += b" " * (-len(j) % 4)
    binary += b"\0" * (-len(binary) % 4)
    total = 12 + 8 + len(j) + 8 + len(binary)
    path.write_bytes(struct.pack("<III", 0x46546C67, 2, total) + struct.pack("<II", len(j), 0x4E4F534A) + j
                     + struct.pack("<II", len(binary), 0x004E4942) + binary)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("glb")
    ap.add_argument("--size", type=int, default=2048)
    args = ap.parse_args()
    path = Path(args.glb).resolve()
    js, binary = read_glb(path)

    replaced = {}
    for img in js.get("images", []):
        if "bufferView" not in img:
            continue
        bv = js["bufferViews"][img["bufferView"]]
        raw = binary[bv.get("byteOffset", 0): bv.get("byteOffset", 0) + bv["byteLength"]]
        im = Image.open(io.BytesIO(raw))
        if max(im.size) <= args.size:
            continue
        before = im.size
        im.thumbnail((args.size, args.size), Image.LANCZOS)
        buf = io.BytesIO()
        im.save(buf, "PNG", optimize=True)
        img["mimeType"] = "image/png"
        replaced[img["bufferView"]] = buf.getvalue()
        print(f"image {img.get('name', img['bufferView'])}: {before} -> {im.size}, {len(raw) // 1024} KB -> {len(buf.getvalue()) // 1024} KB")
    if not replaced:
        print("nothing larger than", args.size)
        return

    # Re-lay the binary chunk with the new image bytes, keeping every other view's bytes unchanged.
    out = bytearray()
    for i, bv in enumerate(js["bufferViews"]):
        start = bv.get("byteOffset", 0)
        chunk = replaced.get(i, binary[start: start + bv["byteLength"]])
        out += b"\0" * (-len(out) % 4)
        bv["byteOffset"] = len(out)
        bv["byteLength"] = len(chunk)
        out += chunk
    js["buffers"][0]["byteLength"] = len(out)

    source = path.parent / "source"
    source.mkdir(exist_ok=True)
    (source / ".gdignore").touch()
    keep = source / f"{path.stem}_4k_texture.glb"
    shutil.copy2(path, keep)
    write_glb(path, js, bytes(out))
    print(f"original kept at {keep}\nwrote {path} ({path.stat().st_size // 1024} KB)")


if __name__ == "__main__":
    main()
