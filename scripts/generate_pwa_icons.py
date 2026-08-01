"""Generate PWA icons from assets/images/app_icon_source.png."""
from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "images" / "app_icon_source.png"
WEB_ICONS = ROOT / "web" / "icons"
BG = (13, 15, 20, 255)  # #0D0F14


def fit_square(img: Image.Image, size: int) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), BG)
    img = img.convert("RGBA")
    scale = min(size / img.width, size / img.height)
    w, h = int(img.width * scale), int(img.height * scale)
    resized = img.resize((w, h), Image.Resampling.LANCZOS)
    x = (size - w) // 2
    y = (size - h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def maskable(img: Image.Image, size: int) -> Image.Image:
    """Keep logo inside Android maskable safe zone (~80%)."""
    canvas = Image.new("RGBA", (size, size), BG)
    img = img.convert("RGBA")
    safe = int(size * 0.8)
    scale = min(safe / img.width, safe / img.height)
    w, h = int(img.width * scale), int(img.height * scale)
    resized = img.resize((w, h), Image.Resampling.LANCZOS)
    x = (size - w) // 2
    y = (size - h) // 2
    canvas.paste(resized, (x, y), resized)
    return canvas


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Missing source icon: {SOURCE}")

    WEB_ICONS.mkdir(parents=True, exist_ok=True)
    src = Image.open(SOURCE)

    sizes = {
        "Icon-192.png": (192, fit_square),
        "Icon-512.png": (512, fit_square),
        "Icon-maskable-192.png": (192, maskable),
        "Icon-maskable-512.png": (512, maskable),
    }

    for name, (size, fn) in sizes.items():
        out = WEB_ICONS / name
        fn(src, size).save(out, format="PNG", optimize=True)
        print(f"wrote {out}")

    favicon = ROOT / "web" / "favicon.png"
    fit_square(src, 48).save(favicon, format="PNG", optimize=True)
    print(f"wrote {favicon}")


if __name__ == "__main__":
    main()
