"""Combines design/screens/*.png into one labelled overview sheet.

Run from the project root after capturing the screens:
    backend\\.venv\\Scripts\\python screenshots\\build_overview.py
"""

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

SCREENS = sorted(Path("design/screens").glob("*.png"))
OUT = Path("design/all_pages_overview.png")
FLUTTER_ROOT = os.environ.get(
    "FLUTTER_ROOT", r"C:/Users/ajayn/Downloads/flutter_windows_3.47.6-stable/flutter"
)
FONTS = Path(FLUTTER_ROOT) / "bin/cache/artifacts/material_fonts"

THUMB_W, THUMB_H = 300, 650  # first phone screen of each page
COLS, GAP, LABEL_H, MARGIN = 6, 36, 44, 48


def main() -> None:
    title_font = ImageFont.truetype(str(FONTS / "roboto-bold.ttf"), 34)
    label_font = ImageFont.truetype(str(FONTS / "roboto-medium.ttf"), 22)

    rows = -(-len(SCREENS) // COLS)
    width = MARGIN * 2 + COLS * THUMB_W + (COLS - 1) * GAP
    height = MARGIN + 70 + rows * (THUMB_H + LABEL_H + GAP) + MARGIN - GAP
    sheet = Image.new("RGB", (width, height), (250, 245, 245))
    draw = ImageDraw.Draw(sheet)
    draw.text(
        (MARGIN, MARGIN - 8),
        "Crimson Campus — all pages (phone, first screen of each)",
        font=title_font,
        fill=(74, 5, 5),
    )

    for i, path in enumerate(SCREENS):
        img = Image.open(path).convert("RGB")
        view_h = int(img.width * 844 / 390)
        img = img.crop((0, 0, img.width, min(view_h, img.height)))
        img = img.resize((THUMB_W, int(img.height * THUMB_W / img.width)), Image.LANCZOS)

        row, col = divmod(i, COLS)
        x = MARGIN + col * (THUMB_W + GAP)
        y = MARGIN + 70 + row * (THUMB_H + LABEL_H + GAP)
        number, name = path.stem.split("_", 1)
        draw.text((x, y), f"{number}  {name.replace('_', ' ').capitalize()}", font=label_font, fill=(60, 20, 20))

        mask = Image.new("L", img.size, 0)
        ImageDraw.Draw(mask).rounded_rectangle((0, 0, *img.size), radius=22, fill=255)
        sheet.paste(img, (x, y + LABEL_H), mask)
        draw.rounded_rectangle(
            (x, y + LABEL_H, x + img.width - 1, y + LABEL_H + img.height - 1),
            radius=22,
            outline=(220, 200, 200),
            width=2,
        )

    sheet.save(OUT, optimize=True)
    print(OUT, sheet.size)


if __name__ == "__main__":
    main()
