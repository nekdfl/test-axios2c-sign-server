#!/usr/bin/env bash
# Установка VSIX в vscodium-server через server CLI.
#
# Переменные:
#   SERVER_ROOT=~/.vscodium-server
#   VSIX_DIR=vsix
#   SERVER_CLI=/путь/к/server-cli
set -euo pipefail

SERVER_ROOT="${SERVER_ROOT:-$HOME/.vscodium-server}"
VSIX_DIR="${VSIX_DIR:-vsix}"
SERVER_EXT_DIR="${SERVER_ROOT}/extensions"

resolve_server_cli() {
  if [[ -n "${SERVER_CLI:-}" && -x "${SERVER_CLI}" ]]; then
    echo "${SERVER_CLI}"
    return
  fi

  local cand
  for cand in \
    "${SERVER_ROOT}"/bin/*/bin/remote-cli/code \
    "${SERVER_ROOT}"/bin/*/bin/code; do
    if [[ -x "$cand" ]]; then
      echo "$cand"
      return
    fi
  done

  echo "Не найден vscodium-server CLI. Задайте SERVER_CLI=/полный/путь" >&2
  exit 1
}

if [[ ! -d "$VSIX_DIR" ]]; then
  echo "Каталог не найден: $VSIX_DIR" >&2
  exit 1
fi

mkdir -p "$SERVER_EXT_DIR"
CLI_PATH="$(resolve_server_cli)"

shopt -s nullglob
files=("$VSIX_DIR"/*.vsix)
if [[ ${#files[@]} -eq 0 ]]; then
  echo "Нет файлов *.vsix в $VSIX_DIR" >&2
  exit 1
fi

for f in "${files[@]}"; do
  echo "Установка в vscodium-server: $f"
  "$CLI_PATH" --extensions-dir "$SERVER_EXT_DIR" --install-extension "$f"
done

echo "Готово. Установлено в: $SERVER_EXT_DIR"
