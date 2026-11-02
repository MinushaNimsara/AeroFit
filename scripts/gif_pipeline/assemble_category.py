#!/usr/bin/env python3
"""Batch-assemble exercise GIFs for one catalog category.

Uses the same settings as assemble_one.py (512px, 220ms, pingpong, crossfade 2).
Skips exercises whose image file already exists on disk.
Does not bump app version or publish releases.

Usage:
  python scripts/gif_pipeline/assemble_category.py back
  python scripts/gif_pipeline/assemble_category.py back --force
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

# Allow `python scripts/gif_pipeline/assemble_category.py` without PYTHONPATH.
_SCRIPT_DIR = Path(__file__).resolve().parent
if str(_SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(_SCRIPT_DIR))

from assemble_one import ROOT, assemble  # noqa: E402


def image_dir_for_category(category: str) -> Path:
    if category == "athletic_performance":
        return ROOT / "assets/exercises/images/athletic"
    return ROOT / "assets/exercises/images" / category


def slug_from_image(path: str) -> str:
    return Path(path).stem


def main() -> None:
    parser = argparse.ArgumentParser(description="Batch assemble GIFs for a catalog category")
    parser.add_argument(
        "category",
        help="Catalog JSON basename / images folder (e.g. back, chest)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Rebuild even when the GIF/PNG already exists on disk",
    )
    args = parser.parse_args()
    category = args.category.strip()

    json_path = ROOT / "assets/data/exercises" / f"{category}.json"
    if not json_path.is_file():
        raise SystemExit(f"missing catalog: {json_path}")

    exercises = json.loads(json_path.read_text(encoding="utf-8"))
    if not isinstance(exercises, list):
        raise SystemExit(f"expected list in {json_path.name}")

    ok = 0
    skipped = 0
    failed = 0

    print(f"Batch assemble category={category} force={args.force}")
    for ex in exercises:
        eid = (ex.get("id") or "").strip()
        name = (ex.get("name") or "").strip()
        image = (ex.get("image") or "").strip()
        if not eid or not image:
            print(f"FAIL skip-bad-entry id={eid!r} name={name!r}")
            failed += 1
            continue

        slug = slug_from_image(image)
        existing = ROOT / Path(*image.split("/"))
        expected_gif = image_dir_for_category(category) / f"{slug}.gif"
        already = (
            existing
            if existing.is_file()
            else expected_gif
            if expected_gif.is_file()
            else None
        )

        if already is not None and not args.force:
            print(f"SKIP {eid} {name} (exists {already.relative_to(ROOT)})")
            skipped += 1
            continue

        try:
            out = assemble(slug, eid, category)
            size_kb = out.stat().st_size / 1024
            print(f"     size={size_kb:.1f} KB")
            ok += 1
        except Exception as e:  # noqa: BLE001 — continue batch
            print(f"FAIL {eid} {name} slug={slug}: {e}")
            failed += 1

    print("")
    print(f"Done category={category}: ok={ok} skipped={skipped} failed={failed}")
    if failed:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
