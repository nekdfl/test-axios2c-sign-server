#!/usr/bin/env bash
# Очистка артефактов autotools и сборки (без удаления исходников).
#
#   ./scripts/clean.sh

set -u

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

rm_f() {
  local f=$1
  [[ -f "$f" || -L "$f" ]] && rm -f -- "$f"
}

rm_rf() {
  local d=$1
  [[ -d "$d" ]] && rm -rf -- "$d"
}

cd "$ROOT" || exit 1

if [[ -f build/Makefile ]]; then
  (cd build && make distclean) || true
fi
rm_rf build

if [[ -f Makefile ]]; then
  make distclean || true
fi

for d in \
  "$ROOT" \
  "$ROOT/source/backend/include" \
  "$ROOT/source/backend/services" \
  "$ROOT/source/backend/services/demo_sign" \
  "$ROOT/source/backend/src" \
  "$ROOT/source/frontend/client"; do
  rm_f "$d/Makefile"
  rm_f "$d/Makefile.in"
done

rm_rf "$ROOT/autom4te.cache"
rm_f "$ROOT/source/backend/axis2_repo/services/demo_sign/libdemo_sign.so"

for name in \
  aclocal.m4 compile config.guess config.sub configure depcomp \
  install-sh ltmain.sh missing ar-lib config.h config.h.in \
  config.log config.status libtool stamp-h1; do
  rm_f "$ROOT/$name"
done

while IFS= read -r -d '' d; do
  rm_rf "$d"
done < <(find "$ROOT" -name .git -prune -o \( -type d \( -name .deps -o -name .libs \) -print0 \))

while IFS= read -r -d '' f; do
  rm_f "$f"
done < <(
  find "$ROOT" -name .git -prune -o \( -type f \( -name '*.o' -o -name '*.lo' -o -name '*.la' -o -name '*.a' \) -print0 \)
)

echo "Очистка завершена." >&2
