"""Turn a raw ChatGPT N x M grid image into a clean grid sheet with equal square cells.

usage: process_grid.py <raw.png> <rows> <cols> <out.png> [--cell N] [--align bottom|center] [--preview p.png] [--key-black]
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
import numpy as np
from analyze_stylelock import block_size, snap_palette, to_logical


def key_black(img, thresh=14):
    a = np.array(img.convert("RGBA"))
    bg = a[..., :3].max(axis=2) < thresh
    a[..., 3] = np.where(bg, 0, 255)
    return Image.fromarray(a, "RGBA")


def components(mask):
    """Label 4-connected components of a boolean mask; returns label array and sizes."""
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    sizes = []
    cur = 0
    for y in range(h):
        for x in range(w):
            if mask[y, x] and labels[y, x] == 0:
                cur += 1
                stack = [(y, x)]; labels[y, x] = cur; n = 0
                while stack:
                    cy, cx = stack.pop(); n += 1
                    for ny, nx in ((cy-1, cx), (cy+1, cx), (cy, cx-1), (cy, cx+1)):
                        if 0 <= ny < h and 0 <= nx < w and mask[ny, nx] and labels[ny, nx] == 0:
                            labels[ny, nx] = cur; stack.append((ny, nx))
                sizes.append(n)
    return labels, sizes


def drop_detached(cell, min_frac=0.12):
    a = np.array(cell)
    mask = a[..., 3] > 0
    if not mask.any():
        return cell
    labels, sizes = components(mask)
    biggest = max(sizes)
    keep = np.zeros_like(mask)
    for i, n in enumerate(sizes, start=1):
        if n >= biggest * min_frac:
            keep |= labels == i
    a[..., 3] = np.where(keep, a[..., 3], 0)
    return Image.fromarray(a, "RGBA")


def process(raw, rows, cols, out, cell=None, align="bottom", preview=None, keyblack=False, min_frac=0.12):
    img = Image.open(raw).convert("RGBA")
    if keyblack:
        img = key_black(img)
    arr = np.array(img)
    block = round((block_size(arr, 1)[0][1] + block_size(arr, 0)[0][1]) / 2)
    logical = snap_palette(to_logical(img, block))
    cw, ch = logical.width / cols, logical.height / rows
    sprites = []
    for r in range(rows):
        for c in range(cols):
            box = (round(c * cw), round(r * ch), round((c + 1) * cw), round((r + 1) * ch))
            s = drop_detached(logical.crop(box), min_frac)
            bb = s.getbbox()
            sprites.append(s.crop(bb) if bb else None)
    maxw = max(s.width for s in sprites if s); maxh = max(s.height for s in sprites if s)
    if cell is None:
        cell = next(n for n in (16, 32, 48, 64, 96, 128) if n >= max(maxw, maxh))
    sheet = Image.new("RGBA", (cols * cell, rows * cell))
    for i, s in enumerate(sprites):
        if not s: continue
        r, c = divmod(i, cols)
        x = c * cell + (cell - s.width) // 2
        y = r * cell + (cell - s.height if align == "bottom" else (cell - s.height) // 2)
        sheet.paste(s, (x, y))
    sheet.save(out)
    if preview:
        k = 4
        big = sheet.resize((sheet.width * k, sheet.height * k), Image.NEAREST)
        bg = Image.new("RGBA", big.size, (90, 90, 90, 255))
        px = bg.load()
        for c in range(1, cols):
            for y in range(big.height): px[c * cell * k, y] = (140, 140, 140, 255)
        for r in range(1, rows):
            for x in range(big.width): px[x, r * cell * k] = (140, 140, 140, 255)
        bg.paste(big, (0, 0), big); bg.save(preview)
    return block, cell, maxw, maxh


if __name__ == "__main__":
    a = sys.argv[1:]
    opt = {"cell": None, "align": "bottom", "preview": None, "keyblack": False}
    if "--cell" in a: i = a.index("--cell"); opt["cell"] = int(a[i+1]); del a[i:i+2]
    if "--align" in a: i = a.index("--align"); opt["align"] = a[i+1]; del a[i:i+2]
    if "--preview" in a: i = a.index("--preview"); opt["preview"] = a[i+1]; del a[i:i+2]
    if "--key-black" in a: a.remove("--key-black"); opt["keyblack"] = True
    raw, rows, cols, out = a[0], int(a[1]), int(a[2]), a[3]
    print(raw, process(raw, rows, cols, out, **opt))
