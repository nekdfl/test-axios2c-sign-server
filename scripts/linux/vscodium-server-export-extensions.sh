#!/usr/bin/env bash
# Экспорт расширений vscodium-server в формате publisher.name@version.
#
# Источник по умолчанию:
#   1) SERVER_EXTENSIONS_JSON (если задан)
#   2) ~/.vscodium-server/extensions/extensions.json
#
# Если доступен SERVER_CLI (или найден в ~/.vscodium-server/bin/*/bin/{code,remote-cli/code}),
# будет использован именно он с --extensions-dir ~/.vscodium-server/extensions.
#
# Переменные:
#   OUT=vscodium-server-extensions.txt
#   SERVER_ROOT=~/.vscodium-server
#   SERVER_EXTENSIONS_JSON=/путь/extensions.json
#   SERVER_CLI=/путь/к/server-cli
set -euo pipefail

OUT="${OUT:-vscodium-server-extensions.txt}"
SERVER_ROOT="${SERVER_ROOT:-$HOME/.vscodium-server}"
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
  return 1
}

resolve_extensions_json() {
  if [[ -n "${SERVER_EXTENSIONS_JSON:-}" && -f "${SERVER_EXTENSIONS_JSON}" ]]; then
    echo "${SERVER_EXTENSIONS_JSON}"
    return
  fi
  if [[ -f "${SERVER_EXT_DIR}/extensions.json" ]]; then
    echo "${SERVER_EXT_DIR}/extensions.json"
    return
  fi
  return 1
}

if cli="$(resolve_server_cli)"; then
  "$cli" --extensions-dir "$SERVER_EXT_DIR" --list-extensions --show-versions >"$OUT"
  echo "Записано в $OUT через vscodium-server CLI: $cli"
  exit 0
fi

if json_path="$(resolve_extensions_json)"; then
  python3 - "$json_path" >"$OUT" <<'PY'
import json
import pathlib
import sys

p = pathlib.Path(sys.argv[1])
data = json.loads(p.read_text(encoding="utf-8"))
rows = set()
for item in data:
    ident = item.get("identifier") or {}
    ext_id = ident.get("id")
    ver = item.get("version")
    if ext_id and ver:
        rows.add(f"{ext_id}@{ver}")
for row in sorted(rows):
    print(row)
PY
  echo "Записано в $OUT из $json_path"
  exit 0
fi

echo "Не найден vscodium-server источник расширений." >&2
echo "Проверьте SERVER_ROOT=${SERVER_ROOT} или задайте SERVER_EXTENSIONS_JSON/SERVER_CLI" >&2
exit 1
