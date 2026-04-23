"""Общие утилиты для скриптов VSCodium (десктоп и server)."""

import glob
import os
import shutil
import sys
import urllib.request
from pathlib import Path
from typing import Optional, Tuple


def proxy_cfg_path() -> Path:
    """Путь к `scripts/proxy.cfg` или переопределение через `VSCODIUM_PROXY_CFG`."""
    env = os.environ.get("VSCODIUM_PROXY_CFG", "").strip()
    if env:
        return Path(env).expanduser().resolve()
    return Path(__file__).resolve().parent / "proxy.cfg"


def load_proxy_settings(cfg_path: Optional[Path] = None) -> Tuple[bool, Optional[str]]:
    """
    Читает `use_proxy` и `address` из proxy.cfg.
    Возвращает (использовать_прокси, url_или_None). При use_proxy=false или пустом address — прямой доступ.
    """
    path = cfg_path or proxy_cfg_path()
    if not path.is_file():
        return False, None
    use = False
    address = ""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError:
        return False, None
    for raw in text.splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        key, val = key.strip().lower(), val.strip().strip('"').strip("'")
        if key == "use_proxy":
            use = val.lower() in ("true", "yes", "1", "on")
        elif key == "address":
            address = val
    if use and address:
        return True, address
    return False, None


def install_urllib_proxy_from_cfg(cfg_path: Optional[Path] = None) -> Optional[str]:
    """
    Если в proxy.cfg задано use_proxy=true и непустой address, устанавливает urllib opener с ProxyHandler.
    Иначе не меняет поведение urllib. Возвращает URL прокси при включении, иначе None.
    """
    use, addr = load_proxy_settings(cfg_path)
    if not use or not addr:
        return None
    handlers = [
        urllib.request.ProxyHandler({"http": addr, "https": addr}),
    ]
    opener = urllib.request.build_opener(*handlers)
    urllib.request.install_opener(opener)
    return addr


def resolve_server_cli_path(cli: Path) -> Path:
    """
    Бинарники под .../bin/<hash>/bin/remote-cli/{code,codium} предназначены для терминала внутри IDE
    и в обычной SSH-сессии отвечают «Command is only available in WSL...».
    Для офлайн-установки VSIX используйте .../bin/<hash>/bin/codium (или code) — подменяем путь при необходимости.
    """
    cli = cli.expanduser().resolve()
    if not cli.is_file():
        return cli
    if "remote-cli" not in cli.parts:
        return cli
    parent_bin = cli.parent.parent
    for name in ("codium", "code"):
        cand = parent_bin / name
        if cand.is_file() and (os.access(str(cand), os.X_OK) or sys.platform == "win32"):
            return cand.resolve()
    return cli


def find_desktop_vscodium(cli: Optional[str]) -> Optional[Path]:
    """Путь к codium / vscodium / VSCodium.exe или None."""
    if cli:
        p = Path(cli).expanduser()
        if p.is_file():
            return p.resolve()
        return None
    for name in ("codium", "vscodium"):
        w = shutil.which(name)
        if w:
            return Path(w).resolve()
    if sys.platform == "win32":
        for p in (
            Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "VSCodium" / "VSCodium.exe",
            Path(os.environ.get("ProgramFiles", "")) / "VSCodium" / "VSCodium.exe",
            Path(os.environ.get("ProgramFiles(x86)", "")) / "VSCodium" / "VSCodium.exe",
        ):
            if p.is_file():
                return p.resolve()
    return None


def find_server_cli(server_root: Path, explicit: Optional[str]) -> Optional[Path]:
    if explicit:
        p = resolve_server_cli_path(Path(explicit))
        if p.is_file():
            return p.resolve()
        return None
    patterns = (
        str(server_root / "bin" / "*" / "bin" / "codium"),
        str(server_root / "bin" / "*" / "bin" / "code"),
        str(server_root / "bin" / "*" / "bin" / "remote-cli" / "code"),
        str(server_root / "bin" / "*" / "bin" / "remote-cli" / "codium"),
    )
    for pat in patterns:
        for cand in sorted(glob.glob(pat)):
            cp = Path(cand)
            if "remote-cli" in cp.parts:
                cp = resolve_server_cli_path(cp)
            if cp.is_file() and (os.access(str(cp), os.X_OK) or sys.platform == "win32"):
                return cp.resolve()
    return None
