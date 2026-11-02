#!/usr/bin/env python3
"""QA exercise GIFs for a catalog category: identical files + low motion.

Usage:
  python scripts/gif_pipeline/qa_category_gifs.py back
  python scripts/gif_pipeline/qa_category_gifs.py back --min-motion 4
"""

from __future__ import annotations

import argparse
import hashlib
import json
import sys
from collections import defaultdict
from pathlib import Path

from PIL import Image, ImageChops, ImageStat

ROOT = Path(__file__).resolve().parents[2]

# Known content bugs that identical-hash alone may not catch after partial remakes.
KNOWN_BAD_CHECKS = {
    "inverted_row": "must be horizontal body row under a bar (heels down), NOT a vertical hang/pull-up",
    "face_pull_band": "must use a resistance BAND, NOT a cable stack/rope machine",
}


def md5_bytes(data: bytes) -> str:
    return hashlib.md5(data).hexdigest()


def md5_file(path: Path) -> str:
    return md5_bytes(path.read_bytes())


def frame_folder_hash(folder: Path) -> str | None:
    if not folder.is_dir():
        return None
    files = sorted(
        p
        for p in folder.iterdir()
        if p.is_file()
        and p.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}
        and not p.name.startswith("_")
    )
    if not files:
        return None
    h = hashlib.md5()
    for f in files:
        h.update(f.name.encode())
        h.update(f.read_bytes())
    return h.hexdigest()


def gif_motion(path: Path) -> tuple[int, float, float, float]:
    """Return (frame_count, mean_consecutive_diff, max_diff, first_last_diff)."""
    im = Image.open(path)
    frames: list[Image.Image] = []
    try:
        while True:
            frames.append(im.convert("RGB").copy())
            im.seek(im.tell() + 1)
    except EOFError:
        pass
    if len(frames) < 2:
        return len(frames), 0.0, 0.0, 0.0

    diffs: list[float] = []
    for a, b in zip(frames, frames[1:]):
        d = ImageChops.difference(a, b)
        diffs.append(sum(ImageStat.Stat(d).mean) / 3.0)
    fl = sum(ImageStat.Stat(ImageChops.difference(frames[0], frames[-1])).mean) / 3.0
    return len(frames), sum(diffs) / len(diffs), max(diffs), fl


def main() -> None:
    parser = argparse.ArgumentParser(description="QA GIFs for one exercise category")
    parser.add_argument("category", help="e.g. back, chest")
    parser.add_argument(
        "--min-motion",
        type=float,
        default=4.0,
        help="Fail stems with mean consecutive pixel diff below this (default 4)",
    )
    parser.add_argument(
        "--stems",
        nargs="*",
        default=None,
        help="If set, only score these stems for the motion floor (still report all identical pairs)",
    )
    args = parser.parse_args()
    category = args.category.strip()

    json_path = ROOT / "assets/data/exercises" / f"{category}.json"
    img_dir_name = "athletic" if category == "athletic_performance" else category
    img_dir = ROOT / "assets/exercises/images" / img_dir_name
    frames_root = ROOT / "scripts/gif_pipeline/frames"

    if not json_path.is_file():
        raise SystemExit(f"missing catalog {json_path}")

    exercises = json.loads(json_path.read_text(encoding="utf-8"))
    focus = set(args.stems) if args.stems else None
    by_gif: dict[str, list[str]] = defaultdict(list)
    by_frame: dict[str, list[str]] = defaultdict(list)
    motion_rows: list[tuple[str, float, float, float, int]] = []
    missing_gif: list[str] = []
    missing_out_of_scope = 0

    for ex in exercises:
        image = (ex.get("image") or "").strip()
        stem = Path(image).stem if image else ""
        if not stem:
            continue
        in_scope = focus is None or stem in focus
        gif = img_dir / f"{stem}.gif"
        if not gif.is_file():
            # fall back to catalog-relative path
            cand = ROOT / Path(*image.split("/"))
            gif = cand if cand.is_file() else gif
        if not gif.is_file():
            if in_scope:
                missing_gif.append(stem)
            else:
                missing_out_of_scope += 1
            continue
        if not in_scope:
            # Still allow full-category identical detection when unscoped;
            # when scoped, only hash in-scope GIFs.
            continue
        ghash = md5_file(gif)
        by_gif[ghash].append(stem)
        fhash = frame_folder_hash(frames_root / stem)
        if fhash:
            by_frame[fhash].append(stem)
        n, mean_d, max_d, fl = gif_motion(gif)
        motion_rows.append((stem, mean_d, max_d, fl, n))

    print(f"QA category={category}")
    print(
        f"  gifs_checked={len(motion_rows)} missing_in_scope={len(missing_gif)}"
        + (f" missing_elsewhere={missing_out_of_scope}" if focus is not None else "")
    )
    if missing_gif:
        print("  MISSING:", ", ".join(missing_gif[:20]))

    identical_gif = [v for v in by_gif.values() if len(v) > 1]
    identical_fr = [v for v in by_frame.values() if len(v) > 1]

    print("\n=== Identical GIF file groups ===")
    if not identical_gif:
        print("  (none)")
    for group in sorted(identical_gif, key=len, reverse=True):
        print(f"  {len(group)}: {', '.join(sorted(group))}")

    print("\n=== Identical frame-folder groups ===")
    if not identical_fr:
        print("  (none)")
    for group in sorted(identical_fr, key=len, reverse=True):
        print(f"  {len(group)}: {', '.join(sorted(group))}")

    print(f"\n=== Low motion (meanDiff < {args.min_motion}) ===")
    low = []
    for stem, mean_d, max_d, fl, n in sorted(motion_rows, key=lambda r: r[1]):
        if mean_d < args.min_motion:
            low.append(stem)
            print(f"  {stem}: mean={mean_d:.2f} max={max_d:.2f} firstLast={fl:.2f} n={n}")
    if not low:
        print("  (none in scope)")

    print("\n=== Known bad-content checklist (manual verify after remake) ===")
    for stem, note in KNOWN_BAD_CHECKS.items():
        present = any(s == stem for s, *_ in motion_rows)
        print(f"  [{'in set' if present else 'n/a'}] {stem}: {note}")

    # When --stems is set: fail on missing-in-scope, identical in-scope, or low motion.
    # Full-category run: fail on identical/missing; low motion is reported only.
    fail = bool(identical_gif) or bool(missing_gif)
    if focus is not None:
        fail = fail or bool(low)

    print("")
    if fail:
        print("FAIL — identical GIFs and/or missing / low-motion (scoped) remain.")
        raise SystemExit(1)
    print("PASS — no identical GIF groups; scoped motion OK (if --stems set).")
    raise SystemExit(0)


if __name__ == "__main__":
    main()
