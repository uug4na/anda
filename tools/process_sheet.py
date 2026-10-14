"""Turn a raw ChatGPT multi-cell sheet into a clean game sheet with fixed cells.

usage: process_sheet.py <raw.png> <cell_size> <out.png> [--preview out_preview.png] [--block N]
Detects the pixel block size, snaps to the ANDA-32 palette, splits cells on fully transparent
columns, and pads each cell to cell_size x cell_size with the sprite feet at bottom centre.
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
import numpy as np
from analyze_stylelock import block_size, snap_palette, to_logical


def split_cells(img, min_gap=2):
    a = np.array(img)[..., 3] > 0
    cols = a.any(axis=0)
    runs, start, gap = [], None, 0
    for x, v in enumerate(cols):
        if v:
            if start is None:
                start = x
            gap = 0
        else:
            if start is not None:
                gap += 1
                if gap >= min_gap:
                    runs.append((start, x - gap + 1))
                    start, gap = None, 0
    if start is not None:
        runs.append((start, len(cols)))
    return [img.crop((x0, 0, x1, img.height)).crop(img.crop((x0, 0, x1, img.height)).getbbox()) for x0, x1 in runs]


def process(raw_path, cell, out_path, preview_path=None, block=None):
    img = Image.open(raw_path).convert("RGBA")
    arr = np.array(img)
    if block is None:
        bx = block_size(arr, 1)[0][1]
        by = block_size(arr, 0)[0][1]
        block = round((bx + by) / 2)
    logical = snap_palette(to_logical(img, block))
    cells = split_cells(logical)
    sheet = Image.new("RGBA", (cell * len(cells), cell))
    info = []
    for i, c in enumerate(cells):
        if c.width > cell or c.height > cell:
            info.append(f"cell {i} {c.size} EXCEEDS {cell}")
        sheet.paste(c, (i * cell + (cell - c.width) // 2, cell - c.height))
        info.append(f"cell {i}: {c.width}x{c.height}")
    sheet.save(out_path)
    if preview_path:
        s = 4
        big = sheet.resize((sheet.width * s, sheet.height * s), Image.NEAREST)
        bg = Image.new("RGBA", big.size, (90, 90, 90, 255))
        # draw cell borders
        px = bg.load()
        for i in range(1, len(cells)):
            for y in range(big.height):
                px[i * cell * s, y] = (140, 140, 140, 255)
        bg.paste(big, (0, 0), big)
        bg.save(preview_path)
    return block, info


if __name__ == "__main__":
    args = sys.argv[1:]
    prev = None
    blk = None
    if "--preview" in args:
        i = args.index("--preview"); prev = args[i + 1]; del args[i:i + 2]
    if "--block" in args:
        i = args.index("--block"); blk = int(args[i + 1]); del args[i:i + 2]
    raw, cell, out = args[0], int(args[1]), args[2]
    block, info = process(raw, cell, out, prev, blk)
    print(f"{raw}: block {block}px; " + "; ".join(info))


SKIN = {(0xe8, 0xb9, 0x8a), (0xb8, 0x86, 0x5a), (0xf6, 0xb0, 0x7a), (0xd8, 0x94, 0x4a)}


def face_width(cell_img):
    """Longest horizontal run of skin-coloured pixels: the face width in a down-facing cell."""
    a = np.array(cell_img)
    best = 0
    for row in a:
        run = 0
        for px in row:
            if px[3] > 0 and (px[0], px[1], px[2]) in SKIN:
                run += 1
                best = max(best, run)
            else:
                run = 0
    return best


def normalize_to_reference(raw_path, ref_processed_path, cell, out_path, preview_path=None):
    """Scale a raw sheet so its down-facing face matches the reference sheet's face width."""
    ref = Image.open(ref_processed_path).convert("RGBA")
    ref_face = face_width(ref.crop((0, 0, cell, cell)))
    img = Image.open(raw_path).convert("RGBA")
    arr = np.array(img)
    block = round((block_size(arr, 1)[0][1] + block_size(arr, 0)[0][1]) / 2)
    first = snap_palette(to_logical(img, block))
    cells = split_cells(first)
    face = face_width(cells[0])
    factor = ref_face / face if face else 1.0
    eff_block = block / factor
    logical = snap_palette(img.resize((round(img.width / eff_block), round(img.height / eff_block)), Image.BOX))
    cells = split_cells(logical)
    sheet = Image.new("RGBA", (cell * len(cells), cell))
    sizes = []
    for i, c in enumerate(cells):
        sheet.paste(c, (i * cell + (cell - c.width) // 2, cell - c.height))
        sizes.append(f"{c.width}x{c.height}")
    sheet.save(out_path)
    if preview_path:
        s = 4
        big = sheet.resize((sheet.width * s, sheet.height * s), Image.NEAREST)
        bg = Image.new("RGBA", big.size, (90, 90, 90, 255)); bg.paste(big, (0, 0), big); bg.save(preview_path)
    return ref_face, face, factor, sizes


def fit_sheet(raw_path, out_path, target_h=None, target_w=None, cell=None, align="bottom", frames=None):
    """Scale a raw image so its opaque bounding box is target_h tall (or target_w wide), snap the
    palette, then either crop to the box or split on transparent gaps into equal cells."""
    img = Image.open(raw_path).convert("RGBA")
    a = np.array(img)[..., 3] > 127
    ys, xs = np.where(a)
    bw, bh = xs.max() - xs.min() + 1, ys.max() - ys.min() + 1
    factor = (target_h / bh) if target_h else (target_w / bw)
    small = img.resize((max(1, round(img.width * factor)), max(1, round(img.height * factor))), Image.BOX)
    logical = snap_palette(small)
    if not cell:
        out = logical.crop(logical.getbbox())
        out.save(out_path)
        return factor, [f"{out.width}x{out.height}"]
    cells = split_cells_n(logical, frames) if frames else split_cells(logical)
    sheet = Image.new("RGBA", (cell * len(cells), cell))
    sizes = []
    for i, c in enumerate(cells):
        y = cell - c.height if align == "bottom" else (cell - c.height) // 2
        sheet.paste(c, (i * cell + (cell - c.width) // 2, max(0, y)))
        sizes.append(f"{c.width}x{c.height}")
    sheet.save(out_path)
    return factor, sizes


def split_cells_n(img, n):
    """Split a strip into exactly n cells. Cuts sit at the emptiest column near each expected
    boundary, so touching frames still separate cleanly."""
    a = np.array(img)[..., 3] > 0
    occupancy = a.sum(axis=0)
    w = img.width
    cuts = [0]
    for k in range(1, n):
        expected = int(w * k / n)
        lo, hi = max(1, expected - w // (n * 3)), min(w - 1, expected + w // (n * 3))
        cuts.append(lo + int(np.argmin(occupancy[lo:hi])))
    cuts.append(w)
    out = []
    for i in range(n):
        c = img.crop((cuts[i], 0, cuts[i + 1], img.height))
        bb = c.getbbox()
        out.append(c.crop(bb) if bb else c)
    return out
