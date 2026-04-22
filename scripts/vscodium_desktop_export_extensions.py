#!/usr/bin/env python3
"""
Экспорт установленных расширений VSCodium (десктоп) в publisher.name@version.

  python3 scripts/vscodium_desktop_export_extensions.py [outfile] [cli]
"""

import subprocess
import sys
from pathlib import Path

from vscodium_common import find_desktop_vscodium


def main() -> int:
    outfile = Path(sys.argv[1] if len(sys.argv) > 1 else "vscodium-extensions.txt")
    cli_arg = sys.argv[2] if len(sys.argv) > 2 else None
    exe = find_desktop_vscodium(cli_arg)
    if not exe:
        print(
            "Не найден VSCodium. Добавьте codium в PATH или передайте путь к exe вторым аргументом.",
            file=sys.stderr,
        )
        return 2
    r = subprocess.run(
        [str(exe), "--list-extensions", "--show-versions"],
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True,
    )
    if r.returncode != 0:
        print(r.stderr or r.stdout or "CLI error", file=sys.stderr)
        return 3
    outfile.write_text(r.stdout, encoding="utf-8")
    print(f"Записано: {outfile.resolve()}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
