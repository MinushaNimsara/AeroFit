#!/usr/bin/env python3
"""Assemble pose frames into GIF and patch catalog JSON image path.

Usage:
  python scripts/gif_pipeline/assemble_one.py <slug> <exercise_id> [category_folder]

category_folder defaults to chest. Example:
  python scripts/gif_pipeline/assemble_one.py pull_up back_006 back
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
PY = Path(sys.executable)
FRAMES_ROOT = ROOT / "scripts/gif_pipeline/frames"


def assemble(slug: str, exercise_id: str, category: str = "chest") -> Path:
    frames = FRAMES_ROOT / slug
    img_dir = ROOT / "assets/exercises/images" / category
    out = img_dir / f"{slug}.gif"
    json_path = ROOT / "assets/data/exercises" / f"{category}.json"

    # athletic_performance JSON folder uses athletic/ in image paths
    if category == "athletic_performance":
        img_dir = ROOT / "assets/exercises/images/athletic"
        out = img_dir / f"{slug}.gif"

    if not frames.is_dir():
        raise FileNotFoundError(f"missing frames dir {frames}")
    files = sorted(
        p
        for p in frames.iterdir()
        if p.suffix.lower() in {".jpg", ".jpeg", ".png"} and not p.name.startswith("_")
    )
    if len(files) < 2:
        raise ValueError(f"need >=2 frames in {frames}, got {len(files)}")

    img_dir.mkdir(parents=True, exist_ok=True)
    cmd = [
        str(PY),
        str(ROOT / "scripts/make_exercise_gif.py"),
        "--frames",
        str(frames),
        "--out",
        str(out),
        "--size",
        "512",
        "--duration",
        "220",
        "--pingpong",
        "--crossfade",
        "2",
    ]
    subprocess.check_call(cmd)

    if not json_path.is_file():
        raise FileNotFoundError(f"missing json: {json_path}")

    data = json.loads(json_path.read_text(encoding="utf-8"))
    rel = f"assets/exercises/images/{img_dir.name}/{slug}.gif"
    changed = False
    for e in data:
        if e.get("id") == exercise_id:
            e["image"] = rel
            changed = True
            break
    if not changed:
        raise KeyError(f"id not found: {exercise_id} in {json_path.name}")
    json_path.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"OK {exercise_id} -> {out}")
    return out


if __name__ == "__main__":
    if len(sys.argv) < 3:
        raise SystemExit("usage: assemble_one.py <slug> <exercise_id> [category]")
    slug = sys.argv[1]
    exercise_id = sys.argv[2]
    category = sys.argv[3] if len(sys.argv) > 3 else "chest"
    try:
        assemble(slug, exercise_id, category)
    except (FileNotFoundError, ValueError, KeyError, subprocess.CalledProcessError) as e:
        raise SystemExit(str(e)) from e
