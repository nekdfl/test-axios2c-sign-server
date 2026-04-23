#!/usr/bin/env python3
"""
Последний релиз VSCodium для Windows: ZIP portable, Setup (система), UserSetup (пользователь).
Стандартная библиотека.

  python3 scripts/vscodium_desktop_download.py [--arch x64|arm64] [--outdir DIR]
"""

import argparse
import json
import re
import sys
import urllib.request
from pathlib import Path
from typing import Tuple

from vscodium_common import install_urllib_proxy_from_cfg

install_urllib_proxy_from_cfg()

API = "https://api.github.com/repos/VSCodium/vscodium/releases/latest"
UA = "vscodium-desktop-download/1.0"


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


def resolve_urls(arch: str) -> Tuple[str, str, str, str]:
    rel = fetch_json(API)
    tag = rel.get("tag_name") or "?"
    assets = rel.get("assets") or []
    zip_re = re.compile(rf"^VSCodium-win32-{re.escape(arch)}-.*\.zip$")
    sys_re = re.compile(rf"^VSCodiumSetup-{re.escape(arch)}-.*\.exe$")
    usr_re = re.compile(rf"^VSCodiumUserSetup-{re.escape(arch)}-.*\.exe$")
    uz = ss = uu = None
    for a in assets:
        n = a.get("name") or ""
        if uz is None and zip_re.match(n):
            uz = a.get("browser_download_url")
        if ss is None and sys_re.match(n):
            ss = a.get("browser_download_url")
        if uu is None and usr_re.match(n):
            uu = a.get("browser_download_url")
        if uz and ss and uu:
            break
    if not uz or not ss or not uu:
        raise SystemExit("Не найдены все три ассета (zip / Setup / UserSetup) в последнем релизе.")
    return uz, ss, uu, tag


def leaf_name(url: str) -> str:
    from urllib.parse import urlparse

    path = urlparse(url).path.rstrip("/")
    return path.rsplit("/", 1)[-1] if path else ""


def main() -> int:
    p = argparse.ArgumentParser(description="Скачать последний VSCodium (Windows): zip + установщики.")
    p.add_argument("--arch", choices=("x64", "arm64"), default="x64", help="x64 = x86_64")
    p.add_argument("--outdir", type=Path, default=Path("."), help="каталог сохранения")
    args = p.parse_args()
    outdir = args.outdir.expanduser().resolve()
    outdir.mkdir(parents=True, exist_ok=True)

    uz, ss, uu, tag = resolve_urls(args.arch)
    print(f"Релиз {tag}", flush=True)
    for url in (uz, ss, uu):
        name = leaf_name(url)
        if not name:
            print(f"Не удалось имя файла из URL: {url}", file=sys.stderr)
            return 1
        dest = outdir / name
        print(f"GET {url}", flush=True)
        fetch_file(url, dest)
        print(f"Сохранено: {dest}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
