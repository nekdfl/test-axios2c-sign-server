#!/usr/bin/env python3
"""
Установка VSIX в vscodium-server через server CLI.

  python3 scripts/vscodium_server_install_vsix.py [--vsix-dir DIR] [--server-root DIR] [--server-cli PATH]

Переменные окружения: VSIX_DIR, SERVER_ROOT, SERVER_CLI.

Не используйте bin/<hash>/bin/remote-cli/{code,codium} из SSH — это CLI для терминала IDE.
Нужен bin/<hash>/bin/codium (или code); если передали remote-cli, скрипт попытается заменить путь сам.
"""

import argparse
import os
import subprocess
import sys
from pathlib import Path

from vscodium_common import find_server_cli


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--vsix-dir", type=Path, default=Path(os.environ.get("VSIX_DIR", "vsix")))
    ap.add_argument(
        "--server-root",
        type=Path,
        default=Path(os.environ.get("SERVER_ROOT", str(Path.home() / ".vscodium-server"))),
    )
    ap.add_argument("--server-cli", default=os.environ.get("SERVER_CLI"))
    args = ap.parse_args()

    vsix_dir = args.vsix_dir.expanduser().resolve()
    server_root = args.server_root.expanduser().resolve()
    ext_dir = server_root / "extensions"

    if not vsix_dir.is_dir():
        print(f"Каталог не найден: {vsix_dir}", file=sys.stderr)
        return 1

    cli = find_server_cli(server_root, args.server_cli)
    if not cli:
        print("Не найден vscodium-server CLI. Задайте --server-cli=/полный/путь", file=sys.stderr)
        return 1

    ext_dir.mkdir(parents=True, exist_ok=True)
    files = sorted(vsix_dir.glob("*.vsix"))
    if not files:
        print(f"Нет файлов *.vsix в {vsix_dir}", file=sys.stderr)
        return 1

    # subprocess.call вместо run: в Python 3.6 run() всегда вызывает communicate(),
    # лишний слой при наследовании stdin/stdout/stderr и неудобный traceback по Ctrl+C.
    for f in files:
        print(f"Установка в vscodium-server: {f}", flush=True)
        code = subprocess.call(
            [
                str(cli),
                "--extensions-dir",
                str(ext_dir),
                "--install-extension",
                str(f),
            ],
        )
        if code != 0:
            return code if code > 0 else 1
    print(f"Готово. Установлено в: {ext_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
