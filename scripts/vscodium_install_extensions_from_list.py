#!/usr/bin/env python3
"""
Скачивание и установка расширений для vscodium-server по текстовому списку
(формат строк как у openvsx_download_vsix.py: publisher.extension@version).

По умолчанию используется корень ~/.vscodium-server и CLI из bin/<hash>/bin/codium.

Режим по умолчанию: серверный CLI качает пакеты из маркетплейса продукта:
  codium --extensions-dir ~/.vscodium-server/extensions --install-extension publisher.name@version

Режим Open VSX: сначала скачать .vsix (openvsx_download_vsix.py), затем:
  codium --extensions-dir … --install-extension /path/to/file.vsix

  python3 scripts/vscodium_install_extensions_from_list.py [список]
      [--openvsx] [--vsix-dir DIR]
      [--server-root DIR] [--server-cli PATH]
      [--desktop] [--codium PATH]

Обёртки cmd: `scripts/windows/vscodium-server-install-from-list.cmd` (сервер),
`scripts/windows/vscodium-desktop-install-from-list.cmd` (десктоп). На Linux:
`scripts/linux/vscodium-server-install-from-list.sh` и `scripts/linux/vscodium-desktop-install-from-list.sh`.

Переменные: SERVER_ROOT (по умолчанию ~/.vscodium-server), SERVER_CLI, VSIX_DIR (--openvsx),
EXTENSIONS_LIST. Для десктопного VSCodium: --desktop и при необходимости CODIUM_EXE / --codium.
"""

from __future__ import annotations

import argparse
import os
import subprocess
import sys
from pathlib import Path
from typing import List, Optional

from vscodium_common import find_desktop_vscodium, find_server_cli

SCRIPT_DIR = Path(__file__).resolve().parent


def read_extension_specs(list_path: Path) -> List[str]:
    """Строки для `codium --install-extension …`: `publisher.ext@version` или `publisher.ext` (последняя версия)."""
    out: List[str] = []
    for raw in list_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "@" in line:
            ext_id, _, ver = line.partition("@")
            ext_id, ver = ext_id.strip(), ver.strip()
            if "." not in ext_id or not ver:
                print(f"пропуск: {line}", file=sys.stderr)
                continue
            out.append(f"{ext_id}@{ver}")
            continue
        if "." in line:
            ext_id = line.strip()
            out.append(ext_id)
        else:
            print(f"пропуск (ожидался publisher.extension или publisher.extension@version): {line}", file=sys.stderr)
    return out


def run_openvsx_download(list_path: Path, vsix_dir: Path) -> int:
    dl = SCRIPT_DIR / "openvsx_download_vsix.py"
    if not dl.is_file():
        print(f"Не найден {dl}", file=sys.stderr)
        return 1
    vsix_dir.mkdir(parents=True, exist_ok=True)
    return subprocess.call([sys.executable, str(dl), str(list_path), str(vsix_dir)])


def main() -> int:
    ap = argparse.ArgumentParser(description="Установка расширений VSCodium по списку (vscodium-server или десктоп).")
    ap.add_argument(
        "list",
        nargs="?",
        type=Path,
        default=Path(os.environ.get("EXTENSIONS_LIST", "vscodium-extensions.txt")),
    )
    ap.add_argument(
        "--openvsx",
        action="store_true",
        help="Скачать .vsix с Open VSX, затем установить файлы (иначе — только --install-extension).",
    )
    ap.add_argument(
        "--vsix-dir",
        type=Path,
        default=Path(os.environ.get("VSIX_DIR", "vsix")),
        help="Каталог для .vsix при --openvsx (по умолчанию vsix).",
    )
    ap.add_argument(
        "--desktop",
        action="store_true",
        help="Десктопный VSCodium (иначе — vscodium-server, см. --server-root).",
    )
    ap.add_argument(
        "--codium",
        default=os.environ.get("CODIUM_EXE"),
        help="С --desktop: путь к VSCodium.exe / codium.",
    )
    ap.add_argument(
        "--server-root",
        type=Path,
        default=Path(os.environ.get("SERVER_ROOT", str(Path.home() / ".vscodium-server"))),
        help="Корень vscodium-server (по умолчанию ~/.vscodium-server или $SERVER_ROOT).",
    )
    ap.add_argument("--server-cli", default=os.environ.get("SERVER_CLI"), help="Явный путь к CLI сервера.")
    args = ap.parse_args()

    list_path = args.list.expanduser().resolve()
    if not list_path.is_file():
        print(f"Файл списка не найден: {list_path}", file=sys.stderr)
        return 1

    ext_dir: Optional[Path] = None
    if args.desktop:
        cli = find_desktop_vscodium(args.codium)
        if not cli:
            print(
                "Не найден VSCodium (десктоп). Добавьте codium в PATH или задайте CODIUM_EXE / --codium.",
                file=sys.stderr,
            )
            return 2
    else:
        server_root = args.server_root.expanduser().resolve()
        cli = find_server_cli(server_root, args.server_cli)
        if not cli:
            print(
                "Не найден vscodium-server CLI под %s. "
                "Распакуйте сервер в этот каталог или укажите --server-cli=/полный/путь к bin/.../codium"
                % (server_root,),
                file=sys.stderr,
            )
            return 2
        ext_dir = server_root / "extensions"
        ext_dir.mkdir(parents=True, exist_ok=True)

    if args.openvsx:
        code = run_openvsx_download(list_path, args.vsix_dir.expanduser().resolve())
        if code != 0:
            return code
        vsix_dir = args.vsix_dir.expanduser().resolve()
        files = sorted(vsix_dir.glob("*.vsix"))
        if not files:
            print(f"Нет *.vsix в {vsix_dir}", file=sys.stderr)
            return 3
        for f in files:
            cmd = [str(cli), "--install-extension", str(f)]
            if ext_dir is not None:
                cmd[1:1] = ["--extensions-dir", str(ext_dir)]
            print(f"Установка: {f.name}", flush=True)
            code = subprocess.call(cmd)
            if code != 0:
                print(f"Ошибка установки: {f.name}", file=sys.stderr)
                return code if code > 0 else 1
    else:
        ids = read_extension_specs(list_path)
        if not ids:
            print("В списке нет пригодных строк расширений", file=sys.stderr)
            return 3
        for ext in ids:
            cmd = [str(cli), "--install-extension", ext]
            if ext_dir is not None:
                cmd[1:1] = ["--extensions-dir", str(ext_dir)]
            print(f"Установка: {ext}", flush=True)
            code = subprocess.call(cmd)
            if code != 0:
                print(f"Ошибка установки: {ext}", file=sys.stderr)
                return code if code > 0 else 1

    print("Готово.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
