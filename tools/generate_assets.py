#!/usr/bin/env python3
"""Batch-generate the Anda asset queue with the OpenAI Images API.

Reads the queue from docs/chatgpt-oneshot-prompt.txt, builds one prompt per item,
calls the Images API (edits endpoint with a style reference image where one exists,
otherwise generations), and saves PNGs into assets/raw/<category>/<name>.png.

usage:
  generate_assets.py --dry-run                 # list items, sizes, qualities, estimated cost; no API calls
  generate_assets.py --list-models             # show image models the key can use (free)
  generate_assets.py --only 6                  # one item
  generate_assets.py --only 6-10,20            # ranges
  generate_assets.py --max-usd 14 --workers 2  # the whole queue, skipping files that already exist

The key is read from $OPENAI_API_KEY or ~/.config/anda/openai.env (line: OPENAI_API_KEY=...).
"""
import argparse
import base64
import json
import os
import re
import sys
import threading
import time
import urllib.error
import urllib.request
import uuid
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
QUEUE_FILE = ROOT / "docs" / "chatgpt-oneshot-prompt.txt"
RAW = ROOT / "assets" / "raw"
LOG = RAW / "generation_log.jsonl"
KEY_FILE = Path.home() / ".config" / "anda" / "openai.env"
API = "https://api.openai.com/v1"

# USD per million tokens. gpt-image-1 list prices as of 2025; adjust if OpenAI changes them.
PRICES = {
    "gpt-image-1": {"text_in": 5.0, "image_in": 10.0, "image_out": 40.0},
    "gpt-image-1-mini": {"text_in": 2.0, "image_in": 2.5, "image_out": 8.0},
}
# Rough per-image estimates for the dry run (USD).
EST = {("high", "1024x1024"): 0.167, ("high", "1536x1024"): 0.25,
       ("medium", "1024x1024"): 0.042, ("medium", "1536x1024"): 0.063,
       ("low", "1024x1024"): 0.011, ("low", "1536x1024"): 0.016}

CATEGORY = {"hero": "hero", "comp": "companions", "npc": "npcs", "enemy": "enemies", "boss": "bosses",
            "animal": "animals", "tile": "tiles", "prop": "props", "item": "items", "ui": "ui",
            "portrait": "portraits", "cutscene": "cutscenes", "vfx": "vfx"}
HIGH_QUALITY = {"hero", "companions", "npcs", "enemies", "bosses", "portraits", "cutscenes", "animals"}
LANDSCAPE_NAMES = {"ui_title_logo", "ui_title_background", "prop_banner_10states"}
OPAQUE_NAMES = {"ui_title_background", "vfx_torch_light"}
OPAQUE_CATEGORIES = {"tiles", "cutscenes"}
REFERENCE = {  # style reference image per category, relative to assets/raw
    "default": "hero/hero_temujin_idle_3dir.png",
    "props": "props/prop_ger_medium.png",
    "tiles": "tiles/tile_steppe_summer_grid01.png",
}

API_PREAMBLE = (
    "Use the attached image only as the reference for art style, pixel density, outline weight, palette and, "
    "when the subject is a person, for the character design. Do not reproduce the attached image. "
    "Create a NEW image of the ASSET described at the end, following every rule below.\n\n"
)


def load_key():
    key = os.environ.get("OPENAI_API_KEY")
    if not key and KEY_FILE.exists():
        for line in KEY_FILE.read_text().splitlines():
            if line.startswith("OPENAI_API_KEY="):
                key = line.split("=", 1)[1].strip()
    if not key:
        sys.exit("no API key: set OPENAI_API_KEY or write it to " + str(KEY_FILE))
    return key


def parse_queue():
    text = QUEUE_FILE.read_text()
    head = text[text.index("== STYLE"):text.index("== ASSET QUEUE")]
    head = head.replace("== STYLE (applies to every image) ==", "== STYLE ==")
    items = []
    section_note = ""
    for line in text[text.index("== ASSET QUEUE"):].splitlines():
        m = re.match(r"^(\d+)\. ([a-z0-9_]+) \| (.+)$", line)
        if m:
            num, name, rest = int(m.group(1)), m.group(2), m.group(3)
            parts = [p.strip() for p in rest.split("|")]
            framing, desc = (parts[0], " | ".join(parts[1:])) if len(parts) > 1 else ("", parts[0])
            if section_note:
                framing = (framing + ". " + section_note).strip(". ")
            items.append({"num": num, "name": name, "framing": framing, "desc": desc})
        elif re.match(r"^[A-Z][A-Z ]+(\(.*\))?$", line.strip()):
            m2 = re.match(r"^[A-Z][A-Z ]+\((.*)\)$", line.strip())
            section_note = m2.group(1) if m2 else ""
    return head, items


def plan(item, args):
    name = item["name"]
    cat = CATEGORY.get(name.split("_")[0], "props")
    landscape = ("3DIR" in item["framing"] or "1536x1024" in item["framing"] or cat == "cutscenes"
                 or name in LANDSCAPE_NAMES)
    size = "1536x1024" if landscape else "1024x1024"
    opaque = cat in OPAQUE_CATEGORIES or name in OPAQUE_NAMES or "opaque" in item["framing"].lower()
    quality = args.quality or ("high" if cat in HIGH_QUALITY else "medium")
    ref = RAW / REFERENCE.get(cat, REFERENCE["default"])
    m = re.search(r"ref=(\S+)", item["framing"])
    if m:
        ref = RAW / m.group(1).rstrip(".,;")
        item["framing"] = item["framing"].replace(m.group(0), "").strip(" .")
    q = re.search(r"q=(low|medium|high)", item["framing"])
    if q:
        quality = q.group(1) if not args.quality else quality
        item["framing"] = item["framing"].replace(q.group(0), "").strip(" .")
    if args.fidelity == "none":
        ref = Path("/nonexistent")
    out = RAW / cat / f"{name}{args.suffix}.png"
    return {"cat": cat, "size": size, "background": "opaque" if opaque else "transparent",
            "quality": quality, "ref": ref if ref.exists() else None, "out": out,
            "fidelity": "low" if args.fidelity == "low" else "high"}


def build_prompt(head, item, p):
    framing = item["framing"] or "fills the canvas"
    asset = (f"ASSET: {item['name']}\nFRAMING: {framing}\nSUBJECT: {item['desc']}\n"
             f"Canvas {p['size']}, {'opaque background' if p['background'] == 'opaque' else 'transparent background PNG'}. "
             "No text, no labels, no watermark, no grid lines.")
    pre = API_PREAMBLE if p["ref"] else ""
    return pre + head.strip() + "\n\n" + asset


def multipart(fields, files):
    boundary = "----anda" + uuid.uuid4().hex
    body = bytearray()
    for k, v in fields.items():
        body += f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"\r\n\r\n{v}\r\n".encode()
    for k, path in files:
        body += (f"--{boundary}\r\nContent-Disposition: form-data; name=\"{k}\"; filename=\"{path.name}\"\r\n"
                 f"Content-Type: image/png\r\n\r\n").encode()
        body += path.read_bytes() + b"\r\n"
    body += f"--{boundary}--\r\n".encode()
    return bytes(body), f"multipart/form-data; boundary={boundary}"


def call_api(key, prompt, p, model, attempt=0):
    fields = {"model": model, "prompt": prompt, "n": "1", "size": p["size"], "quality": p["quality"],
              "background": p["background"], "output_format": "png"}
    if p["ref"]:
        if model.startswith("gpt-image-1") or model == "chatgpt-image-latest":
            fields["input_fidelity"] = p["fidelity"]
        body, ctype = multipart(fields, [("image[]", p["ref"])])
        url = API + "/images/edits"
    else:
        body, ctype = json.dumps({**fields, "n": 1}).encode(), "application/json"
        url = API + "/images/generations"
    req = urllib.request.Request(url, data=body, method="POST",
                                 headers={"Authorization": f"Bearer {key}", "Content-Type": ctype})
    try:
        with urllib.request.urlopen(req, timeout=300) as r:
            return json.loads(r.read())
    except urllib.error.HTTPError as e:
        msg = e.read().decode(errors="replace")[:600]
        if e.code in (429, 500, 502, 503, 504) and attempt < 4:
            wait = [10, 30, 60, 120][attempt]
            print(f"  HTTP {e.code}, retrying in {wait}s: {msg[:120]}", flush=True)
            time.sleep(wait)
            return call_api(key, prompt, p, model, attempt + 1)
        raise RuntimeError(f"HTTP {e.code}: {msg}")


def cost_of(usage, model):
    pr = PRICES.get(model, PRICES["gpt-image-1"])
    det = usage.get("input_tokens_details", {})
    return (det.get("text_tokens", 0) * pr["text_in"] + det.get("image_tokens", 0) * pr["image_in"]
            + usage.get("output_tokens", 0) * pr["image_out"]) / 1e6


def list_models(key):
    req = urllib.request.Request(API + "/models", headers={"Authorization": f"Bearer {key}"})
    with urllib.request.urlopen(req, timeout=60) as r:
        ids = sorted(m["id"] for m in json.loads(r.read())["data"])
    print("\n".join(i for i in ids if "image" in i or "dall" in i))


def parse_only(spec):
    nums = set()
    for part in spec.split(","):
        part = part.strip()
        if "-" in part:
            a, b = part.split("-")
            nums.update(range(int(a), int(b) + 1))
        elif part:
            nums.add(int(part))
    return nums


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--list-models", action="store_true")
    ap.add_argument("--only", help="item numbers, e.g. 6-10,20")
    ap.add_argument("--model", default="gpt-image-2.5-flare")
    ap.add_argument("--quality", choices=["low", "medium", "high"], help="override quality for every item")
    ap.add_argument("--max-usd", type=float, default=8.0, help="stop scheduling new items past this spend")
    ap.add_argument("--workers", type=int, default=2)
    ap.add_argument("--force", action="store_true", help="regenerate even if the output file exists")
    ap.add_argument("--suffix", default="", help="append to output file names, e.g. _test")
    ap.add_argument("--fidelity", choices=["high", "low", "none"], default="high",
                    help="reference image fidelity for the edits endpoint; none = generations endpoint, no reference")
    args = ap.parse_args()

    if args.list_models:
        list_models(load_key())
        return

    head, items = parse_queue()
    only = parse_only(args.only) if args.only else None
    todo = []
    for it in items:
        if only and it["num"] not in only:
            continue
        p = plan(it, args)
        if p["out"].exists() and not args.force:
            continue
        todo.append((it, p))

    est = sum(EST[(p["quality"], p["size"])] for _, p in todo)
    print(f"{len(todo)} items to generate, estimated ${est:.2f} at list prices (model {args.model})")
    if args.dry_run:
        for it, p in todo:
            print(f"  {it['num']:3d} {it['name']:38s} {p['cat']:11s} {p['size']:9s} {p['quality']:6s} "
                  f"{p['background']:11s} ref={'yes' if p['ref'] else 'no'}")
        return
    if not todo:
        return

    key = load_key()
    lock = threading.Lock()
    spent = {"usd": 0.0, "done": 0, "failed": 0}
    stop = threading.Event()

    def work(it, p):
        if stop.is_set():
            return "skipped (cap)"
        prompt = build_prompt(head, it, p)
        p["out"].parent.mkdir(parents=True, exist_ok=True)
        p["out"].with_suffix(".prompt.txt").write_text(prompt)
        t0 = time.time()
        try:
            res = call_api(key, prompt, p, args.model)
            img = base64.b64decode(res["data"][0]["b64_json"])
            p["out"].write_bytes(img)
            usage = res.get("usage", {})
            usd = cost_of(usage, args.model)
            with lock:
                spent["usd"] += usd
                spent["done"] += 1
                if spent["usd"] >= args.max_usd:
                    stop.set()
                LOG.open("a").write(json.dumps({"num": it["num"], "name": it["name"], "file": str(p["out"].relative_to(ROOT)),
                                                "size": p["size"], "quality": p["quality"], "usage": usage,
                                                "usd": round(usd, 4), "seconds": round(time.time() - t0, 1),
                                                "ts": time.strftime("%Y-%m-%d %H:%M:%S")}) + "\n")
            return f"ok ${usd:.3f} {time.time() - t0:.0f}s (total ${spent['usd']:.2f})"
        except Exception as e:  # noqa: BLE001
            with lock:
                spent["failed"] += 1
                LOG.open("a").write(json.dumps({"num": it["num"], "name": it["name"], "error": str(e)[:600],
                                                "ts": time.strftime("%Y-%m-%d %H:%M:%S")}) + "\n")
            return f"FAILED {str(e)[:200]}"

    with ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(work, it, p): it for it, p in todo}
        for f in as_completed(futs):
            it = futs[f]
            print(f"  {it['num']:3d} {it['name']:38s} {f.result()}", flush=True)
    print(f"done: {spent['done']} generated, {spent['failed']} failed, ${spent['usd']:.2f} spent"
          + (" (stopped at spend cap)" if stop.is_set() else ""))


if __name__ == "__main__":
    main()
