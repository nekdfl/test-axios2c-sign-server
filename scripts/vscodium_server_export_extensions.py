#!/usr/bin/env python3
"""
Экспорт расширений vscodium-server: publisher.name@version.

  python3 scripts/vscodium_server_export_extensions.py [--out FILE] [--server-root DIR]
      [--server-cli PATH] [--extensions-json PATH]

Переменные окружения: OUT, SERVER_ROOT, SERVER_CLI, SERVER_EXTENSIONS_JSON.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path
from typing import Set

from vscodium_common import find_server_cli


def export_from_json(json_path: Path, out: Path) -> None:
    data = json.loads(json_path.read_text(encoding="utf-8"))
    rows = set()  # type: Set[str]
    for item in data:
        ident = item.get("identifier") or {}
        ext_id = ident.get("id")
        ver = item.get("version")
        if ext_id and ver:
            rows.add(f"{ext_id}@{ver}")
    out.write_text("\n".join(sorted(rows)) + ("\n" if rows else ""), encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", type=Path, default=Path(os.environ.get("OUT", "vscodium-server-extensions.txt")))
    ap.add_argument(
        "--server-root",
        type=Path,
        default=Path(os.environ.get("SERVER_ROOT", str(Path.home() / ".vscodium-server"))),
    )
    ap.add_argument("--server-cli", default=os.environ.get("SERVER_CLI"))
    ap.add_argument("--extensions-json", default=os.environ.get("SERVER_EXTENSIONS_JSON"))
    args = ap.parse_args()

    server_root = args.server_root.expanduser().resolve()
    ext_dir = server_root / "extensions"
    cli = find_server_cli(server_root, args.server_cli)

    if cli:
        r = subprocess.run(
            [str(cli), "--extensions-dir", str(ext_dir), "--list-extensions", "--show-versions"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            universal_newlines=True,
        )
        if r.returncode != 0:
            print(r.stderr or r.stdout or "CLI error", file=sys.stderr)
            return 1
        args.out.write_text(r.stdout, encoding="utf-8")
        print(f"Записано в {args.out} через vscodium-server CLI: {cli}")
        return 0

    if args.extensions_json:
        jp = Path(args.extensions_json).expanduser()
    else:
        jp = ext_dir / "extensions.json"
    if jp.is_file():
        export_from_json(jp, args.out)
        print(f"Записано в {args.out} из {jp}")
        return 0

    print("Не найден vscodium-server источник расширений.", file=sys.stderr)
    print(f"Проверьте --server-root={server_root} или задайте --extensions-json / --server-cli", file=sys.stderr)
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
