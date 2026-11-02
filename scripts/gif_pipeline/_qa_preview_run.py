from PIL import Image, ImageChops, ImageStat
from pathlib import Path


def mean_abs_diff(a: Image.Image, b: Image.Image) -> float:
    a = a.convert("RGB")
    b = b.convert("RGB")
    if a.size != b.size:
        b = b.resize(a.size)
    diff = ImageChops.difference(a, b)
    return sum(ImageStat.Stat(diff).mean) / 3.0


stems = [
    "assisted_pull_up_machine",
    "barbell_romanian_deadlift",
    "chin_up",
    "neutral_grip_pull_up",
    "rack_pull",
    "sumo_deadlift",
    "wide_grip_pull_up",
    "pull_up",
]
out = Path("scripts/gif_pipeline/_qa_preview")
out.mkdir(parents=True, exist_ok=True)

for stem in stems:
    gif = Path(f"assets/exercises/images/back/{stem}.gif")
    im = Image.open(gif)
    frames = []
    try:
        while True:
            frames.append(im.copy().convert("RGB"))
            im.seek(im.tell() + 1)
    except EOFError:
        pass
    diffs = [mean_abs_diff(a, b) for a, b in zip(frames, frames[1:])]
    fl = mean_abs_diff(frames[0], frames[-1]) if len(frames) > 1 else 0.0
    fr = Path(f"scripts/gif_pipeline/frames/{stem}")
    s2 = Image.open(fr / "01_start.jpg").convert("RGB").resize((512, 512))
    e2 = Image.open(fr / "02_end.jpg").convert("RGB").resize((512, 512))
    se = mean_abs_diff(s2, e2)
    combo = Image.new("RGB", (1024, 512))
    combo.paste(s2, (0, 0))
    combo.paste(e2, (512, 0))
    combo.save(out / f"{stem}_pair.jpg", quality=90)
    frames[0].resize((512, 512)).save(out / f"{stem}_gif0.jpg", quality=90)
    frames[len(frames) // 2].resize((512, 512)).save(out / f"{stem}_gifmid.jpg", quality=90)
    mean_d = sum(diffs) / len(diffs) if diffs else 0.0
    print(
        f"{stem}: gif_frames={len(frames)} consec_mean={mean_d:.2f} "
        f"first_last={fl:.2f} start_end_src={se:.2f}"
    )
