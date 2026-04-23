#!/usr/bin/env bash
# Экспорт списка расширений vscodium-server (publisher@version). Только bash (+ jq для extensions.json).
# По умолчанию OUT — scripts/linux/vscodium-server-extensions.txt
#
# Аргументы: --out, --server-root, --server-cli, --extensions-json
# Переменные: OUT, SERVER_ROOT, SERVER_CLI, SERVER_EXTENSIONS_JSON
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_vscodium_server_common.sh"

OUT="${OUT:-$SCRIPT_DIR/vscodium-server-extensions.txt}"
SERVER_ROOT="${SERVER_ROOT:-$HOME/.vscodium-server}"
SERVER_CLI="${SERVER_CLI:-}"
SERVER_EXTENSIONS_JSON="${SERVER_EXTENSIONS_JSON:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --out)
      OUT="$2"
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
    --extensions-json)
      SERVER_EXTENSIONS_JSON="$2"
      shift 2
      ;;
    *)
      echo "Неизвестный аргумент: $1" >&2
      exit 1
      ;;
  esac
done

OUT="${OUT/#\~/$HOME}"
SERVER_ROOT="${SERVER_ROOT/#\~/$HOME}"
SERVER_CLI="${SERVER_CLI/#\~/$HOME}"
SERVER_EXTENSIONS_JSON="${SERVER_EXTENSIONS_JSON/#\~/$HOME}"

EXT_DIR="$SERVER_ROOT/extensions"

if CLI="$(vscodium_find_server_cli "$SERVER_ROOT" "${SERVER_CLI:-}")"; then
  "$CLI" --extensions-dir "$EXT_DIR" --list-extensions --show-versions >"$OUT"
  echo "Записано в $OUT через vscodium-server CLI: $CLI" >&2
  exit 0
fi

if [[ -n "$SERVER_EXTENSIONS_JSON" ]]; then
  JP="$SERVER_EXTENSIONS_JSON"
else
  JP="$EXT_DIR/extensions.json"
fi

if [[ ! -f "$JP" ]]; then
  echo "Не найден vscodium-server источник расширений." >&2
  echo "Проверьте --server-root=$SERVER_ROOT или задайте --extensions-json / --server-cli" >&2
  exit 1
fi

command -v jq >/dev/null 2>&1 || {
  echo "Нужен jq для чтения $JP или задайте рабочий --server-cli." >&2
  exit 1
}

tmp="$(mktemp "${TMPDIR:-/tmp}/vscodium-exp.XXXXXX")"
if ! jq -r '.[] | select(.identifier.id != null and .version != null) | "\(.identifier.id)@\(.version)"' "$JP" | sort -u >"$tmp"; then
  rm -f "$tmp"
  exit 1
fi
mv -f "$tmp" "$OUT"
echo "Записано в $OUT из $JP" >&2
