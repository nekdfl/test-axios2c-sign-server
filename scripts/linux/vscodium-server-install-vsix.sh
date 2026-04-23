#!/usr/bin/env bash
# Установить все *.vsix из каталога в vscodium-server (офлайн). Только bash + codium CLI.
# По умолчанию VSIX_DIR — scripts/linux/vsix; SERVER_ROOT — ~/.vscodium-server
#
# Аргументы: --vsix-dir, --server-root, --server-cli (как у Python-скрипта).
# Переменные: VSIX_DIR, SERVER_ROOT, SERVER_CLI
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_vscodium_server_common.sh"

VSIX_DIR="${VSIX_DIR:-$SCRIPT_DIR/vsix}"
SERVER_ROOT="${SERVER_ROOT:-$HOME/.vscodium-server}"
SERVER_CLI="${SERVER_CLI:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --vsix-dir)
      VSIX_DIR="$2"
      shift 2
      ;;
    --server-root)
      SERVER_ROOT="$2"
      shift 2
      ;;
    --server-cli)
      SERVER_CLI="$2"
      shift 2
      ;;
    *)
      echo "Неизвестный аргумент: $1" >&2
      exit 1
      ;;
  esac
done

VSIX_DIR="${VSIX_DIR/#\~/$HOME}"
SERVER_ROOT="${SERVER_ROOT/#\~/$HOME}"
SERVER_CLI="${SERVER_CLI/#\~/$HOME}"

if [[ ! -d "$VSIX_DIR" ]]; then
  echo "Каталог не найден: $VSIX_DIR" >&2
  exit 1
fi

if ! CLI="$(vscodium_find_server_cli "$SERVER_ROOT" "${SERVER_CLI:-}")"; then
  echo "Не найден vscodium-server CLI. Задайте --server-cli=/полный/путь к bin/.../bin/codium" >&2
  exit 1
fi

EXT_DIR="$SERVER_ROOT/extensions"
mkdir -p "$EXT_DIR"

shopt -s nullglob
files=( "$VSIX_DIR"/*.vsix )
shopt -u nullglob
if [[ ${#files[@]} -eq 0 ]]; then
  echo "Нет файлов *.vsix в $VSIX_DIR" >&2
  exit 1
fi

mapfile -t sorted < <(printf '%s\n' "${files[@]}" | sort)

for f in "${sorted[@]}"; do
  echo "Установка в vscodium-server: $f" >&2
  "$CLI" --extensions-dir "$EXT_DIR" --install-extension "$f" || exit "$?"
done

echo "Готово. Установлено в: $EXT_DIR" >&2
