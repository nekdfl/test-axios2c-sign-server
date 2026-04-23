#!/usr/bin/env bash
# Сборка: autoreconf в корне → configure + make в build/ (вне дерева исходников).
#
#   ./scripts/build.sh [префикс_axis2c] [...аргументы configure...]
#
# Переменные: AXIS2C_HOME, DEMO_SIGN_BUILD_DIR, NPROC (число параллельных задач make).
# Целевая платформа: Unix (Linux, macOS) с autotools; на Windows без MSYS этот скрипт не применим.

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)

die() {
  echo "Ошибка: $*" >&2
  exit 1
}

axis2_prefix_has_headers() {
  local base inc f rel nf
  base=$(CDPATH= cd -- "$1" && pwd) || return 1
  inc="$base/include"
  if [[ -f "$inc/axis2_http_server.h" ]]; then
    return 0
  fi
  if [[ ! -d "$inc" ]]; then
    return 1
  fi
  while IFS= read -r -d '' f; do
    rel="${f#"$inc"/}"
    nf=$(printf '%s\n' "$rel" | awk -F/ '{print NF}')
    if [[ "$nf" -le 2 ]]; then
      return 0
    fi
  done < <(find "$inc" -name axis2_http_server.h -type f -print0 2>/dev/null)
  return 1
}

if [[ "${OS:-}" = Windows_NT ]] && [[ -z "${MSYSTEM:-}" ]]; then
  echo "Этот build.sh рассчитан на Unix-подобную среду с autoreconf/configure/make. Используйте WSL или MSYS2, либо собирайте вручную." >&2
  exit 1
fi

command -v autoreconf >/dev/null 2>&1 || die "autoreconf не найден. Установите autoconf automake libtool m4."

cd "$ROOT"
autoreconf -fi

axis2=""
if [[ $# -ge 1 && "${1:0:1}" != '-' && -d "$1" ]]; then
  cand=$(CDPATH= cd -- "$1" && pwd)
  if axis2_prefix_has_headers "$cand"; then
    axis2=$cand
    shift
  else
    die "в каталоге '$cand' нет axis2_http_server.h."
  fi
fi
if [[ -z "$axis2" ]]; then
  for cand in "${AXIS2C_HOME:-}" "$HOME/axis2c-built" "$HOME/axis2c" /usr/local/axis2c /opt/axis2c; do
    [[ -z "$cand" ]] && continue
    cand="${cand/#\~/$HOME}"
    [[ -d "$cand" ]] || continue
    cand=$(CDPATH= cd -- "$cand" && pwd) || continue
    if axis2_prefix_has_headers "$cand"; then
      axis2=$cand
      break
    fi
  done
fi
if [[ -z "$axis2" ]]; then
  echo "Ошибка: не найден установленный Apache Axis2/C (файл axis2_http_server.h)." >&2
  echo "  Укажите: AXIS2C_HOME=/path/to/prefix ./scripts/build.sh" >&2
  echo "  или:     ./scripts/build.sh /path/to/prefix [...]" >&2
  exit 1
fi

builddir=${DEMO_SIGN_BUILD_DIR:-"$ROOT/build"}
builddir="${builddir/#\~/$HOME}"
mkdir -p "$builddir"
builddir=$(CDPATH= cd -- "$builddir" && pwd)

echo "Axis2/C: $axis2" >&2
echo "Каталог сборки: $builddir" >&2

(cd "$builddir" && "$ROOT/configure" --with-axis2c="$axis2" "$@")

nproc_val=${NPROC:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)}
if [[ -z "${nproc_val:-}" || ! "$nproc_val" =~ ^[0-9]+$ ]]; then
  nproc_val=$(nproc 2>/dev/null || echo 4)
fi
if [[ ! "$nproc_val" =~ ^[0-9]+$ ]]; then
  nproc_val=4
fi
j="-j$nproc_val"

compile_commands_nonempty() {
  local path=$1
  [[ -f "$path" ]] && grep -q '"file"' "$path"
}

cc_json="$builddir/compile_commands.json"
if command -v bear >/dev/null 2>&1; then
  (cd "$builddir" && bear -- make $j) || exit $?
  if ! compile_commands_nonempty "$cc_json"; then
    echo "compile_commands.json пуст — делается make clean и полная пересборка под bear." >&2
    rm -f "$cc_json"
    (cd "$builddir" && bear -- make $j clean)
    (cd "$builddir" && bear -- make $j)
  fi
  if compile_commands_nonempty "$cc_json"; then
    echo "compile_commands.json: $cc_json" >&2
  else
    echo "Предупреждение: не удалось заполнить compile_commands.json." >&2
  fi
else
  (cd "$builddir" && make $j)
  echo "Установите bear и пересоберите — появится $cc_json для IDE." >&2
fi

bin_path="$builddir/source/backend/src/demo-sign-server"
echo "Готово: $bin_path" >&2
echo "Запуск: cd $ROOT && ./scripts/run.sh" >&2
