#!/usr/bin/env python3
"""
Скачивание VSIX из Open VSX по списку (publisher.extension@version).
Стандартная библиотека; без curl.

  python3 scripts/openvsx_download_vsix.py [список] [каталог_vsix]
"""

import json
import pathlib
import sys
import urllib.error
import urllib.request

UA = "openvsx-download-vsix/1.0"


def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())


def fetch_bytes(url: str) -> bytes:
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=120) as r:
        return r.read()


def main() -> int:
    list_path = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "vscodium-extensions.txt")
    out_dir = pathlib.Path(sys.argv[2] if len(sys.argv) > 2 else "vsix")
    if not list_path.is_file():
        print(f"Файл списка не найден: {list_path}", file=sys.stderr)
        return 1
    out_dir.mkdir(parents=True, exist_ok=True)

    for raw in list_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "@" not in line:
            print("пропуск (нет @):", line, file=sys.stderr)
            continue
        ext_id, _, ver = line.partition("@")
        ext_id, ver = ext_id.strip(), ver.strip()
        if "." not in ext_id:
            print("пропуск (ожидался publisher.extension):", line, file=sys.stderr)
            continue
        dot = ext_id.index(".")
        namespace, name = ext_id[:dot], ext_id[dot + 1:]
        meta_url = f"https://open-vsx.org/api/{namespace}/{name}/{ver}"
        try:
            meta = fetch_json(meta_url)
            dl = meta["files"]["download"]
            leaf = dl.rsplit("/", 1)[-1]
            dest = out_dir / leaf
            data = fetch_bytes(dl)
            dest.write_bytes(data)
            print(dest)
        except urllib.error.HTTPError as e:
            print(f"HTTP {e.code}: {line}", file=sys.stderr)
        except Exception as e:
            print(f"ошибка {line}: {e}", file=sys.stderr)

    print(f"Готово. Каталог: {out_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
