#!/usr/bin/env python3
"""Install Cursor/Gemini-generated pose stills into gif_pipeline frames and assemble.

Looks for files named <stem>_01_start.(jpg|png) and <stem>_02_end.(jpg|png)
or batch-prefixed 3.<stem>_01_start / 3.<stem>_02_end (also 1./2.)
in a source directory (default: Cursor project assets folder or --src).

Usage:
  python scripts/gif_pipeline/install_generated_frames.py --preset back-fix --assemble
  python scripts/gif_pipeline/install_generated_frames.py --preset back-batch3 --assemble
"""

from __future__ import annotations

import argparse
import shutil
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES_ROOT = ROOT / "scripts/gif_pipeline/frames"
BACKUP_ROOT = FRAMES_ROOT / "_backup"

# stem -> catalog exercise id
BACK_FIX = {
    # Batch 1 (back_001–back_010)
    "conventional_barbell_deadlift": "back_001",
    "sumo_deadlift": "back_002",
    "barbell_romanian_deadlift": "back_003",
    "dumbbell_romanian_deadlift": "back_004",
    "rack_pull": "back_005",
    "pull_up": "back_006",
    "chin_up": "back_007",
    "wide_grip_pull_up": "back_008",
    "neutral_grip_pull_up": "back_009",
    "assisted_pull_up_machine": "back_010",
    # Batch 2 (back_011–back_020)
    "lat_pulldown_wide_grip": "back_011",
    "lat_pulldown_close_grip": "back_012",
    "lat_pulldown_reverse_grip": "back_013",
    "single_arm_lat_pulldown": "back_014",
    "straight_arm_pulldown": "back_015",
    "barbell_bent_over_row": "back_016",
    "pendlay_row": "back_017",
    "t_bar_row": "back_018",
    "chest_supported_row_machine": "back_019",
    "seated_cable_row_wide_grip": "back_020",
    # Batch 3 (back_021–back_030)
    "seated_cable_row_close_grip": "back_021",
    "single_arm_seated_cable_row": "back_022",
    "single_arm_dumbbell_row": "back_023",
    "two_arm_dumbbell_row": "back_024",
    "kroc_row": "back_025",
    "meadows_row": "back_026",
    "inverted_row": "back_027",
    "renegade_row": "back_028",
    "cable_face_pull": "back_029",
    "face_pull_band": "back_030",
    # Later batches / earlier remake set (kept for tooling)
    "cable_pullover": "back_044",
    "landmine_row": "back_042",
    "single_arm_landmine_row": "back_043",
    "back_extension": "back_038",
    "weighted_back_extension": "back_039",
    "barbell_shrug": "back_033",
    "dumbbell_shrug": "back_034",
    "trap_bar_shrug": "back_035",
}

BACK_BATCH1 = [
    "conventional_barbell_deadlift",
    "sumo_deadlift",
    "barbell_romanian_deadlift",
    "dumbbell_romanian_deadlift",
    "rack_pull",
    "pull_up",
    "chin_up",
    "wide_grip_pull_up",
    "neutral_grip_pull_up",
    "assisted_pull_up_machine",
]

# Batch 2 (back_011–back_020)
BACK_BATCH2 = [
    "lat_pulldown_wide_grip",
    "lat_pulldown_close_grip",
    "lat_pulldown_reverse_grip",
    "single_arm_lat_pulldown",
    "straight_arm_pulldown",
    "barbell_bent_over_row",
    "pendlay_row",
    "t_bar_row",
    "chest_supported_row_machine",
    "seated_cable_row_wide_grip",
]

# Batch 3 (back_021–back_030)
BACK_BATCH3 = [
    "seated_cable_row_close_grip",
    "single_arm_seated_cable_row",
    "single_arm_dumbbell_row",
    "two_arm_dumbbell_row",
    "kroc_row",
    "meadows_row",
    "inverted_row",
    "renegade_row",
    "cable_face_pull",
    "face_pull_band",
]

DEFAULT_SRC_CANDIDATES = [
    Path(r"C:\Users\minuwaa\.cursor\projects\d-Users-p-Desktop-quantumexe-project-aerofit\assets"),
    ROOT / "assets" / "_generated_frames",
]


def find_pair(src: Path, stem: str) -> tuple[Path, Path] | None:
    # Prefer batch-prefixed names (3.stem, 2.stem, 1.stem) over bare stem.
    name_prefixes = (f"3.{stem}", f"2.{stem}", f"1.{stem}", stem)
    for prefix in name_prefixes:
        start = end = None
        for ext in (".jpg", ".jpeg", ".png", ".webp"):
            s = src / f"{prefix}_01_start{ext}"
            e = src / f"{prefix}_02_end{ext}"
            if s.is_file():
                start = s
            if e.is_file():
                end = e
        if start and end:
            return start, end
    return None


def install_stem(src_start: Path, src_end: Path, stem: str) -> None:
    dest = FRAMES_ROOT / stem
    bak = BACKUP_ROOT / stem
    if dest.is_dir() and any(dest.iterdir()):
        if bak.exists():
            shutil.rmtree(bak)
        bak.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(dest, bak)
    dest.mkdir(parents=True, exist_ok=True)
    for old in list(dest.iterdir()):
        if old.is_file():
            old.unlink()
    for src, name in ((src_start, "01_start.jpg"), (src_end, "02_end.jpg")):
        img = Image.open(src).convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
        img.save(dest / name, format="JPEG", quality=92)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--src", type=Path, default=None)
    parser.add_argument(
        "--preset",
        choices=["back-fix", "back-batch1", "back-batch2", "back-batch3"],
        default=None,
    )
    parser.add_argument("--assemble", action="store_true")
    parser.add_argument("--stems", nargs="*", default=None)
    args = parser.parse_args()

    src = args.src
    if src is None:
        src = next((p for p in DEFAULT_SRC_CANDIDATES if p.is_dir()), None)
    if src is None or not src.is_dir():
        raise SystemExit("No --src directory with generated frames")

    if args.stems:
        stems = list(args.stems)
    elif args.preset == "back-batch1":
        stems = list(BACK_BATCH1)
    elif args.preset == "back-batch2":
        stems = list(BACK_BATCH2)
    elif args.preset == "back-batch3":
        stems = list(BACK_BATCH3)
    elif args.preset == "back-fix":
        stems = list(BACK_FIX.keys())
    else:
        raise SystemExit("Pass --preset back-batch1|back-batch2|back-batch3|back-fix or --stems ...")
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from assemble_one import assemble

    ok = fail = skip = 0
    for stem in stems:
        pair = find_pair(src, stem)
        if not pair:
            print(f"SKIP missing pair for {stem}")
            skip += 1
            continue
        try:
            install_stem(pair[0], pair[1], stem)
            print(f"OK frames {stem}")
            if args.assemble:
                assemble(stem, BACK_FIX[stem], "back")
            ok += 1
        except Exception as e:  # noqa: BLE001
            print(f"FAIL {stem}: {e}")
            fail += 1

    print(f"\nDone ok={ok} skip={skip} fail={fail}")
    if fail:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
