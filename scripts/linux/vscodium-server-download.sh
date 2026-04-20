#!/usr/bin/env bash
# Скачивание архива vscodium-server (Remote Extension Host) для Linux.
#
# Переменные:
#   ARCH=x64|arm64|armhf      (по умолчанию x64)
#   FLAVOR=reh|reh-web        (по умолчанию reh)
#   OUTDIR=.                  каталог сохранения
#
# Примеры:
#   ARCH=x64 ./scripts/linux/vscodium-server-download.sh
#   FLAVOR=reh-web OUTDIR=$HOME/dist ./scripts/linux/vscodium-server-download.sh
set -euo pipefail

ARCH="${ARCH:-x64}"
FLAVOR="${FLAVOR:-reh}"
OUTDIR="${OUTDIR:-.}"

API="https://api.github.com/repos/VSCodium/vscodium/releases/latest"

pick_regex() {
  case "$FLAVOR" in
    reh) echo "^vscodium-reh-linux-${ARCH}-.*\\.tar\\.gz$" ;;
    reh-web) echo "^vscodium-reh-web-linux-${ARCH}-.*\\.tar\\.gz$" ;;
    *)
      echo "Неизвестный FLAVOR=$FLAVOR (reh|reh-web)" >&2
      exit 1
      ;;
  esac
}

tag="$(curl -fsSL "$API" | python3 -c "import sys,json; print(json.load(sys.stdin)['tag_name'])")"
mapfile -t lines < <(curl -fsSL "$API" | python3 -c '
import json, re, sys
r = json.load(sys.stdin)
pat = re.compile(sys.argv[1])
for a in r.get("assets", []):
    n = a.get("name") or ""
    if pat.match(n):
        print(a["browser_download_url"])
        print(n)
        break
else:
    sys.exit(2)
' "$(pick_regex)")

if [[ ${#lines[@]} -lt 2 ]]; then
  echo "Не найден asset (FLAVOR=$FLAVOR ARCH=$ARCH)" >&2
  exit 1
fi

url="${lines[0]}"
name="${lines[1]}"
mkdir -p "$OUTDIR"
dest="$OUTDIR/$name"
echo "Релиз $tag"
echo "GET $url"
curl -fSL "$url" -o "$dest"
echo "Сохранено: $dest"
