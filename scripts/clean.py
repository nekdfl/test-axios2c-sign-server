#!/usr/bin/env python3
"""
Очистка артефактов autotools и сборки (без удаления исходников).

  python3 scripts/clean.py
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def rm_rf(path: Path) -> None:
    if path.exists():
        shutil.rmtree(path, ignore_errors=True)


def rm_f(path: Path) -> None:
    try:
        path.unlink()
    except OSError:
        pass


def main() -> int:
    os.chdir(str(ROOT))

    build = ROOT / "build"
    if (build / "Makefile").is_file():
        subprocess.run(["make", "distclean"], cwd=str(build), check=False)
    rm_rf(build)

    if (ROOT / "Makefile").is_file():
        subprocess.run(["make", "distclean"], cwd=str(ROOT), check=False)

    subdirs = [
        ROOT,
        ROOT / "source/backend/include",
        ROOT / "source/backend/services",
        ROOT / "source/backend/services/demo_sign",
        ROOT / "source/backend/src",
        ROOT / "source/frontend/client",
    ]
    for d in subdirs:
        rm_f(d / "Makefile")
        rm_f(d / "Makefile.in")

    rm_rf(ROOT / "autom4te.cache")
    rm_f(ROOT / "source/backend/axis2_repo/services/demo_sign/libdemo_sign.so")

    for name in (
        "aclocal.m4",
        "compile",
        "config.guess",
        "config.sub",
        "configure",
        "depcomp",
        "install-sh",
        "ltmain.sh",
        "missing",
        "ar-lib",
        "config.h",
        "config.h.in",
        "config.log",
        "config.status",
        "libtool",
        "stamp-h1",
    ):
        rm_f(ROOT / name)

    for dirpath, _, _ in os.walk(str(ROOT), topdown=False):
        d = Path(dirpath)
        if d.name in (".deps", ".libs"):
            rm_rf(d)

    skip_under = {".git"}
    for dirpath, dirnames, filenames in os.walk(str(ROOT)):
        parts = set(Path(dirpath).parts)
        if parts & skip_under:
            dirnames[:] = []
            continue
        dp = Path(dirpath)
        for fn in filenames:
            if fn.endswith((".o", ".lo", ".la", ".a")):
                rm_f(dp / fn)

    print("Очистка завершена.", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
