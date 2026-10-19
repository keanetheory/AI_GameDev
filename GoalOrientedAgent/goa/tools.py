"""Sandboxed tools the model can call.

Read tools work anywhere under the project root (minus .git, .godot, .env). Write tools only work
inside config.WRITE_ALLOWED, back up every file before the first change (so a task can be undone),
and run_command always asks the human first.
"""
import base64
import io
import json
import re
import shutil
import subprocess
from pathlib import Path

from . import config

SKIP_DIRS = {".git", ".godot", "__pycache__", "node_modules", "backups"}
SKIP_SUFFIXES = {".import", ".uid"}
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}
BINARY_SUFFIXES = IMAGE_SUFFIXES | {".glb", ".gltf", ".wav", ".ogg", ".mp3", ".pdf", ".res", ".scn", ".ttf", ".otf", ".zip"}
MAX_OUT = 30000
DENY_COMMANDS = ("git push", "git reset --hard", "git checkout --", "rm -rf", "del /s", "rmdir /s", "format ", "shutdown")


class ToolError(Exception):
    pass


def _t(name, description, props, required):
    return {"name": name, "description": description,
            "input_schema": {"type": "object", "properties": props, "required": required}}


READ_TOOL_SCHEMAS = [
    _t("list_dir", "List files and folders under a path (relative to the project root AI_GameDev). Skips .godot, .import and .uid noise.",
       {"path": {"type": "string"}, "depth": {"type": "integer", "description": "1-4, default 1"}}, ["path"]),
    _t("read_file", "Read a text file with line numbers. Use start_line/end_line for big files (default first 400 lines).",
       {"path": {"type": "string"}, "start_line": {"type": "integer"}, "end_line": {"type": "integer"}}, ["path"]),
    _t("grep", "Regex search over text files. Returns path:line:text. Use glob like '*.gd' to narrow.",
       {"pattern": {"type": "string"}, "path": {"type": "string", "description": "folder or file, default '.'"},
        "glob": {"type": "string"}}, ["pattern"]),
    _t("view_image", "Look at an image (concept art, screenshot). It is downscaled to 1024px.",
       {"path": {"type": "string"}}, ["path"]),
]

WRITE_TOOL_SCHEMAS = [
    _t("write_file", "Create or fully replace a text file. Only allowed under LightingTheStorm/, Docs/ and AIAgentCrew/.",
       {"path": {"type": "string"}, "content": {"type": "string"}}, ["path", "content"]),
    _t("edit_file", "Replace one exact, unique occurrence of old_string with new_string in an existing file.",
       {"path": {"type": "string"}, "old_string": {"type": "string"}, "new_string": {"type": "string"}},
       ["path", "old_string", "new_string"]),
    _t("run_command", "Run a shell command from the project root (for example a Godot headless test or a python tool). "
                      "The human is asked to approve every command. 120 s timeout.",
       {"command": {"type": "string"}, "why": {"type": "string"}}, ["command", "why"]),
]


class Sandbox:
    def __init__(self, writable=False, task_id=None, confirm=None):
        self.root = config.ROOT
        self.writable = writable
        self.task_id = task_id
        self.confirm = confirm or (lambda cmd, why: False)
        self.backup_dir = config.BACKUP_DIR / (task_id or "_none")
        self.manifest = {}                       # relpath -> "modified" | "created"
        self.commands = []                       # (command, exit_code)

    # ---- path handling -------------------------------------------------------------------
    def resolve(self, path: str) -> Path:
        clean = path.strip().strip('"').replace("\\", "/")
        p = (self.root / clean).resolve()
        if not p.exists() and not self.writable_target(clean) and (self.root / "LightingTheStorm" / clean).exists():
            p = (self.root / "LightingTheStorm" / clean).resolve()   # models often drop the game folder prefix
        try:
            rel = p.relative_to(self.root)
        except ValueError:
            raise ToolError(f"'{path}' is outside the project root.")
        if set(rel.parts) & config.READ_BLOCKED_PARTS or p.name in config.READ_BLOCKED_NAMES:
            raise ToolError(f"'{path}' is not accessible.")
        return p

    def writable_target(self, clean):
        return clean.split("/")[0] in ("LightingTheStorm", "Docs", "AIAgentCrew", "ConceptArt", "GoalOrientedAgent")

    def rel(self, p: Path) -> str:
        return p.relative_to(self.root).as_posix()

    def _check_writable(self, p: Path):
        if not self.writable:
            raise ToolError("This phase is read-only.")
        top = p.relative_to(self.root).parts[0]
        if top not in config.WRITE_ALLOWED:
            raise ToolError(f"Writes are only allowed under {', '.join(config.WRITE_ALLOWED)}.")

    def _backup(self, p: Path):
        rel = self.rel(p)
        if rel in self.manifest:
            return
        if p.exists():
            dest = self.backup_dir / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(p, dest)
            self.manifest[rel] = "modified"
        else:
            self.manifest[rel] = "created"
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        (self.backup_dir / "manifest.json").write_text(json.dumps(self.manifest, indent=2), encoding="utf-8")

    # ---- tools ----------------------------------------------------------------------------
    def list_dir(self, path, depth=1):
        base = self.resolve(path)
        if not base.is_dir():
            raise ToolError(f"'{path}' is not a folder.")
        depth = max(1, min(int(depth or 1), 4))
        lines = []

        def walk(d: Path, level: int):
            for child in sorted(d.iterdir(), key=lambda c: (c.is_file(), c.name.lower())):
                if child.name in SKIP_DIRS or child.suffix in SKIP_SUFFIXES:
                    continue
                pad = "  " * level
                if child.is_dir():
                    lines.append(f"{pad}{child.name}/")
                    if level + 1 < depth:
                        walk(child, level + 1)
                else:
                    lines.append(f"{pad}{child.name}  ({child.stat().st_size:,} B)")
                if len(lines) > 400:
                    lines.append("... truncated")
                    return
        walk(base, 0)
        return "\n".join(lines) or "(empty)"

    def read_file(self, path, start_line=1, end_line=None):
        p = self.resolve(path)
        if not p.is_file():
            raise ToolError(f"'{path}' is not a file.")
        if p.suffix.lower() in IMAGE_SUFFIXES:
            raise ToolError("That is an image. Use view_image.")
        if p.suffix.lower() in BINARY_SUFFIXES:
            raise ToolError("Binary file; cannot be read as text.")
        text = p.read_text(encoding="utf-8", errors="replace").splitlines()
        start = max(1, int(start_line or 1))
        end = int(end_line) if end_line else min(len(text), start + 399)
        out = "\n".join(f"{i}\t{text[i - 1]}" for i in range(start, min(end, len(text)) + 1))
        head = f"[{self.rel(p)}: lines {start}-{min(end, len(text))} of {len(text)}]\n"
        return _clip(head + out)

    def grep(self, pattern, path=".", glob=None):
        base = self.resolve(path)
        try:
            rx = re.compile(pattern, re.IGNORECASE)
        except re.error as e:
            raise ToolError(f"Bad regex: {e}")
        files = [base] if base.is_file() else sorted(base.rglob(glob or "*"))
        hits = []
        for f in files:
            if not f.is_file() or f.suffix.lower() in BINARY_SUFFIXES or f.suffix in SKIP_SUFFIXES:
                continue
            if set(f.relative_to(self.root).parts) & (SKIP_DIRS | config.READ_BLOCKED_PARTS) or f.name in config.READ_BLOCKED_NAMES:
                continue
            try:
                if f.stat().st_size > 1_500_000:
                    continue
                for n, line in enumerate(f.read_text(encoding="utf-8", errors="ignore").splitlines(), 1):
                    if rx.search(line):
                        hits.append(f"{self.rel(f)}:{n}:{line.strip()[:200]}")
                        if len(hits) >= 80:
                            return "\n".join(hits) + "\n... more matches truncated"
            except OSError:
                continue
        return "\n".join(hits) or "(no matches)"

    def view_image(self, path):
        from PIL import Image
        p = self.resolve(path)
        if p.suffix.lower() not in IMAGE_SUFFIXES or not p.is_file():
            raise ToolError("Not an image file.")
        return image_block(p, 1024)

    def write_file(self, path, content):
        p = self.resolve(path)
        self._check_writable(p)
        self._backup(p)
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8", newline="\n")
        return f"Wrote {self.rel(p)} ({len(content):,} chars)."

    def edit_file(self, path, old_string, new_string):
        p = self.resolve(path)
        self._check_writable(p)
        if not p.is_file():
            raise ToolError(f"'{path}' does not exist; use write_file to create it.")
        text = p.read_text(encoding="utf-8")
        n = text.count(old_string)
        if n != 1:
            raise ToolError(f"old_string matched {n} times; it must match exactly once. Include more surrounding context.")
        self._backup(p)
        p.write_text(text.replace(old_string, new_string), encoding="utf-8", newline="\n")
        return f"Edited {self.rel(p)}."

    def run_command(self, command, why=""):
        if not self.writable:
            raise ToolError("This phase is read-only.")
        low = command.lower()
        if any(d in low for d in DENY_COMMANDS):
            raise ToolError("That command is on the deny list.")
        if not self.confirm(command, why):
            raise ToolError("The human declined to run that command.")
        r = subprocess.run(command, shell=True, cwd=self.root, capture_output=True, text=True,
                           encoding="utf-8", errors="replace", timeout=120)
        self.commands.append((command, r.returncode))
        return _clip(f"exit code {r.returncode}\n--- stdout ---\n{r.stdout}\n--- stderr ---\n{r.stderr}")

    # ---- dispatch ---------------------------------------------------------------------------
    def call(self, name, args):
        fn = getattr(self, name, None)
        if name not in {s["name"] for s in READ_TOOL_SCHEMAS + WRITE_TOOL_SCHEMAS} or fn is None:
            raise ToolError(f"Unknown tool '{name}'.")
        return fn(**args)

    def undo(self):
        """Restore every file this sandbox touched. Returns the list of restored relpaths."""
        done = []
        for rel, kind in self.manifest.items():
            target = self.root / rel
            if kind == "created":
                target.unlink(missing_ok=True)
            else:
                shutil.copy2(self.backup_dir / rel, target)
            done.append(f"{kind}: {rel}")
        return done


def undo_from_disk(task_id):
    """Undo a past task from its on-disk manifest (used if the session was restarted)."""
    sb = Sandbox(writable=True, task_id=task_id)
    mf = sb.backup_dir / "manifest.json"
    if not mf.exists():
        return []
    sb.manifest = json.loads(mf.read_text(encoding="utf-8"))
    return sb.undo()


def image_block(p: Path, max_px=1024, quality=80):
    from PIL import Image
    img = Image.open(p).convert("RGB")
    img.thumbnail((max_px, max_px))
    buf = io.BytesIO()
    img.save(buf, "JPEG", quality=quality)
    return {"type": "image", "source": {"type": "base64", "media_type": "image/jpeg",
                                        "data": base64.b64encode(buf.getvalue()).decode()}}


def _clip(s: str) -> str:
    return s if len(s) <= MAX_OUT else s[:MAX_OUT] + f"\n... [truncated {len(s) - MAX_OUT:,} chars]"
