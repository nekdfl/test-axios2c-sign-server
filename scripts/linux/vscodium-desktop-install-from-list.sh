#!/usr/bin/env bash
# Установка расширений десктопного VSCodium по списку (обёртка над ../vscodium_install_extensions_from_list.py --desktop).
#
# Пример из корня репозитория:
#   ./scripts/linux/vscodium-desktop-install-from-list.sh scripts/linux/vscodium-extensions.txt
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 "$SCRIPT_DIR/../vscodium_install_extensions_from_list.py" --desktop "$@"
