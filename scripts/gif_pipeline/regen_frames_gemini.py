#!/usr/bin/env python3
"""Regenerate unique start/end pose frames via Gemini Image, then optional assemble.

Reads GEMINI_API_KEY from secrets/dart_defines.json (or env).
Backs up existing frames to scripts/gif_pipeline/frames/_backup/<stem>/.

If Gemini image quota is exhausted, generate pairs with Cursor GenerateImage
named <stem>_01_start / <stem>_02_end, then run install_generated_frames.py.

Usage:
  python scripts/gif_pipeline/regen_frames_gemini.py --stems inverted_row face_pull_band
  python scripts/gif_pipeline/regen_frames_gemini.py --preset back-fix --assemble
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import sys
import time
from io import BytesIO
from pathlib import Path

from google import genai
from google.genai import types
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
FRAMES_ROOT = ROOT / "scripts/gif_pipeline/frames"
BACKUP_ROOT = FRAMES_ROOT / "_backup"
DEFAULT_MODEL = "gemini-2.5-flash-image"

STYLE = (
    "Fitness anatomical illustration style: clean white background, "
    "grayscale muscular male figure with realistic muscle definition, "
    "primary working muscles highlighted in solid bright red, "
    "black athletic shorts, no text, no watermark, no logo, "
    "square composition, clear readable equipment."
)

# stem -> (exercise_id, start_brief, end_brief)
BRIEFS: dict[str, tuple[str, str, str]] = {
    "conventional_barbell_deadlift": (
        "back_001",
        "START of conventional barbell deadlift: bar on the floor over mid-foot, "
        "athlete hinged at hips with flat back, arms straight gripping the bar, "
        "plates touching the ground. NOT a Romanian deadlift — bar starts on floor.",
        "END/LOCKOUT of conventional barbell deadlift: standing tall, hips fully "
        "extended, barbell held at thighs, shoulders back. Same athlete and bar.",
    ),
    "barbell_romanian_deadlift": (
        "back_003",
        "START of barbell Romanian deadlift: standing tall holding barbell at thighs, "
        "soft knees. Distinct from conventional deadlift — bar never rests on floor.",
        "END/BOTTOM of barbell Romanian deadlift: hips pushed back, torso hinged "
        "forward ~45-70°, bar sliding down thighs toward mid-shin, flat back, "
        "plates OFF the floor. Soft knees, not a squat.",
    ),
    "straight_arm_pulldown": (
        "back_015",
        "START of straight-arm cable pulldown: standing facing high cable with "
        "straight bar or rope, arms extended overhead/forward holding the bar, "
        "slight hip hinge. NOT a pullover on a bench.",
        "END of straight-arm cable pulldown: arms still nearly straight, bar pulled "
        "down to thighs/hips, lats contracted, same cable machine.",
    ),
    "cable_pullover": (
        "back_044",
        "START of cable pullover (standing or kneeling at high cable with rope): "
        "arms extended forward/up holding rope, stretch through lats. "
        "Must show CABLE MACHINE + rope — not a straight-arm pulldown bar path twin.",
        "END of cable pullover: elbows soft, rope pulled down toward hips/waist, "
        "lats squeezed, same cable setup.",
    ),
    "t_bar_row": (
        "back_018",
        "START of T-bar row: chest over a landmine/T-bar platform, V-handle under "
        "loaded barbell sleeve, arms hanging long. Distinct chest-supported or "
        "hinged T-bar machine look — NOT a single-landmine V-handle landmine row clone.",
        "END of T-bar row: elbows pulled back, handle to chest/upper abs, "
        "upper back contracted, same T-bar setup.",
    ),
    "landmine_row": (
        "back_042",
        "START of landmine row: one end of barbell in floor landmine pivot, "
        "athlete hinged holding the weighted end with both hands on a V-handle "
        "or sleeve, arms extended. Emphasize single landmine pivot on floor.",
        "END of landmine row: pulling the loaded end to torso, elbows back, "
        "same landmine pivot clearly visible.",
    ),
    "single_arm_dumbbell_row": (
        "back_023",
        "START of single-arm dumbbell row: one knee and hand on flat bench, "
        "other foot on floor, dumbbell hanging in free hand, arm long. Classic 3-point stance.",
        "END of single-arm dumbbell row: dumbbell pulled to hip/pocket, elbow high, "
        "same bench setup — NOT a standing heavy Kroc row.",
    ),
    "kroc_row": (
        "back_025",
        "START of Kroc row: standing staggered stance, one hand braced on sturdy "
        "bench/rack, VERY HEAVY dumbbell hanging, torso hinged. Distinct from "
        "knee-on-bench single-arm row — standing brace, bigger ROM look.",
        "END of Kroc row: heavy dumbbell yanked high to ribs with momentum allowed, "
        "same standing braced setup.",
    ),
    "meadows_row": (
        "back_026",
        "START of Meadows row: visible landmine floor pivot, barbell diagonal, "
        "athlete PERPENDICULAR/side-on to bar (not facing the plates head-on), "
        "staggered stance, free forearm braced on front thigh, RIGHT hand OVERHAND "
        "wrapped directly around the fat bare metal barbell SLEEVE/collar itself "
        "(John Meadows grip) — NO D-handle, NO T-handle, NO perpendicular attachment, "
        "NO strap, fingers on cylindrical sleeve tip only. RIGHT arm fully straight "
        "hanging, sleeve near floor. NOT dumbbell row, NOT V-handle landmine, "
        "NOT photo clothing — anatomical only.",
        "END of Meadows row: SAME athlete/side/camera/landmine as start — RIGHT hand "
        "still gripping bare sleeve (NO D-handle), RIGHT elbow flared high outward "
        "pulling sleeve to hip, LEFT forearm still on thigh, working lat bright red. "
        "Do not switch working arm.",
    ),
    "single_arm_landmine_row": (
        "back_043",
        "START of single-arm landmine row: facing the landmine, one hand on barbell "
        "sleeve, staggered stance, arm extended toward pivot. Different camera/angle "
        "from Meadows (not side-on perpendicular).",
        "END of single-arm landmine row: pulling sleeve to waist, same facing-landmine setup.",
    ),
    "cable_face_pull": (
        "back_029",
        "START of cable face pull: facing cable crossover, rope on HIGH pulley, "
        "arms extended forward holding rope ends, weight stack visible.",
        "END of cable face pull: pulling rope to face/ears, elbows high and wide, "
        "external rotation, same cable stack + rope.",
    ),
    "face_pull_band": (
        "back_030",
        "START of BAND face pull: athlete holding a long LOOP RESISTANCE BAND "
        "anchored at head height to a rack/pole — NO cable machine, NO weight stack, "
        "NO metal pulley. Arms extended holding band.",
        "END of BAND face pull: pulling band to face, elbows high, same band anchor "
        "clearly visible — still no cable stack.",
    ),
    "back_extension": (
        "back_038",
        "START/BOTTOM of 45° back extension (hyperextension bench): hips on pad, "
        "heels under rollers, torso folded down toward floor, arms crossed or hanging. "
        "NO weight plate in hands.",
        "END/TOP of 45° back extension: torso raised to straight line with legs, "
        "neutral spine, empty hands — unweighted.",
    ),
    "weighted_back_extension": (
        "back_039",
        "START/BOTTOM of WEIGHTED 45° back extension: same hyperextension bench, "
        "torso folded down, athlete hugging a visible weight PLATE or dumbbell to chest.",
        "END/TOP of weighted back extension: torso extended in line with legs, "
        "still holding the plate/dumbbell clearly against chest.",
    ),
    "inverted_row": (
        "back_027",
        "START of inverted row (bodyweight row): athlete under a barbell set on a squat "
        "rack at about waist height, BODY HORIZONTAL / diagonal with HEELS on floor, "
        "arms straight holding bar overhand, chest under bar. "
        "CRITICAL: NOT a hanging pull-up, feet must stay on the ground.",
        "END of inverted row: pulling chest up to the bar, body still roughly horizontal, "
        "heels on floor, elbows bent — still NOT a vertical hang.",
    ),
    "barbell_shrug": (
        "back_033",
        "START of barbell shrug: standing holding barbell at thighs, shoulders depressed, "
        "arms straight. Clear before-shrug posture.",
        "END of barbell shrug: shoulders elevated strongly toward ears, traps peaked, "
        "arms still straight, same barbell — exaggerate the shrug travel.",
    ),
    "dumbbell_shrug": (
        "back_034",
        "START of dumbbell shrug: standing with dumbbells at sides, shoulders down.",
        "END of dumbbell shrug: shoulders shrugged high to ears, dumbbells still at sides, "
        "big visible trap elevation — exaggerate ROM vs start.",
    ),
    "trap_bar_shrug": (
        "back_035",
        "START of trap-bar shrug: standing inside hex/trap bar, hands on side handles, "
        "shoulders down. Trap bar clearly hexagonal.",
        "END of trap-bar shrug: shoulders shrugged up hard, same hex bar, big trap lift.",
    ),
    "chin_up": (
        "back_007",
        "START/BOTTOM of chin-up: hanging from pull-up bar with UNDERHAND (supinated) "
        "shoulder-width grip, arms fully extended, body vertical.",
        "END/TOP of chin-up: chin clearly above the bar, underhand grip still visible, "
        "elbows down — large ROM vs the hang. Must look different from start.",
    ),
    "chest_supported_row_machine": (
        "back_019",
        "START of seated chest-supported row MACHINE: chest on thick pad, seated, "
        "arms nearly straight reaching forward holding TWO separate short vertical "
        "handles. CRITICAL grip: fists wrap MID black foam of each handle, top caps "
        "clearly ABOVE the hands — never palms on top caps. CRITICAL feet: both "
        "sneakers full-sole flat on one diamond-plate platform, heels down, knees ~90°. "
        "Lats lightly red. White background anatomical style.",
        "END of seated chest-supported row MACHINE: same machine/athlete/camera, "
        "elbows pulled high behind torso, handles at lower ribs, scapulae squeezed, "
        "SAME mid-foam wrap grip (not top caps), SAME flat heels-down feet on platform, "
        "lats bright red. Large visible ROM vs start.",
    ),
}

BACK_FIX_PRESET = list(BRIEFS.keys())


def load_api_key() -> str:
    env = os.environ.get("GEMINI_API_KEY", "").strip()
    if env:
        return env
    path = ROOT / "secrets" / "dart_defines.json"
    if path.is_file():
        data = json.loads(path.read_text(encoding="utf-8"))
        key = str(data.get("GEMINI_API_KEY") or "").strip()
        if key and key != "PASTE_YOUR_GEMINI_KEY_HERE":
            return key
    raise SystemExit("GEMINI_API_KEY missing (env or secrets/dart_defines.json)")


def load_model_name() -> str:
    env = os.environ.get("GEMINI_IMAGE_MODEL", "").strip()
    if env:
        return env
    path = ROOT / "secrets" / "dart_defines.json"
    if path.is_file():
        data = json.loads(path.read_text(encoding="utf-8"))
        # Prefer dedicated image model; ignore text-only flash aliases.
        m = str(data.get("GEMINI_IMAGE_MODEL") or "").strip()
        if m:
            return m
    return DEFAULT_MODEL


def backup_frames(stem: str) -> None:
    src = FRAMES_ROOT / stem
    if not src.is_dir():
        return
    dest = BACKUP_ROOT / stem
    if dest.exists():
        shutil.rmtree(dest)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(src, dest)
    print(f"  backup -> {dest.relative_to(ROOT)}")


def extract_image(response) -> Image.Image:
    parts = []
    if getattr(response, "parts", None):
        parts = response.parts
    elif response.candidates:
        parts = response.candidates[0].content.parts or []
    for part in parts:
        inline = getattr(part, "inline_data", None)
        if inline is not None and getattr(inline, "data", None):
            return Image.open(BytesIO(inline.data)).convert("RGB")
    raise RuntimeError("No image in Gemini response")


def generate_pose(client: genai.Client, model: str, stem: str, phase: str, brief: str) -> Image.Image:
    prompt = (
        f"{STYLE}\n\n"
        f"Create ONE still frame for exercise slug '{stem}', phase={phase}.\n"
        f"{brief}\n"
        "Do not draw any other exercise. Do not include captions or arrows."
    )
    response = client.models.generate_content(
        model=model,
        contents=prompt,
        config=types.GenerateContentConfig(
            response_modalities=["TEXT", "IMAGE"],
        ),
    )
    return extract_image(response)


def write_frame_pair(stem: str, start_img: Image.Image, end_img: Image.Image) -> tuple[Path, Path]:
    out_dir = FRAMES_ROOT / stem
    out_dir.mkdir(parents=True, exist_ok=True)
    for old in list(out_dir.iterdir()):
        if old.is_file() and old.suffix.lower() in {".jpg", ".jpeg", ".png", ".webp"}:
            old.unlink()
    p1 = out_dir / "01_start.jpg"
    p2 = out_dir / "02_end.jpg"
    start_img.resize((1024, 1024), Image.Resampling.LANCZOS).save(
        p1, format="JPEG", quality=92
    )
    end_img.resize((1024, 1024), Image.Resampling.LANCZOS).save(
        p2, format="JPEG", quality=92
    )
    return p1, p2


def assemble_stem(stem: str, exercise_id: str) -> None:
    sys.path.insert(0, str(Path(__file__).resolve().parent))
    from assemble_one import assemble  # local import

    assemble(stem, exercise_id, "back")


def main() -> None:
    parser = argparse.ArgumentParser(description="Regenerate pose frames with Gemini Image")
    parser.add_argument("--stems", nargs="*", default=None, help="Specific stems to remake")
    parser.add_argument(
        "--preset",
        choices=["back-fix"],
        default=None,
        help="back-fix = clone pairs + inverted_row + low-motion shrugs/chin_up",
    )
    parser.add_argument("--assemble", action="store_true", help="Rebuild GIFs after frames")
    parser.add_argument("--sleep", type=float, default=1.5, help="Pause between API calls")
    parser.add_argument("--model", default=None, help="Override image model id")
    args = parser.parse_args()

    if args.preset == "back-fix":
        stems = list(BACK_FIX_PRESET)
    elif args.stems:
        stems = list(args.stems)
    else:
        raise SystemExit("Pass --preset back-fix or --stems ...")

    unknown = [s for s in stems if s not in BRIEFS]
    if unknown:
        raise SystemExit(f"No briefs for: {unknown}")

    api_key = load_api_key()
    model = args.model or load_model_name()
    client = genai.Client(api_key=api_key)
    print(f"model={model} stems={len(stems)}")

    failures: list[str] = []
    for i, stem in enumerate(stems, 1):
        eid, start_brief, end_brief = BRIEFS[stem]
        print(f"\n[{i}/{len(stems)}] {stem} ({eid})")
        try:
            backup_frames(stem)
            start_img = generate_pose(client, model, stem, "START", start_brief)
            time.sleep(args.sleep)
            end_img = generate_pose(client, model, stem, "END", end_brief)
            p1, p2 = write_frame_pair(stem, start_img, end_img)
            print(f"  wrote {p1.name}, {p2.name}")
            if args.assemble:
                assemble_stem(stem, eid)
        except Exception as e:  # noqa: BLE001
            print(f"  FAIL {stem}: {e}")
            failures.append(stem)
            # try restore backup
            bak = BACKUP_ROOT / stem
            if bak.is_dir():
                dest = FRAMES_ROOT / stem
                if dest.exists():
                    shutil.rmtree(dest)
                shutil.copytree(bak, dest)
                print("  restored backup frames")
        time.sleep(args.sleep)

    print(f"\nDone. failures={len(failures)} {failures}")
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
