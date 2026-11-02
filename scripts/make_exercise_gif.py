#!/usr/bin/env python3
"""Assemble pose frames into a looping exercise demo GIF.

Usage:
  python scripts/make_exercise_gif.py ^
    --frames scripts/gif_pipeline/frames/decline_barbell_bench_press ^
    --out assets/exercises/images/chest/decline_barbell_bench_press.gif ^
    --size 512 --duration 220 --pingpong --crossfade 2
"""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".webp"}


def load_frames(folder: Path) -> list[Image.Image]:
    files = sorted(
        p
        for p in folder.iterdir()
        if p.is_file() and p.suffix.lower() in IMAGE_EXTS and not p.name.startswith("_")
    )
    if len(files) < 2:
        raise SystemExit(f"Need at least 2 frames in {folder}, found {len(files)}")

    frames: list[Image.Image] = []
    for path in files:
        img = Image.open(path).convert("RGB")
        frames.append(img)
        print(f"  + {path.name} ({img.size[0]}x{img.size[1]})")
    return frames


def normalize(frames: list[Image.Image], size: int) -> list[Image.Image]:
    out: list[Image.Image] = []
    for img in frames:
        # Fit into square canvas so all frames share identical dimensions.
        canvas = Image.new("RGB", (size, size), (255, 255, 255))
        ratio = min(size / img.width, size / img.height)
        new_w = max(1, int(img.width * ratio))
        new_h = max(1, int(img.height * ratio))
        resized = img.resize((new_w, new_h), Image.Resampling.LANCZOS)
        offset = ((size - new_w) // 2, (size - new_h) // 2)
        canvas.paste(resized, offset)
        out.append(canvas)
    return out


def insert_crossfades(frames: list[Image.Image], steps: int) -> list[Image.Image]:
    """Insert blended intermediates between consecutive pose frames."""
    if steps <= 0 or len(frames) < 2:
        return frames

    out: list[Image.Image] = []
    for i, current in enumerate(frames):
        out.append(current)
        if i >= len(frames) - 1:
            break
        nxt = frames[i + 1]
        for step in range(1, steps + 1):
            alpha = step / (steps + 1)
            out.append(Image.blend(current, nxt, alpha))
    return out


def main() -> None:
    parser = argparse.ArgumentParser(description="Build looping exercise GIF from pose frames")
    parser.add_argument("--frames", required=True, type=Path, help="Folder of ordered pose images")
    parser.add_argument("--out", required=True, type=Path, help="Output .gif path")
    parser.add_argument("--size", type=int, default=512, help="Square output size (px)")
    parser.add_argument("--duration", type=int, default=300, help="Frame duration ms")
    parser.add_argument(
        "--pingpong",
        action="store_true",
        help="Append reversed middle frames for smoother loop (1..n-2 reversed)",
    )
    parser.add_argument(
        "--crossfade",
        type=int,
        default=0,
        metavar="N",
        help="Insert N blended frames between each pose pair (default 0)",
    )
    args = parser.parse_args()

    if not args.frames.is_dir():
        raise SystemExit(f"Frames folder not found: {args.frames}")
    if args.crossfade < 0:
        raise SystemExit("--crossfade must be >= 0")

    print(f"Loading frames from {args.frames}")
    frames = normalize(load_frames(args.frames), args.size)

    if args.pingpong and len(frames) >= 3:
        frames = frames + list(reversed(frames[1:-1]))
        print(f"Ping-pong expanded to {len(frames)} frames")

    if args.crossfade > 0:
        before = len(frames)
        frames = insert_crossfades(frames, args.crossfade)
        print(f"Crossfade x{args.crossfade}: {before} -> {len(frames)} frames")

    args.out.parent.mkdir(parents=True, exist_ok=True)
    frames[0].save(
        args.out,
        save_all=True,
        append_images=frames[1:],
        duration=args.duration,
        loop=0,
        optimize=False,
    )
    size_kb = args.out.stat().st_size / 1024
    print(f"Wrote {args.out} ({size_kb:.1f} KB, {len(frames)} frames, {args.duration}ms)")


if __name__ == "__main__":
    main()
