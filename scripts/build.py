#!/usr/bin/env python3
"""
Сборка: autoreconf в корне → configure + make в build/ (вне дерева исходников).

  python3 scripts/build.py [префикс_axis2c] [...аргументы configure...]

Переменные: AXIS2C_HOME, DEMO_SIGN_BUILD_DIR, NPROC (число параллельных задач make).
Целевая платформа: Unix (Linux, macOS) с autotools; на Windows без MSYS этот скрипт не применим.
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import List, Tuple

ROOT = Path(__file__).resolve().parent.parent


def axis2_prefix_has_headers(p: Path) -> bool:
    p = p.expanduser().resolve()
    inc = p / "include"
    direct = inc / "axis2_http_server.h"
    if direct.is_file():
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


def discover_axis2(argv: List[str]) -> Tuple[Path, List[str]]:
    """Возвращает (axis2_prefix, оставшиеся аргументы для configure)."""
    rest = list(argv)
    axis2 = None  # type: Optional[Path]
    if rest and not rest[0].startswith("-") and Path(rest[0]).is_dir():
        cand = Path(rest[0]).expanduser().resolve()
        if axis2_prefix_has_headers(cand):
            axis2 = cand
            rest = rest[1:]
        else:
            print(f"Ошибка: в каталоге '{cand}' нет axis2_http_server.h.", file=sys.stderr)
            sys.exit(1)

    if axis2 is None:
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
            if axis2_prefix_has_headers(cand):
                axis2 = cand
                break

    if axis2 is None:
        print("Ошибка: не найден установленный Apache Axis2/C (файл axis2_http_server.h).", file=sys.stderr)
        print("  Укажите: AXIS2C_HOME=/path/to/prefix python3 scripts/build.py", file=sys.stderr)
        print("  или:     python3 scripts/build.py /path/to/prefix [...]", file=sys.stderr)
        sys.exit(1)

    return axis2, rest


def compile_commands_nonempty(path: Path) -> bool:
    if not path.is_file():
        return False
    try:
        return '"file"' in path.read_text(encoding="utf-8", errors="ignore")
    except OSError:
        return False


def main() -> int:
    if os.name == "nt" and "MSYSTEM" not in os.environ:
        print(
            "Этот build.py рассчитан на Unix-подобную среду с autoreconf/configure/make. "
            "Используйте WSL или MSYS2, либо собирайте вручную.",
            file=sys.stderr,
        )
        return 1

    if not shutil.which("autoreconf"):
        print("autoreconf не найден. Установите autoconf automake libtool m4.", file=sys.stderr)
        return 1

    os.chdir(str(ROOT))
    subprocess.run(["autoreconf", "-fi"], check=True)

    axis2, configure_args = discover_axis2(sys.argv[1:])

    builddir = Path(os.environ.get("DEMO_SIGN_BUILD_DIR", str(ROOT / "build"))).expanduser().resolve()
    builddir.mkdir(parents=True, exist_ok=True)

    print(f"Axis2/C: {axis2}", file=sys.stderr)
    print(f"Каталог сборки: {builddir}", file=sys.stderr)

    cfg = [str(ROOT / "configure"), f"--with-axis2c={axis2}", *configure_args]
    subprocess.run(cfg, check=True, cwd=str(builddir))

    try:
        nproc = int(os.environ.get("NPROC", str(os.cpu_count() or 4)))
    except ValueError:
        nproc = 4
    j = f"-j{nproc}"

    bear = shutil.which("bear")
    if bear:
        r = subprocess.run([bear, "--", "make", j], cwd=str(builddir))
        if r.returncode != 0:
            sys.exit(r.returncode)
        cc = builddir / "compile_commands.json"
        if not compile_commands_nonempty(cc):
            print(
                "compile_commands.json пуст — делается make clean и полная пересборка под bear.",
                file=sys.stderr,
            )
            if cc.is_file():
                cc.unlink()
            subprocess.run([bear, "--", "make", j, "clean"], check=True, cwd=str(builddir))
            subprocess.run([bear, "--", "make", j], check=True, cwd=str(builddir))
        if compile_commands_nonempty(cc):
            print(f"compile_commands.json: {cc}", file=sys.stderr)
        else:
            print("Предупреждение: не удалось заполнить compile_commands.json.", file=sys.stderr)
    else:
        subprocess.run(["make", j], check=True, cwd=str(builddir))
        print(
            f"Установите bear и пересоберите — появится {builddir / 'compile_commands.json'} для IDE.",
            file=sys.stderr,
        )

    bin_path = builddir / "source" / "backend" / "src" / "demo-sign-server"
    print(f"Готово: {bin_path}", file=sys.stderr)
    print(f"Запуск: cd {ROOT} && python3 scripts/run.py", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
