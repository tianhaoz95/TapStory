#!/usr/bin/env python3
"""
Bakes a device frame (bezel, rounded screen corners, drop shadow) directly
into a copy of each screenshot, for display on the landing page and in
README.md. This has to happen at the image level rather than via CSS: raw
Markdown/HTML rendered by GitHub strips <style> blocks and most inline
styling, so a CSS-only frame (fine for docs/index.html on its own) can't
survive on GitHub's README rendering.

Raw screenshots from capture_screenshots.sh are left completely
untouched under docs/screenshots/<device>/ -- those stay pixel-accurate
to real device dimensions, which matters if they're ever reused for an
actual App Store Connect screenshot upload. Framed copies are written to
docs/screenshots/framed/<device>/ instead.

Usage: ./Scripts/frame_screenshots.py
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC_ROOT = ROOT / "docs" / "screenshots"
DST_ROOT = ROOT / "docs" / "screenshots" / "framed"

BEZEL_COLOR = (18, 18, 20, 255)

PHONE_DEVICES = ["iphone-17-pro-max", "iphone-11-pro-max"]
PHONE_SCENES = ["idle", "story-magic-monkey", "vocab-letter-m", "music-lullaby", "dashboard"]


def rounded_mask(size, radius):
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([(0, 0), (size[0] - 1, size[1] - 1)], radius=radius, fill=255)
    return mask


def drop_shadow(canvas_size, rect, radius, blur, opacity=115, y_offset_ratio=0.012):
    shadow = Image.new("RGBA", canvas_size, (0, 0, 0, 0))
    (x0, y0), (x1, y1) = rect
    offset = int((y1 - y0) * y_offset_ratio)
    ImageDraw.Draw(shadow).rounded_rectangle(
        [(x0, y0 + offset), (x1, y1 + offset)], radius=radius, fill=(0, 0, 0, opacity)
    )
    return shadow.filter(ImageFilter.GaussianBlur(blur))


def frame_phone(src_path: Path, dst_path: Path):
    shot = Image.open(src_path).convert("RGBA")
    w, h = shot.size

    bezel = round(w * 0.022)
    corner = round(w * 0.125)  # matches a modern iPhone's screen corner radius closely enough
    pad = round(w * 0.05)

    screen = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    screen.paste(shot, (0, 0), rounded_mask((w, h), corner))

    body_w, body_h = w + bezel * 2, h + bezel * 2
    canvas_w, canvas_h = body_w + pad * 2, body_h + pad * 2
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

    body_rect = ((pad, pad), (pad + body_w, pad + body_h))
    canvas = Image.alpha_composite(canvas, drop_shadow((canvas_w, canvas_h), body_rect, corner + bezel, round(w * 0.028)))

    body = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    ImageDraw.Draw(body).rounded_rectangle(
        [body_rect[0], body_rect[1]], radius=corner + bezel, fill=BEZEL_COLOR
    )
    canvas = Image.alpha_composite(canvas, body)
    canvas.paste(screen, (pad + bezel, pad + bezel), screen)

    dst_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dst_path)


def frame_watch(src_path: Path, dst_path: Path):
    shot = Image.open(src_path).convert("RGBA")
    w, h = shot.size

    bezel = round(w * 0.075)
    corner = round(min(w, h) * 0.34)  # Watch cases read as a rounded squircle, not a plain rounded rect
    pad = round(w * 0.11)

    screen = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    screen.paste(shot, (0, 0), rounded_mask((w, h), round(corner * 0.72)))

    body_w, body_h = w + bezel * 2, h + bezel * 2
    canvas_w, canvas_h = body_w + pad * 2, body_h + pad * 2
    canvas = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))

    body_rect = ((pad, pad), (pad + body_w, pad + body_h))
    canvas = Image.alpha_composite(canvas, drop_shadow((canvas_w, canvas_h), body_rect, corner + bezel, round(w * 0.05), opacity=130))

    body = Image.new("RGBA", (canvas_w, canvas_h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(body)
    draw.rounded_rectangle([body_rect[0], body_rect[1]], radius=corner + bezel, fill=BEZEL_COLOR)

    # Digital Crown + side button nubs on the right edge -- what actually
    # reads as "Apple Watch" rather than just another rounded rectangle.
    right_x = pad + body_w
    nub_w = round(bezel * 1.3)
    crown_h = round(body_h * 0.15)
    crown_y = pad + round(body_h * 0.28)
    draw.rounded_rectangle(
        [(right_x - bezel * 0.4, crown_y), (right_x + nub_w, crown_y + crown_h)],
        radius=nub_w // 2, fill=BEZEL_COLOR
    )
    button_h = round(body_h * 0.10)
    button_y = pad + round(body_h * 0.52)
    button_w = round(nub_w * 0.75)
    draw.rounded_rectangle(
        [(right_x - bezel * 0.4, button_y), (right_x + button_w, button_y + button_h)],
        radius=button_w // 2, fill=BEZEL_COLOR
    )

    canvas = Image.alpha_composite(canvas, body)
    canvas.paste(screen, (pad + bezel, pad + bezel), screen)

    dst_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dst_path)


def main():
    count = 0
    for device in PHONE_DEVICES:
        for scene in PHONE_SCENES:
            src = SRC_ROOT / device / f"{scene}.png"
            if not src.exists():
                continue
            dst = DST_ROOT / device / f"{scene}.png"
            frame_phone(src, dst)
            count += 1
            print(f"  {src.relative_to(ROOT)} -> {dst.relative_to(ROOT)}")

    watch_src = SRC_ROOT / "apple-watch" / "overview.png"
    if watch_src.exists():
        watch_dst = DST_ROOT / "apple-watch" / "overview.png"
        frame_watch(watch_src, watch_dst)
        count += 1
        print(f"  {watch_src.relative_to(ROOT)} -> {watch_dst.relative_to(ROOT)}")

    print(f"Done. Framed {count} image(s) under {DST_ROOT.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
