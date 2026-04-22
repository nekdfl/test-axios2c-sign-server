#!/usr/bin/env python3
"""
Скачивание архива vscodium-server (Linux) из GitHub Releases.

  python3 scripts/vscodium_server_download.py [--arch x64|arm64|armhf] [--flavor reh|reh-web] [--outdir DIR]

Переменные окружения (как в bash-скрипте): ARCH, FLAVOR, OUTDIR — подставляются как значения по умолчанию.
"""

import argparse
import json
import os
import re
import sys
import urllib.request
from pathlib import Path
from typing import Pattern

API = "https://api.github.com/repos/VSCodium/vscodium/releases/latest"
UA = "vscodium-server-download/1.0"


def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())


def fetch_file(url: str, dest: Path) -> None:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    dest.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(req, timeout=600) as resp, dest.open("wb") as out:
        while True:
            chunk = resp.read(1 << 20)
            if not chunk:
                break
            out.write(chunk)


def pattern_for(flavor: str, arch: str) -> Pattern:
    if flavor == "reh":
        return re.compile(rf"^vscodium-reh-linux-{re.escape(arch)}-.*\.tar\.gz$")
    if flavor == "reh-web":
        return re.compile(rf"^vscodium-reh-web-linux-{re.escape(arch)}-.*\.tar\.gz$")
    raise SystemExit(f"Неизвестный FLAVOR={flavor} (reh|reh-web)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "--arch",
        default=os.environ.get("ARCH", "x64"),
        choices=("x64", "arm64", "armhf"),
    )
    ap.add_argument(
        "--flavor",
        default=os.environ.get("FLAVOR", "reh"),
        choices=("reh", "reh-web"),
    )
    ap.add_argument("--outdir", type=Path, default=Path(os.environ.get("OUTDIR", ".")))
    args = ap.parse_args()

    pat = pattern_for(args.flavor, args.arch)
    rel = fetch_json(API)
    tag = rel.get("tag_name", "?")
    url = name = None
    for a in rel.get("assets") or []:
        n = a.get("name") or ""
        if pat.match(n):
            url = a.get("browser_download_url")
            name = n
            break
    if not url or not name:
        print(f"Не найден asset (FLAVOR={args.flavor} ARCH={args.arch})", file=sys.stderr)
        return 1

    outdir = args.outdir.expanduser().resolve()
    outdir.mkdir(parents=True, exist_ok=True)
    dest = outdir / name
    print(f"Релиз {tag}", flush=True)
    print(f"GET {url}", flush=True)
    fetch_file(url, dest)
    print(f"Сохранено: {dest}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
