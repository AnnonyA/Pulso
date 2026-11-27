#!/usr/bin/env python3
"""Rebuild Pulso's original geometric app icons with Pillow. No remote assets."""
from pathlib import Path
import json
import math

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
ASSETS = ROOT / "Sources/Pulso/Resources/Assets.xcassets"


def color(hex_value):
    return tuple(int(hex_value[i:i + 2], 16) for i in (1, 3, 5))


def make_icon(filename, background, foreground, ring):
    scale = 3
    image = Image.new("RGB", (1024 * scale, 1024 * scale), color(background))
    draw = ImageDraw.Draw(image)
    def box(values):
        return tuple(round(v * scale) for v in values)
    # The arcs form the open NFC field around a small electric pulse.
    draw.arc(box((162, 162, 862, 862)), 214, 326, fill=color(ring), width=18 * scale)
    draw.arc(box((162, 162, 862, 862)), 34, 146, fill=color(ring), width=18 * scale)
    draw.arc(box((245, 245, 779, 779)), 220, 320, fill=color(foreground), width=35 * scale)
    draw.arc(box((245, 245, 779, 779)), 40, 140, fill=color(foreground), width=35 * scale)
    points = [(267, 512), (392, 512), (458, 407), (557, 615), (626, 512), (757, 512)]
    points = [(x * scale, y * scale) for x, y in points]
    width = 45 * scale
    draw.line(points, fill=color(foreground), width=width, joint="curve")
    for x, y in points:
        r = width / 2
        draw.ellipse((round(x-r), round(y-r), round(x+r), round(y+r)), fill=color(foreground))
    image.resize((1024, 1024), Image.Resampling.LANCZOS).save(filename, optimize=True)


def main():
    icons = ASSETS / "AppIcon.appiconset"
    icons.mkdir(parents=True, exist_ok=True)
    make_icon(icons / "AppIcon.png", "#102B28", "#B8F3D5", "#457C6C")
    make_icon(icons / "AppIcon-dark.png", "#0A1917", "#B8F3D5", "#2D5A4B")
    make_icon(icons / "AppIcon-tinted.png", "#171717", "#E4E4E4", "#747474")
    entries = [{"filename": "AppIcon.png", "idiom": "universal", "platform": "ios", "size": "1024x1024"}]
    for appearance in ("dark", "tinted"):
        entries.append({"filename": f"AppIcon-{appearance}.png", "idiom": "universal", "platform": "ios", "size": "1024x1024", "appearances": [{"appearance": "luminosity", "value": appearance}]})
    (icons / "Contents.json").write_text(json.dumps({"images": entries, "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    (ASSETS / "Contents.json").write_text(json.dumps({"info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    accent = ASSETS / "AccentColor.colorset"
    accent.mkdir(exist_ok=True)
    (accent / "Contents.json").write_text(json.dumps({"colors": [{"idiom": "universal", "color": {"color-space": "srgb", "components": {"alpha": "1.000", "red": "0.055", "green": "0.357", "blue": "0.286"}}}, {"idiom": "universal", "appearances": [{"appearance": "luminosity", "value": "dark"}], "color": {"color-space": "srgb", "components": {"alpha": "1.000", "red": "0.722", "green": "0.953", "blue": "0.835"}}}], "info": {"author": "xcode", "version": 1}}, indent=2) + "\n")
    print(f"Wrote 3 RGB app icons and asset catalog to {ASSETS}")


if __name__ == "__main__":
    main()
