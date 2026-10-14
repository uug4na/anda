#!/usr/bin/env python3
"""Tile every processed asset into one labelled review image.

usage: contact_sheet.py [out.png] [--scale 2] [--category hero]
"""
import sys
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "processed"


def main():
    args = sys.argv[1:]
    scale = 2
    cat_filter = None
    if "--scale" in args:
        i = args.index("--scale"); scale = int(args[i + 1]); del args[i:i + 2]
    if "--category" in args:
        i = args.index("--category"); cat_filter = args[i + 1]; del args[i:i + 2]
    out_path = Path(args[0]) if args else OUT / "contact_sheet.png"

    entries = []
    for cat in sorted(p for p in OUT.iterdir() if p.is_dir() and p.name not in ("stylelock",)):
        if cat_filter and cat.name != cat_filter:
            continue
        for f in sorted(cat.glob("*.png")):
            entries.append((cat.name, f))
    if not entries:
        sys.exit("nothing to show")

    max_w = 1600
    pad, label_h = 12, 14
    tiles = []
    for cat, f in entries:
        im = Image.open(f).convert("RGBA")
        s = scale
        while im.width * s > max_w - 2 * pad and s > 1:
            s -= 1
        im = im.resize((im.width * s, im.height * s), Image.NEAREST)
        tiles.append((f"{cat}/{f.stem}  ({Image.open(f).width}x{Image.open(f).height})", im))

    # simple row packing
    rows, row, row_w = [], [], 0
    for label, im in tiles:
        w = max(im.width, 220) + pad
        if row and row_w + w > max_w:
            rows.append(row); row, row_w = [], 0
        row.append((label, im)); row_w += w
    if row:
        rows.append(row)
    H = sum(max(im.height for _, im in r) + label_h + pad * 2 for r in rows)
    sheet = Image.new("RGBA", (max_w, H), (70, 70, 70, 255))
    draw = ImageDraw.Draw(sheet)
    y = 0
    for r in rows:
        x = pad
        rh = max(im.height for _, im in r)
        for label, im in r:
            draw.text((x, y + 2), label, fill=(230, 230, 230, 255))
            sheet.paste(im, (x, y + label_h + pad), im)
            x += max(im.width, 220) + pad
        y += rh + label_h + pad * 2
    sheet.save(out_path)
    print(out_path, sheet.size, len(tiles), "assets")


if __name__ == "__main__":
    main()
