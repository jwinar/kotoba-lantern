#!/usr/bin/env python3
"""Draws the app icon and writes every size iOS asks for.

    python3 scripts/build_icons.py

The mark is the app's own lantern - the same silhouette
`lib/widgets/lantern.dart` paints, lit, on the night ground the app opens
in. Drawn in code rather than kept as a binary so the icon and the running
app can't drift apart: both take their geometry and their palette from the
same numbers.

iOS icons must be fully opaque with no alpha channel and no rounded corners
of their own (the system masks them), so everything is composited onto an
opaque ground and saved as RGB.
"""

import os

from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONSET = os.path.join(
    ROOT, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset"
)

# Straight from LanternColors.dark / the Chōchin palette.
NIGHT = (20, 16, 15)
PLUM = (44, 29, 34)
LANTERN = (228, 118, 46)
PAPER = (246, 241, 228)

# Master is drawn at 4x the largest export, then downsampled - cheap
# supersampling, and the ribs stay crisp at 40px.
MASTER = 4096

SIZES = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]


def lantern_body(cx: float, cy: float, width: float, height: float) -> list:
    """The chōchin silhouette as a polygon, mirroring the cubic curves in
    LanternPainter._bodyPath so the icon and the in-app lantern are the same
    shape."""
    points = []
    steps = 240
    half_w = width / 2
    half_h = height / 2
    for i in range(steps + 1):
        t = i / steps
        # A superellipse: straighter shoulders than an ellipse, fat belly.
        angle = t * 2 * 3.141592653589793
        import math

        sin_a = math.sin(angle)
        cos_a = math.cos(angle)
        n = 2.6
        x = cx + half_w * (abs(cos_a) ** (2 / n)) * (1 if cos_a >= 0 else -1)
        y = cy + half_h * (abs(sin_a) ** (2 / n)) * (1 if sin_a >= 0 else -1)
        points.append((x, y))
    return points


def draw_icon(size: int, ground: bool = True) -> Image.Image:
    """Draws the lantern.

    With [ground], the full icon: night panel, plum lift, glow, lantern -
    an opaque square for the home screen. Without it, the lantern and its
    glow alone on transparency, for the launch screen, where the storyboard
    already paints a flat night behind it and any ground of our own would
    show as a lighter square.
    """
    image = Image.new("RGB", (size, size), NIGHT)
    draw = ImageDraw.Draw(image)

    # Night ground with the plum lift in the top-left corner, matching the
    # hero panel's gradient direction.
    if ground:
        for y in range(size):
            blend = max(0.0, 1.0 - (y / size) * 1.5)
            row = tuple(
                int(NIGHT[i] + (PLUM[i] - NIGHT[i]) * blend * 0.85) for i in range(3)
            )
            draw.line([(0, y), (size, y)], fill=row)

    # The glow the lantern throws, drawn as concentric discs and blurred.
    glow = Image.new("L", (size, size), 0)
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse(
        [size * 0.16, size * 0.16, size * 0.84, size * 0.9], fill=150
    )
    glow = glow.filter(ImageFilter.GaussianBlur(size * 0.10))
    image = Image.composite(Image.new("RGB", (size, size), LANTERN), image, glow)
    draw = ImageDraw.Draw(image)
    # Kept for the transparent variant: everything lit is the lantern plus
    # its glow, so that same mask is exactly the alpha channel.
    lit = glow

    cx = size / 2
    cy = size * 0.53
    body_w = size * 0.47
    body_h = size * 0.60

    # The lit paper. A vertical gradient inside the body - brighter low,
    # where the flame sits - keeps it from reading as a flat orange pill at
    # 60pt.
    body_mask_fill = Image.new("L", (size, size), 0)
    ImageDraw.Draw(body_mask_fill).polygon(
        lantern_body(cx, cy, body_w, body_h), fill=255
    )
    paper = Image.new("RGB", (size, size), LANTERN)
    paper_draw = ImageDraw.Draw(paper)
    top = cy - body_h / 2
    for y in range(int(top), int(cy + body_h / 2) + 1):
        t = (y - top) / body_h
        # Warm up toward the base without going pale: +14% red, +22% green.
        row = (
            min(255, int(LANTERN[0] * (1 + 0.10 * t))),
            min(255, int(LANTERN[1] * (1 + 0.30 * t))),
            min(255, int(LANTERN[2] * (1 + 0.22 * t))),
        )
        paper_draw.line([(0, y), (size, y)], fill=row)
    image = Image.composite(paper, image, body_mask_fill)
    draw = ImageDraw.Draw(image)

    # Bamboo ribs, clipped to the body by drawing them into a mask.
    ribs = Image.new("L", (size, size), 0)
    ribs_draw = ImageDraw.Draw(ribs)
    rib_gap = body_h / 6
    y = cy - body_h / 2 + rib_gap
    while y < cy + body_h / 2:
        ribs_draw.line(
            [(0, y), (size, y)], fill=255, width=max(1, int(size * 0.007))
        )
        y += rib_gap
    body_mask = Image.new("L", (size, size), 0)
    ImageDraw.Draw(body_mask).polygon(
        lantern_body(cx, cy, body_w, body_h), fill=255
    )
    ribs = Image.composite(ribs, Image.new("L", (size, size), 0), body_mask)
    # Ribs are the paper darkened, not black lines drawn on top - bamboo
    # showing through from behind is what they actually are.
    shade = tuple(int(c * 0.62) for c in LANTERN)
    image = Image.composite(Image.new("RGB", (size, size), shade), image, ribs)
    draw = ImageDraw.Draw(image)

    # Cap and base fittings, plus the cord it hangs from.
    fitting_w = body_w * 0.42
    fitting_h = size * 0.035
    top_y = cy - body_h / 2 - fitting_h * 0.4
    draw.rounded_rectangle(
        [cx - fitting_w / 2, top_y - fitting_h, cx + fitting_w / 2, top_y],
        radius=fitting_h * 0.35,
        fill=PAPER,
    )
    base_y = cy + body_h / 2 + fitting_h * 0.4
    draw.rounded_rectangle(
        [
            cx - fitting_w * 0.36,
            base_y,
            cx + fitting_w * 0.36,
            base_y + fitting_h * 0.85,
        ],
        radius=fitting_h * 0.3,
        fill=PAPER,
    )
    draw.line(
        [(cx, size * 0.055), (cx, top_y - fitting_h)],
        fill=PAPER,
        width=max(1, int(size * 0.009)),
    )

    if ground:
        return image

    transparent = image.convert("RGBA")
    solid = Image.new("L", (size, size), 0)
    solid_draw = ImageDraw.Draw(solid)
    solid_draw.polygon(lantern_body(cx, cy, body_w, body_h), fill=255)
    solid_draw.rectangle(
        [cx - fitting_w / 2, top_y - fitting_h, cx + fitting_w / 2, top_y], fill=255
    )
    solid_draw.rectangle(
        [cx - fitting_w * 0.36, base_y, cx + fitting_w * 0.36, base_y + fitting_h],
        fill=255,
    )
    solid_draw.line(
        [(cx, size * 0.055), (cx, top_y)], fill=255, width=max(1, int(size * 0.012))
    )
    # Alpha = the lantern itself at full opacity, plus its glow fading out.
    alpha = Image.new("L", (size, size), 0)
    alpha.paste(lit, (0, 0))
    alpha.paste(solid, (0, 0), solid)
    transparent.putalpha(alpha)
    return transparent


LAUNCH_SET = os.path.join(
    ROOT, "ios", "Runner", "Assets.xcassets", "LaunchImage.imageset"
)


def draw_launch_mark(size: int) -> Image.Image:
    """The lantern alone on transparency, for the launch screen - the
    storyboard paints the night ground behind it, so the mark carries no
    background of its own and no seam can show."""
    return draw_icon(MASTER, ground=False).resize((size, size), Image.LANCZOS)


def main() -> None:
    master = draw_icon(MASTER)
    os.makedirs(ICONSET, exist_ok=True)
    for filename, size in SIZES:
        # LANCZOS off the 4096 master: the ribs are sub-pixel at 20pt and
        # any cheaper filter turns them into moiré.
        resized = master.resize((size, size), Image.LANCZOS).convert("RGB")
        resized.save(os.path.join(ICONSET, filename), format="PNG")
        print(f"  {filename}  {size}x{size}")
    print(f"\nwrote {len(SIZES)} icons to {os.path.relpath(ICONSET, ROOT)}")

    os.makedirs(LAUNCH_SET, exist_ok=True)
    for suffix, size in (("", 220), ("@2x", 440), ("@3x", 660)):
        mark = draw_launch_mark(size)
        mark.save(os.path.join(LAUNCH_SET, f"LaunchImage{suffix}.png"))
    print(f"wrote 3 launch images to {os.path.relpath(LAUNCH_SET, ROOT)}")


if __name__ == "__main__":
    main()
