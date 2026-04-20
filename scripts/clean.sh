#!/usr/bin/env bash
# Локальная очистка артефактов autotools и сборки (без удаления исходников).
# Из корня: ./scripts/clean.sh
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

if [[ -f "$root/build/Makefile" ]]; then
  (cd "$root/build" && make distclean) || true
fi
rm -rf "$root/build"

if [[ -f Makefile ]]; then
  make distclean || true
fi

submfs=(
  .
  source/backend/include
  source/backend/services
  source/backend/services/demo_sign
  source/backend/src
  source/frontend/client
)
for d in "${submfs[@]}"; do
  rm -f "$root/$d/Makefile" "$root/$d/Makefile.in"
done

rm -rf "$root/autom4te.cache"
rm -f "$root/source/backend/axis2_repo/services/demo_sign/libdemo_sign.so"

rm -f "$root/aclocal.m4" "$root/compile" "$root/config.guess" "$root/config.sub" \
  "$root/configure" "$root/depcomp" "$root/install-sh" "$root/ltmain.sh" \
  "$root/missing" "$root/ar-lib" "$root/config.h" "$root/config.h.in" \
  "$root/config.log" "$root/config.status" "$root/libtool" "$root/stamp-h1"

while IFS= read -r -d '' dir; do
  rm -rf "$dir"
done < <(find "$root" -type d \( -name .deps -o -name .libs \) -print0 2>/dev/null || true)

find "$root" -type f \( -name '*.o' -o -name '*.lo' -o -name '*.la' -o -name '*.a' \) -delete 2>/dev/null || true

echo "Очистка завершена." >&2
