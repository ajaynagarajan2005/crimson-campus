"""Upscales the campus photos with EDSR super-resolution (OpenCV dnn_superres).

Run from the project root:
    backend\\.venv\\Scripts\\python tools\\enhance_images.py

Originals are kept in tools/original_images/ (not bundled with the app), so the
script can be re-run safely: it always starts from the originals.
"""

import shutil
import time
from pathlib import Path

import cv2
from PIL import Image, ImageEnhance, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets" / "images"
ORIGINALS = ROOT / "tools" / "original_images"
MODELS = ROOT / "tools" / "sr_models"
PHOTOS = [
    "inti_campus.jpg",
    "inti_students.jpg",
    "inti_aerial.jpg",
    "inti_atrium.jpg",
    "inti_graduates.jpg",
]
MAX_SIDE = 2200


def load_model(scale: int):
    sr = cv2.dnn_superres.DnnSuperResImpl_create()
    sr.readModel(str(MODELS / f"EDSR_x{scale}.pb"))
    sr.setModel("edsr", scale)
    return sr


def main() -> None:
    ORIGINALS.mkdir(parents=True, exist_ok=True)
    models = {}
    for name in PHOTOS:
        original = ORIGINALS / name
        if not original.exists():
            shutil.copy2(ASSETS / name, original)

        image = cv2.imread(str(original))
        h, w = image.shape[:2]
        scale = 4 if max(h, w) < 800 else 2
        sr = models.setdefault(scale, load_model(scale))

        start = time.time()
        upscaled = sr.upsample(image)
        rgb = Image.fromarray(cv2.cvtColor(upscaled, cv2.COLOR_BGR2RGB))

        # Gentle finishing: cap size, a light unsharp mask and a touch of contrast.
        rgb.thumbnail((MAX_SIDE, MAX_SIDE), Image.LANCZOS)
        rgb = rgb.filter(ImageFilter.UnsharpMask(radius=1.2, percent=60, threshold=2))
        rgb = ImageEnhance.Contrast(rgb).enhance(1.04)
        rgb.save(ASSETS / name, "JPEG", quality=88, optimize=True, progressive=True)
        print(f"{name}: {w}x{h} -> {rgb.width}x{rgb.height} (x{scale}, {time.time() - start:.0f}s)")


if __name__ == "__main__":
    main()
