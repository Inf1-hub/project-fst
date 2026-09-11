#!/usr/bin/env python3
"""Remove the painted transparency-checkerboard background from a generated asset.

The image generator bakes a light gray/white checkerboard to represent "transparent"
but exports RGB. We key out background pixels that are (a) light and low-saturation and
(b) connected to the image border, so interior light details are preserved. Then we trim
the anti-alias halo, feather, and auto-crop to the content bounds (bottom edge = ground
contact for the game's bottom-anchored props).

Usage: dekey_asset.py IN.png OUT.png [--light 170] [--sat 30] [--pad 6]
"""
import sys
import argparse
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage


def dekey(in_path: str, out_path: str, light: int = 170, sat: int = 30, pad: int = 6) -> None:
    img = Image.open(in_path).convert("RGB")
    arr = np.asarray(img).astype(np.int16)
    mx = np.max(arr, axis=2)
    mn = np.min(arr, axis=2)
    # Checkerboard: light and near-neutral (low saturation).
    bg_like = (mn >= light) & ((mx - mn) <= sat)
    # Detect the two checker tones from border background pixels, then remove those tones
    # globally (kills enclosed pockets the border flood fill can't reach).
    border_mask = np.zeros(bg_like.shape, bool)
    border_mask[0, :] = border_mask[-1, :] = border_mask[:, 0] = border_mask[:, -1] = True
    sample = arr[border_mask & bg_like]
    global_bg = np.zeros(bg_like.shape, bool)
    if len(sample) > 50:
        bright = sample.mean(axis=1)
        split = (bright.min() + bright.max()) / 2.0
        tones = []
        for grp in (sample[bright <= split], sample[bright > split]):
            if len(grp) > 0:
                tones.append(grp.mean(axis=0))
        for c in tones:
            dist = np.max(np.abs(arr - c.reshape(1, 1, 3)), axis=2)
            global_bg |= (dist <= 22)
    # Border-connected background captures the anti-alias halo around the object.
    labels, _ = ndimage.label(bg_like)
    border = np.concatenate([labels[0, :], labels[-1, :], labels[:, 0], labels[:, -1]])
    border_labels = set(int(v) for v in np.unique(border) if v != 0)
    connected = np.isin(labels, list(border_labels)) if border_labels else np.zeros_like(bg_like)
    background = connected | (global_bg & bg_like)
    fg = ~background
    # Trim 1px anti-alias fringe, then feather the alpha slightly.
    fg = ndimage.binary_erosion(fg, iterations=1)
    alpha = (fg * 255).astype(np.uint8)
    alpha_img = Image.fromarray(alpha, "L").filter(ImageFilter.GaussianBlur(0.6))
    out = np.dstack([np.asarray(img), np.asarray(alpha_img)])
    result = Image.fromarray(out, "RGBA")
    # Auto-crop to content bounds with padding.
    bbox = result.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if bbox:
        x0, y0, x1, y1 = bbox
        x0 = max(0, x0 - pad); y0 = max(0, y0 - pad)
        x1 = min(result.width, x1 + pad); y1 = min(result.height, y1 + pad)
        result = result.crop((x0, y0, x1, y1))
    result.save(out_path)
    a = result.getchannel("A").getextrema()
    print(f"{out_path} size={result.size} alpha={a}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("in_path")
    ap.add_argument("out_path")
    ap.add_argument("--light", type=int, default=170)
    ap.add_argument("--sat", type=int, default=30)
    ap.add_argument("--pad", type=int, default=6)
    args = ap.parse_args()
    dekey(args.in_path, args.out_path, args.light, args.sat, args.pad)
