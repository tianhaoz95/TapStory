#!/usr/bin/env python3
"""
Generates the 1024x1024 App Icon source image, shared by both the
TapStory (iOS) and TapStoryWatch (watchOS) asset catalogs. Deliberately
matches the app's own visual identity rather than inventing a new one:
solid black background (exactly IdleTapPromptView's Color.black) with a
present/gift box in the app's accent orange (matching --accent in
docs/assets/style.css) -- a "magic box" wrapped like a gift, which is
literally what this product turns a toy into.

Apple requires app icon source images to be fully opaque (no alpha) and
NOT pre-rounded -- the OS applies corner/circle masking itself.

Usage: ./Scripts/generate_app_icon.py
"""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
SIZE = 1024

BG = (0, 0, 0, 255)
BOX = (224, 122, 44, 255)  # matches --accent
RIBBON = (255, 255, 255, 255)


def rounded_rect(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def main():
    img = Image.new("RGBA", (SIZE, SIZE), BG)
    draw = ImageDraw.Draw(img)

    # The gift box body.
    box_w, box_h = 620, 520
    box_x0 = (SIZE - box_w) // 2
    box_y0 = 360
    box_x1, box_y1 = box_x0 + box_w, box_y0 + box_h
    rounded_rect(draw, [box_x0, box_y0, box_x1, box_y1], radius=52, fill=BOX)

    # The lid: a slightly wider, shorter band across the top of the box.
    lid_w, lid_h = box_w + 44, 96
    lid_x0 = box_x0 - 22
    lid_y0 = box_y0 - 32
    rounded_rect(draw, [lid_x0, lid_y0, lid_x0 + lid_w, lid_y0 + lid_h], radius=40, fill=BOX)

    # Ribbon: vertical + horizontal white bands across the whole gift.
    ribbon_w = 80
    v_x0 = (SIZE - ribbon_w) // 2
    draw.rectangle([v_x0, lid_y0 - 10, v_x0 + ribbon_w, box_y1], fill=RIBBON)
    h_y0 = box_y0 + (box_h - ribbon_w) // 2
    draw.rectangle([box_x0, h_y0, box_x1, h_y0 + ribbon_w], fill=RIBBON)
    # Re-draw the lid's ribbon segment on top so the ribbon reads as
    # continuous even where it crosses the lid band.
    draw.rectangle([v_x0, lid_y0 - 10, v_x0 + ribbon_w, lid_y0 + lid_h], fill=RIBBON)

    # Bow: two loops + a center knot, sitting on top of the lid.
    bow_cy = lid_y0 - 45
    loop_r = 105
    draw.ellipse([SIZE // 2 - loop_r * 2 + 22, bow_cy - loop_r, SIZE // 2 - 22, bow_cy + loop_r], fill=RIBBON)
    draw.ellipse([SIZE // 2 + 22, bow_cy - loop_r, SIZE // 2 + loop_r * 2 - 22, bow_cy + loop_r], fill=RIBBON)
    # Punch the loop holes out in the background color so the loops read
    # as rings, not solid discs.
    hole_r = 50
    draw.ellipse([SIZE // 2 - loop_r * 2 + 22 + 38, bow_cy - hole_r, SIZE // 2 - 22 - 38, bow_cy + hole_r], fill=BG)
    draw.ellipse([SIZE // 2 + 22 + 38, bow_cy - hole_r, SIZE // 2 + loop_r * 2 - 22 - 38, bow_cy + hole_r], fill=BG)
    knot_r = 44
    draw.ellipse([SIZE // 2 - knot_r, bow_cy - knot_r, SIZE // 2 + knot_r, bow_cy + knot_r], fill=RIBBON)

    # Flatten onto opaque black -- Apple rejects icons with an alpha channel.
    flat = Image.new("RGB", (SIZE, SIZE), BG[:3])
    flat.paste(img, (0, 0), img)

    for dst in [
        ROOT / "App/TapStory/Assets.xcassets/AppIcon.appiconset/icon-1024.png",
        ROOT / "App/TapStoryWatch/Assets.xcassets/AppIcon.appiconset/icon-1024.png",
    ]:
        dst.parent.mkdir(parents=True, exist_ok=True)
        flat.save(dst)
        print(f"Wrote {dst.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
