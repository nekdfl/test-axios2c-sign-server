#!/usr/bin/env bash
# Скачать архив vscodium-server (Linux) из GitHub Releases в каталог (по умолчанию scripts/linux/).
# Зависимости: curl, jq.
#
# Переменные: ARCH (x64|arm64|armhf), FLAVOR (reh|reh-web), OUTDIR
# Аргументы: --arch, --flavor, --outdir
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/_vscodium_server_common.sh"
vscodium_require_curl_jq || exit 1

ARCH="${ARCH:-x64}"
FLAVOR="${FLAVOR:-reh}"
OUTDIR="${OUTDIR:-$SCRIPT_DIR}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch)
      ARCH="$2"
      shift 2
      ;;
    --flavor)
      FLAVOR="$2"
      shift 2
      ;;
    --outdir)
      OUTDIR="$2"
      shift 2
      ;;
    *)
      echo "Неизвестный аргумент: $1" >&2
      exit 1
      ;;
  esac
done

OUTDIR="${OUTDIR/#\~/$HOME}"
mkdir -p "$OUTDIR"

case "$ARCH" in
  x64 | arm64 | armhf) ;;
  *)
    echo "Недопустимый ARCH=$ARCH (ожидалось x64|arm64|armhf)" >&2
    exit 1
    ;;
esac

case "$FLAVOR" in
  reh) RX="^vscodium-reh-linux-${ARCH}-.*\\.tar\\.gz\$" ;;
  reh-web) RX="^vscodium-reh-web-linux-${ARCH}-.*\\.tar\\.gz\$" ;;
  *)
    echo "Недопустимый FLAVOR=$FLAVOR (ожидалось reh|reh-web)" >&2
    exit 1
    ;;
esac

API="https://api.github.com/repos/VSCodium/vscodium/releases/latest"
UA="vscodium-server-download-bash/1.0"

JSON="$(curl -fsSL -H "User-Agent: $UA" "$API")"
TAG="$(printf '%s' "$JSON" | jq -r '.tag_name // "?"')"

URL="$(printf '%s' "$JSON" | jq -r --arg rx "$RX" '(.assets // [])[] | select(.name | test($rx)) | .browser_download_url' | head -n1)"
NAME="$(printf '%s' "$JSON" | jq -r --arg rx "$RX" '(.assets // [])[] | select(.name | test($rx)) | .name' | head -n1)"

if [[ -z "$URL" || -z "$NAME" ]]; then
  echo "Не найден asset (FLAVOR=$FLAVOR ARCH=$ARCH)" >&2
  exit 1
fi

DEST="$OUTDIR/$NAME"
echo "Релиз $TAG" >&2
echo "GET $URL" >&2
curl -fL --progress-bar -H "User-Agent: $UA" -o "$DEST" "$URL"
echo "Сохранено: $DEST" >&2
