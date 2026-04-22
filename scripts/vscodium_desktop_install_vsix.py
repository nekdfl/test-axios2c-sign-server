#!/usr/bin/env python3
"""
Офлайн-установка всех .vsix из каталога в VSCodium (десктоп).

  python3 scripts/vscodium_desktop_install_vsix.py [vsix_dir] [cli]
"""

import subprocess
import sys
from pathlib import Path

from vscodium_common import find_desktop_vscodium


def main() -> int:
    vsix_dir = Path(sys.argv[1] if len(sys.argv) > 1 else "vsix")
    cli_arg = sys.argv[2] if len(sys.argv) > 2 else None
    if not vsix_dir.is_dir():
        print(f"Каталог не найден: {vsix_dir}", file=sys.stderr)
        return 2
    exe = find_desktop_vscodium(cli_arg)
    if not exe:
        print(
            "Не найден VSCodium. Добавьте codium в PATH или передайте путь к exe вторым аргументом.",
            file=sys.stderr,
        )
        return 2
    files = sorted(vsix_dir.glob("*.vsix"))
    if not files:
        print(f"Нет *.vsix в {vsix_dir}", file=sys.stderr)
        return 3
    for f in files:
        print(f"Установка: {f}", flush=True)
        code = subprocess.call([str(exe), "--install-extension", str(f)])
        if code != 0:
            print(f"Ошибка установки: {f.name}", file=sys.stderr)
            return 4
    print("Готово.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
