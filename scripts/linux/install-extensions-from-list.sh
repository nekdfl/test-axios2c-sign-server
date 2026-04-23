#!/usr/bin/env bash
# Скачивание и установка расширений vscodium-server по списку (обёртка над ../vscodium_install_extensions_from_list.py).
#
# Примеры из корня репозитория:
#   ./scripts/linux/install-extensions-from-list.sh scripts/linux/vscodium-extensions.txt
#   ./scripts/linux/install-extensions-from-list.sh --openvsx scripts/linux/vscodium-extensions.txt
# Десктоп: добавьте --desktop
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/../vscodium_install_extensions_from_list.py" "$@"
