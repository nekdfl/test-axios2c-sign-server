#!/usr/bin/env python3
"""
Запуск demo-sign-server после сборки (python3 scripts/build.py).

  python3 scripts/run.py [...аргументы сервера...]

Переменные: PORT (по умолчанию 8080), DEMO_SIGN_AXIS2_REPO, AXIS2C_HOME.
"""

import os
import subprocess
import sys
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parent.parent


def axis2_prefix_has_headers(p: Path) -> bool:
    p = p.expanduser().resolve()
    inc = p / "include"
    if (inc / "axis2_http_server.h").is_file():
        return True
    if not inc.is_dir():
        return False
    for f in inc.rglob("axis2_http_server.h"):
        if f.is_file():
            try:
                depth = len(f.relative_to(inc).parts)
            except ValueError:
                continue
            if depth <= 2:
                return True
    return False


def resolve_axis2c_home() -> Optional[Path]:
    for raw in (
        os.environ.get("AXIS2C_HOME", ""),
        str(Path.home() / "axis2c-built"),
        str(Path.home() / "axis2c"),
        "/usr/local/axis2c",
        "/opt/axis2c",
    ):
        if not raw:
            continue
        cand = Path(raw).expanduser().resolve()
        if cand.is_dir() and axis2_prefix_has_headers(cand):
            return cand
    return None


def _axis2_sender_in(lib_parent: Path) -> bool:
    return (lib_parent / "libaxis2_http_sender.so").is_file() or (
        lib_parent / "libaxis2_http_sender.dylib"
    ).is_file()


def ensure_repo_lib(repo: Path) -> None:
    liblink = repo / "lib"
    if _axis2_sender_in(liblink):
        return
    ax = resolve_axis2c_home()
    if not ax:
        print(
            "Ошибка: Axis2/C ищет транспорты в $REPO/lib (например libaxis2_http_sender.so), а каталога нет.",
            file=sys.stderr,
        )
        print(
            "Установите AXIS2C_HOME на корень установки Axis2/C или создайте симлинк repo/lib -> .../lib.",
            file=sys.stderr,
        )
        sys.exit(1)
    axlib = ax / "lib"
    if not axlib.is_dir():
        print(f"Ошибка: нет каталога {axlib}", file=sys.stderr)
        sys.exit(1)
    if liblink.exists() or liblink.is_symlink():
        if liblink.is_symlink() or liblink.is_file():
            liblink.unlink()
        else:
            print(f"Ошибка: {liblink} существует и не симлинк — удалите или переименуйте.", file=sys.stderr)
            sys.exit(1)
    try:
        if sys.version_info >= (3, 10):
            liblink.symlink_to(axlib, target_is_directory=True)
        else:
            liblink.symlink_to(axlib)
    except OSError as e:
        print(f"Не удалось создать симлинк {liblink} -> {axlib}: {e}", file=sys.stderr)
        print("На Windows включите режим разработчика для symlink или создайте junction вручную.", file=sys.stderr)
        sys.exit(1)


def main() -> int:
    os.chdir(str(ROOT))
    b1 = ROOT / "build/source/backend/src/demo-sign-server"
    b2 = ROOT / "source/backend/src/demo-sign-server"
    if os.access(str(b1), os.X_OK):
        bin_path = b1
    elif os.access(str(b2), os.X_OK):
        bin_path = b2
    else:
        print(f"Не найден demo-sign-server (ожидалось {b1}).", file=sys.stderr)
        print("Сначала выполните: python3 scripts/build.py", file=sys.stderr)
        return 1

    if os.environ.get("DEMO_SIGN_AXIS2_REPO"):
        repo = Path(os.environ["DEMO_SIGN_AXIS2_REPO"]).expanduser().resolve()
    elif (ROOT / "build/axis2_repo/axis2.xml").is_file():
        repo = (ROOT / "build/axis2_repo").resolve()
    else:
        repo = (ROOT / "source/backend/axis2_repo").resolve()

    port = os.environ.get("PORT", "8080")
    if not (repo / "axis2.xml").is_file():
        print(f"Предупреждение: нет {repo / 'axis2.xml'} — проверьте DEMO_SIGN_AXIS2_REPO.", file=sys.stderr)

    ensure_repo_lib(repo)

    cmd = [str(bin_path), "-p", str(port), "-r", str(repo)] + sys.argv[1:]
    return subprocess.call(cmd)


if __name__ == "__main__":
    raise SystemExit(main())
