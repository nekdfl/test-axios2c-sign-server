#!/usr/bin/env bash
# Скачать VSIX с Open VSX по списку publisher.extension@version.
# Зависимости: curl, jq.
#
# Аргументы: [файл_списка] [каталог_vsix]
# По умолчанию: scripts/linux/vscodium-extensions.txt и scripts/linux/vsix/
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_vscodium_server_common.sh"
vscodium_require_curl_jq || exit 1

UA="openvsx-download-bash/1.0"

case $# in
  0)
    LIST="$SCRIPT_DIR/vscodium-extensions.txt"
    VSIX_DIR="$SCRIPT_DIR/vsix"
    ;;
  1)
    LIST="$1"
    VSIX_DIR="$SCRIPT_DIR/vsix"
    ;;
  *)
    LIST="$1"
    VSIX_DIR="$2"
    ;;
esac

LIST="${LIST/#\~/$HOME}"
VSIX_DIR="${VSIX_DIR/#\~/$HOME}"

if [[ ! -f "$LIST" ]]; then
  echo "Файл списка не найден: $LIST" >&2
  exit 1
fi

mkdir -p "$VSIX_DIR"

while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="$(echo "$raw" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$line" || "$line" =~ ^# ]] && continue
  if [[ "$line" != *"@"* ]]; then
    echo "пропуск (нет @): $line" >&2
    continue
  fi
  ext_id="${line%%@*}"
  ver="${line#*@}"
  ext_id="$(echo "$ext_id" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  ver="$(echo "$ver" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  if [[ "$ext_id" != *"."* ]]; then
    echo "пропуск (ожидался publisher.extension): $line" >&2
    continue
  fi
  ns="${ext_id%%.*}"
  name="${ext_id#*.}"
  meta_url="https://open-vsx.org/api/${ns}/${name}/${ver}"
  if ! meta="$(curl -fsSL -H "User-Agent: $UA" "$meta_url")"; then
    echo "HTTP ошибка: $line" >&2
    continue
  fi
  dl="$(printf '%s' "$meta" | jq -r '.files.download // empty')"
  if [[ -z "$dl" ]]; then
    echo "нет URL загрузки: $line" >&2
    continue
  fi
  leaf="${dl##*/}"
  dest="$VSIX_DIR/$leaf"
  if ! curl -fsSL -H "User-Agent: $UA" -o "$dest" "$dl"; then
    echo "ошибка загрузки: $line" >&2
    continue
  fi
  echo "$dest"
done < "$LIST"

echo "Готово. Каталог: $VSIX_DIR" >&2
