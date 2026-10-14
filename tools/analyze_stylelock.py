"""Measure the real pixel density of AI generated pixel art and preview it at game size."""
import sys
from collections import Counter
from PIL import Image
import numpy as np

PALETTE_HEX = """1a1423 2e2a3b 243a5e 2b5fa8 7fb2e5 3d7fa6 6fb0c9 c9a84a a88a2f 7a6a24
6b8f3e 3f6a2f 22452b 8c6239 5c3f23 3a2616 b07d4a f1e9d2 d9cfb1 a89f85 e8b98a b8865a
b23a2f 7a2219 f28c28 ffd45c f6f8fb c8d4e3 8a8f9a 565a66 6a3f7a ffffff
d8944a 6a4a3a f6b07a""".split()
PAL = np.array([[int(h[i:i+2], 16) for i in (0, 2, 4)] for h in PALETTE_HEX], dtype=np.float32)


def block_size(arr, axis, thresh=40):
    """Most common spacing between colour changes along an axis = logical pixel size in source px."""
    rgb = arr[..., :3].astype(np.int16)
    if axis == 1:
        diff = np.abs(np.diff(rgb, axis=1)).sum(axis=2)  # H x (W-1)
    else:
        diff = np.abs(np.diff(rgb, axis=0)).sum(axis=2).T  # W x (H-1)
    spacings = Counter()
    for line in diff:
        idx = np.flatnonzero(line > thresh)
        if len(idx) > 1:
            spacings.update((np.diff(idx)).tolist())
    cands = [(n, s) for s, n in spacings.items() if 3 <= s <= 60]
    cands.sort(reverse=True)
    return cands[:6]


def srgb_to_lab(rgb):
    c = rgb / 255.0
    c = np.where(c > 0.04045, ((c + 0.055) / 1.055) ** 2.4, c / 12.92)
    M = np.array([[0.4124, 0.3576, 0.1805], [0.2126, 0.7152, 0.0722], [0.0193, 0.1192, 0.9505]], dtype=np.float32)
    xyz = c @ M.T / np.array([0.95047, 1.0, 1.08883], dtype=np.float32)
    f = np.where(xyz > 0.008856, np.cbrt(xyz), 7.787 * xyz + 16 / 116)
    return np.stack([116 * f[..., 1] - 16, 500 * (f[..., 0] - f[..., 1]), 200 * (f[..., 1] - f[..., 2])], axis=-1)


PAL_LAB = srgb_to_lab(PAL)


def snap_palette(img):
    """Map every opaque pixel to the nearest palette colour in CIELAB space."""
    a = np.array(img.convert("RGBA")).astype(np.float32)
    rgb = a[..., :3].reshape(-1, 3)
    lab = srgb_to_lab(rgb)
    d = ((lab[:, None, :] - PAL_LAB[None, :, :]) ** 2).sum(axis=2)
    out = PAL[d.argmin(axis=1)].reshape(a[..., :3].shape)
    a[..., :3] = out
    a[..., 3] = np.where(a[..., 3] > 170, 255, 0)
    return Image.fromarray(a.astype(np.uint8), "RGBA")


def to_logical(img, px):
    """Nearest neighbour sample at the detected block size."""
    w, h = img.size
    return img.resize((max(1, round(w / px)), max(1, round(h / px))), Image.NEAREST)


def main(path, target_w, target_h, out_prefix):
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)
    print(f"\n== {path} {img.size}")
    bx = block_size(arr, 1)
    by = block_size(arr, 0)
    print("block size candidates x:", bx)
    print("block size candidates y:", by)
    px = bx[0][1]
    alpha = arr[..., 3]
    if alpha.min() < 255:
        ys, xs = np.where(alpha > 127)
        print(f"opaque bbox: x {xs.min()}..{xs.max()} y {ys.min()}..{ys.max()} "
              f"=> {(xs.max()-xs.min()+1)/px:.1f} x {(ys.max()-ys.min()+1)/px:.1f} logical px at block {px}")
    native = to_logical(img, px)
    print("native logical size:", native.size)
    native_snap = snap_palette(native)
    native_snap.save(f"{out_prefix}_native.png")
    # target size via box filter then snap
    tgt = img.resize((target_w, target_h), Image.BOX)
    tgt_snap = snap_palette(tgt)
    tgt_snap.save(f"{out_prefix}_target.png")
    # preview: both at 8x, side by side
    scale = 8
    a = native_snap.resize((native_snap.width * scale, native_snap.height * scale), Image.NEAREST)
    b = tgt_snap.resize((tgt_snap.width * scale, tgt_snap.height * scale), Image.NEAREST)
    sheet = Image.new("RGBA", (a.width + b.width + 40, max(a.height, b.height)), (90, 90, 90, 255))
    sheet.paste(a, (0, 0), a)
    sheet.paste(b, (a.width + 40, 0), b)
    sheet.save(f"{out_prefix}_preview.png")
    print("saved", out_prefix + "_{native,target,preview}.png")


if __name__ == "__main__":
    main(sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4])
