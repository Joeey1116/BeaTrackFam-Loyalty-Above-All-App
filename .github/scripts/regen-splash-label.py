#!/usr/bin/env python3
"""Regenerate the splash screen's version label for the current build number.

The Main app's splash (assets/splash.png, 1290x2796) carries a small bottom
label "14.0.0 (1400)". The build workflows auto-bump the build number on
every run, so without this the label would go stale after the first rebuild
(it already lagged once: splash read 1300 against live build 1301).

What it does:
  1. Reads expo.version + expo.ios.buildNumber from app.json -> "14.0.0 (1401)".
  2. Erases the old label by cloning the fabric texture from directly above
     it (never a flat fill — the knit texture would show a seam).
  3. Draws the new label in the exact same font/position as the shipped
     splash: DejaVu Sans Bold 20 (bundled here as DejaVuSans-Bold.ttf),
     centered at x=645, ink top y=2726. Verified Nov 10, 2026: rendering
     "14.0.0 (1400)" this way matches the shipped label at 0.987 pixel IoU.

Run from the repo root, after the build-number bump step, before prebuild.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

SPLASH = "assets/splash.png"
FONT = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                    "DejaVuSans-Bold.ttf")

# Label geometry, measured from the shipped splash (Nov 10, 2026):
# ink x 570-718, y 2726-2743 on a 1290x2796 canvas; centered at x=645.
LABEL_CENTER_X = 645
LABEL_INK_TOP = 2726
ERASE_BOX = (560, 2716, 730, 2754)   # (left, upper, right, lower)
SOURCE_BOX = (560, 2678, 730, 2716)  # fabric directly above the label
FONT_SIZE = 20

with open("app.json", encoding="utf-8") as f:
    expo = json.load(f)["expo"]
label = f"{expo['version']} ({expo['ios']['buildNumber']})"

im = Image.open(SPLASH).convert("RGB")
if im.size != (1290, 2796):
    print(f"::error::Unexpected splash size {im.size}, expected (1290, 2796). "
          "Label geometry is measured for 1290x2796 — refusing to guess.")
    sys.exit(1)

# 1. Erase the old label with a clone of the fabric directly above it.
im.paste(im.crop(SOURCE_BOX), ERASE_BOX[:2])

# 2. Draw the new label, same font/position as the shipped splash.
font = ImageFont.truetype(FONT, FONT_SIZE)
draw = ImageDraw.Draw(im)
bb = draw.textbbox((0, 0), label, font=font)
ink_center_x = (bb[0] + bb[2]) / 2
draw.text((LABEL_CENTER_X - ink_center_x, LABEL_INK_TOP - bb[1]),
          label, font=font, fill=(255, 255, 255))

im.save(SPLASH)
print(f"Splash label updated to '{label}'")
