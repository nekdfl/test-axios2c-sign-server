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
import tarfile
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


_BIN_COMMIT_RE = re.compile(r"(?:^|/)bin/([0-9a-f]{40})(?:/|$)")


def detect_git_id_from_tar_gz(path: Path) -> str:
    """
    Detect the VSCodium server commit id from the tarball contents.

    VSCodium expects binaries under ~/.vscodium-server/bin/<git-id>/...
    The archive typically contains paths with /bin/<40-hex>/.
    """
    try:
        with tarfile.open(path, mode="r:gz") as tf:
            for m in tf:
                mm = _BIN_COMMIT_RE.search(m.name)
                if mm:
                    return mm.group(1)
    except (tarfile.TarError, OSError):
        return ""
    return ""


def with_git_id(name: str, git_id: str) -> str:
    """
    Insert git_id into a tarball name, preserving compound suffixes like .tar.gz.

    Examples:
      vscodium-reh-linux-x64-1.100.2.tar.gz -> vscodium-reh-linux-x64-1.100.2-<git>.tar.gz
    """
    if not git_id:
        return name
    p = Path(name)
    suffixes = "".join(p.suffixes)
    stem = p.name[: -len(suffixes)] if suffixes else p.stem
    return f"{stem}-{git_id}{suffixes}"


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

    tmp = outdir / f".{name}.download"
    print(f"Релиз {tag}", flush=True)
    print(f"GET {url}", flush=True)
    fetch_file(url, tmp)

    git_id = detect_git_id_from_tar_gz(tmp)
    save_name = with_git_id(name, git_id)
    dest = outdir / save_name
    try:
        tmp.replace(dest)
    except OSError:
        # Cross-device fallback
        dest.write_bytes(tmp.read_bytes())
        try:
            tmp.unlink()
        except OSError:
            pass

    if git_id:
        print(f"git-id: {git_id}", flush=True)
    print(f"Сохранено: {dest}", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
