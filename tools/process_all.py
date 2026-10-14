#!/usr/bin/env python3
"""Process every raw asset in assets/raw into assets/processed using per-asset rules.

usage: process_all.py [--only name_substring] [--force]
Skips outputs that are newer than their raw file unless --force.
"""
import os
import re
import sys
import time
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
import numpy as np
from analyze_stylelock import block_size, snap_palette, to_logical
from process_sheet import normalize_to_reference, process as sheet, fit_sheet
from process_grid import process as grid, key_black

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "assets" / "raw"
OUT = ROOT / "assets" / "processed"
HERO_REF = OUT / "hero" / "hero_temujin_idle_3dir.png"

# name -> (kind, params). Kinds:
#   sheet_norm  : multi-cell sheet, face-normalised to the hero idle, cell size
#   sheet       : multi-cell sheet split on transparent gaps, cell size
#   grid        : rows, cols, align ("bottom" | "center"), optional fixed cell
#   tiles       : opaque N x N tile grid resized so each tile is 32 px
#   single      : one object, native density, cropped
#   portrait    : one bust, native density, padded to 128 x 128
#   cutscene    : opaque illustration, native density
RULES = {
    # hero poses: face-normalised to the idle sheet so his head never changes size
    "hero_temujin_idle_3dir": ("sheet", 96),
    "hero_temujin_sword_3dir": ("sheet_norm", 96),
    "hero_temujin_bow_3dir": ("sheet_norm", 96),
    "hero_temujin_hurt_3dir": ("sheet_norm", 96),
    "hero_temujin_boy_idle_3dir": ("sheet_norm", 96),
    # everything else: scaled so the tallest cell is target_h logical px (hero is 66)
    "hero_temujin_roll_side": ("fit", 96, 48, None),
    "hero_temujin_walk_side_6f": ("fit", 96, 66, None),
    "hero_temujin_walk_down_6f": ("fit", 96, 66, None),
    "hero_temujin_walk_up_6f": ("fit", 96, 66, None),
    "animal_dog_run_side_4f": ("fit", 48, 30, None),
    "enemy_tayichiud_sword_walk_side_6f": ("fit", 96, 70, None),
    "enemy_tayichiud_sword_walk_down_6f": ("fit", 96, 70, None),
    "enemy_tayichiud_sword_walk_up_6f": ("fit", 96, 70, None),
    "enemy_tayichiud_archer_walk_side_6f": ("fit", 96, 70, None),
    "enemy_tayichiud_archer_walk_down_6f": ("fit", 96, 70, None),
    "enemy_tayichiud_archer_walk_up_6f": ("fit", 96, 70, None),
    "enemy_hunter_walk_side_6f": ("fit", 96, 70, None),
    "enemy_hunter_walk_down_6f": ("fit", 96, 70, None),
    "enemy_hunter_walk_up_6f": ("fit", 96, 70, None),
    "boss_begter_walk_side_6f": ("fit", 96, 66, None),
    "boss_begter_walk_down_6f": ("fit", 96, 66, None),
    "boss_begter_walk_up_6f": ("fit", 96, 66, None),
    "boss_targhutai_walk_side_6f": ("fit", 192, 130, None),
    "boss_targhutai_walk_down_6f": ("fit", 192, 130, None),
    "boss_targhutai_walk_up_6f": ("fit", 192, 130, None),
    "hero_temujin_death_2cells": ("fit", 96, 60, None),
    "hero_temujin_mounted_idle_3dir": ("fit", 144, 100, None),
    "hero_temujin_mounted_gallop_side": ("fit", 144, 96, None),
    "comp_hoelun_idle_3dir": ("fit", 96, 70, None),
    "comp_boorchu_idle_3dir": ("fit", 96, 70, None),
    "npc_sorkanshira_idle_3dir": ("fit", 96, 68, None),
    "enemy_tayichiud_sword_idle_3dir": ("fit", 96, 70, None),
    "enemy_tayichiud_sword_attack_3dir": ("fit", 96, 70, None),
    "enemy_tayichiud_archer_idle_3dir": ("fit", 96, 70, None),
    "enemy_tayichiud_archer_attack_3dir": ("fit", 96, 70, None),
    "enemy_hunter_idle_3dir": ("fit", 96, 70, None),
    "boss_begter_idle_3dir": ("fit", 96, 66, None),
    "boss_begter_attack_down": ("fit", 96, 66, None),
    "boss_targhutai_idle_3dir": ("fit", 192, 130, None),
    "boss_targhutai_whip_down": ("fit", 192, 130, None),
    "boss_targhutai_horn_down": ("fit", 192, 130, None),
    "npc_herder_man_idle_3dir": ("fit", 96, 70, None),
    "npc_herder_woman_idle_3dir": ("fit", 96, 68, None),
    "npc_child_idle_3dir": ("fit", 96, 48, None),
    "animal_horse_bay_idle_3dir": ("fit", 144, 88, None),
    "animal_horse_bay_gallop_side": ("fit", 144, 80, None),
    "animal_small_grid01": ("grid", 4, 4, "bottom", None),
    "tile_steppe_summer_grid01": ("tiles", 4),
    "tile_forest_grid01": ("tiles", 4),
    "tile_camp_ground_grid01": ("tiles", 4),
    "tile_water_strip": ("tiles_rc", 2, 4),
    "prop_ger_medium": ("single",),
    "prop_ger_small": ("fit", None, 118, None),
    "prop_ger_enemy": ("fit", None, 146, None),
    "prop_oxcart": ("fit", None, None, 100),
    "prop_small_grid01": ("grid", 4, 4, "bottom", None),
    "prop_hitching_line": ("fit", None, None, 128),
    "prop_fence_pieces": ("grid", 2, 4, "bottom", None),
    "prop_haystack": ("fit", None, 64, None),
    "prop_ovoo": ("fit", None, 96, None),
    "prop_banner_10states": ("fit", 128, 120, None),
    "prop_torch_4f": ("fit", 64, 60, None),
    "prop_boulders_3": ("fit", 96, 72, None),
    "prop_larch_trees_3": ("fit", 128, 110, None),
    "prop_pine_trees_2": ("fit", 128, 110, None),
    "prop_bush_grass_grid": ("grid", 4, 4, "bottom", None),
    "item_weapons_grid01": ("grid", 4, 4, "center", None),
    "item_quest_grid01": ("grid", 4, 4, "center", None),
    "ui_hud_grid": ("grid", 4, 4, "center", None),
    "ui_companion_slot": ("fit", None, 40, None),
    "ui_dialog_9slice": ("fit", None, 48, None),
    "ui_menu_panel_9slice": ("fit", None, 48, None),
    "ui_button_3states": ("fit", 48, 44, None),
    "ui_title_logo": ("fit", None, None, 400),
    "ui_title_background": ("cutscene",),
    "vfx_slash_4f": ("grid", 1, 4, "center", None),
    "vfx_small_fx_grid": ("grid", 4, 4, "center", None),
    "vfx_hoofdust_4f": ("grid", 1, 4, "center", None),
    "vfx_torch_light": ("cutscene",),
}
for n in ("portrait_temujin_boy_neutral", "portrait_temujin_youth_neutral", "portrait_temujin_youth_intense",
          "portrait_hoelun_neutral", "portrait_begter_neutral", "portrait_targhutai_neutral", "portrait_boorchu_neutral"):
    RULES[n] = ("portrait",)
for n in ("cutscene_01_poisoned_feast", "cutscene_02_abandoned_camp", "cutscene_03_fish_and_begter", "cutscene_04_nine_days_forest"):
    RULES[n] = ("cutscene",)


def detect_block(img):
    arr = np.array(img)
    return round((block_size(arr, 1)[0][1] + block_size(arr, 0)[0][1]) / 2)


def native(img):
    return snap_palette(to_logical(img, detect_block(img)))


KEY_BLACK = {"hero_temujin_boy_idle_3dir"}  # raw files that came with a flat black background instead of alpha


def run_one(raw, out, rule):
    kind = rule[0]
    out.parent.mkdir(parents=True, exist_ok=True)
    if raw.stem in KEY_BLACK:
        tmp = OUT / "_tmp" / raw.name
        tmp.parent.mkdir(parents=True, exist_ok=True)
        key_black(Image.open(raw)).save(tmp)
        raw = tmp
    if kind == "sheet_norm":
        r = normalize_to_reference(str(raw), str(HERO_REF), rule[1], str(out))
        return f"norm x{r[2]:.2f} cells {r[3]}"
    if kind == "sheet":
        block, info = sheet(str(raw), rule[1], str(out))
        return f"block {block} " + "; ".join(info)
    if kind == "fit":
        _, cell, th, tw = rule
        m = re.search(r"_(\d+)f$", raw.stem)
        frames = int(m.group(1)) if m else None
        f, sizes = fit_sheet(str(raw), str(out), target_h=th, target_w=tw, cell=cell, frames=frames)
        return f"fit x{f:.2f} {sizes}"
    if kind == "grid":
        _, rows, cols, align, cell = rule
        b, c, mw, mh = grid(str(raw), rows, cols, str(out), cell=cell, align=align)
        return f"block {b} cell {c} max {mw}x{mh}"
    if kind == "tiles":
        n = rule[1]
        img = Image.open(raw).convert("RGBA").resize((32 * n, 32 * n), Image.BOX)
        snap_palette(img).save(out)
        return f"{n}x{n} tiles at 32 px"
    if kind == "tiles_rc":
        rows, cols = rule[1], rule[2]
        img = Image.open(raw).convert("RGBA").resize((32 * cols, 32 * rows), Image.BOX)
        snap_palette(img).save(out)
        return f"{rows}x{cols} tiles at 32 px"
    if kind == "single":
        img = native(Image.open(raw).convert("RGBA"))
        bb = img.getbbox()
        img = img.crop(bb) if bb else img
        img.save(out)
        return f"{img.width}x{img.height}"
    if kind == "portrait":
        img = native(Image.open(raw).convert("RGBA"))
        bb = img.getbbox()
        img = img.crop(bb) if bb else img
        if img.width > 128 or img.height > 128:
            img.thumbnail((128, 128), Image.BOX)
            img = snap_palette(img)
        canvas = Image.new("RGBA", (128, 128))
        canvas.paste(img, ((128 - img.width) // 2, 128 - img.height))
        canvas.save(out)
        return f"bust {img.width}x{img.height} in 128"
    if kind == "cutscene":
        img = native(Image.open(raw).convert("RGBA"))
        img.save(out)
        return f"{img.width}x{img.height}"
    return "unknown rule"


def main():
    only = None
    force = "--force" in sys.argv
    if "--only" in sys.argv:
        only = sys.argv[sys.argv.index("--only") + 1]
    done = skipped = failed = 0
    for cat in sorted(p for p in RAW.iterdir() if p.is_dir() and not p.name.startswith("_")):
        for raw in sorted(cat.glob("*.png")):
            name = raw.stem
            if only and only not in name:
                continue
            rule = rule_for(name)
            if not rule:
                print(f"  ?  {name}: no rule, skipped")
                continue
            out = OUT / cat.name / f"{name}.png"
            if out.exists() and out.stat().st_mtime > raw.stat().st_mtime and not force:
                skipped += 1
                continue
            try:
                t0 = time.time()
                info = run_one(raw, out, rule)
                print(f"  ok {name}: {info} ({time.time() - t0:.1f}s)")
                done += 1
            except Exception as e:  # noqa: BLE001
                print(f"  !! {name}: {e}")
                failed += 1
    print(f"processed {done}, skipped {skipped} up to date, failed {failed}")




def rule_for(name: str):
    """Fallback rules by name pattern for assets added after the P0 table."""
    if name in RULES:
        return RULES[name]
    if name.startswith("cutscene_"):
        return ("cutscene",)
    if name.startswith("portrait_"):
        return ("portrait",)
    if name.startswith("tile_"):
        return ("tiles", 4)
    if name.endswith("_grid") or "_grid" in name and name.startswith("prop_"):
        rows, cols = (2, 4) if ("wall" in name or "palisade" in name) else (4, 4)
        return ("grid", rows, cols, "bottom", None)
    if name.startswith("prop_") and name.endswith("_4f"):
        return ("grid", 1, 4, "bottom", None)
    if name == "prop_merkit_standard":
        return ("fit", None, 120, None)
    if name == "prop_golden_tent":
        return ("fit", None, 150, None)
    if name == "prop_wool_cart":
        return ("fit", None, None, 100)
    if name.startswith("prop_"):
        return ("single",)
    mounted = "mounted" in name
    big = any(name.startswith("boss_" + b) for b in ("captain", "chilger", "tatarchief", "senggum", "tayang"))
    if mounted:
        return ("fit", 144, 100, None)
    if big:
        return ("fit", 192, 130, None)
    if name.startswith("hero_"):
        return ("fit", 96, 66, None)
    if name.startswith("comp_shigi"):
        return ("fit", 96, 50, None)
    if name.startswith(("enemy_", "comp_", "npc_", "boss_")):
        return ("fit", 96, 70, None)
    return None

if __name__ == "__main__":
    main()
