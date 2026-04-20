#!/usr/bin/env bash
# Сборка: autoreconf в корне исходников → configure + make в каталоге build/ (вне дерева исходников).
# Объекты (.o, .lo), libtool-артефакты и копии axis2_repo для запуска создаются только под build/.
#
# Запуск из корня репозитория: ./scripts/build.sh
#
# Префикс Axis2/C (первый найденный с axis2_http_server.h):
#   1) первый аргумент, если это каталог с заголовками (не опция ./configure);
#   2) $AXIS2C_HOME;
#   3) $HOME/axis2c-built, $HOME/axis2c;
#   4) /usr/local/axis2c, /opt/axis2c.
# Остальные аргументы передаются в ./configure.
#
# Каталог сборки: build/ (можно переопределить переменной DEMO_SIGN_BUILD_DIR).
#
# Если установлен Bear (bear), make выполняется под ним — в $DEMO_SIGN_BUILD_DIR
# появится compile_commands.json для clangd / расширения C++ в VSCodium.
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

if ! command -v autoreconf >/dev/null 2>&1; then
  echo "autoreconf не найден. Установите: sudo apt-get install -y autoconf automake libtool m4" >&2
  exit 1
fi

axis2_prefix_has_headers() {
  local p=$1
  [[ -f "$p/include/axis2_http_server.h" ]] && return 0
  if [[ -n "$(find "$p/include" -maxdepth 2 -type f -name axis2_http_server.h 2>/dev/null | head -n 1)" ]]; then
    return 0
  fi
  return 1
}

autoreconf -fi

configure_args=()
axis2_home=

if [[ $# -gt 0 && "${1:-}" != -* ]]; then
  if [[ -d "$1" ]] && axis2_prefix_has_headers "$1"; then
    axis2_home=$(cd "$1" && pwd)
    shift
  elif [[ -d "$1" ]]; then
    echo "Ошибка: в каталоге '$1' нет axis2_http_server.h (include или include/axis2-*)." >&2
    exit 1
  fi
fi

if [[ -z "$axis2_home" ]]; then
  for cand in "${AXIS2C_HOME:-}" "${HOME}/axis2c-built" "${HOME}/axis2c" /usr/local/axis2c /opt/axis2c; do
    [[ -z "$cand" ]] && continue
    if axis2_prefix_has_headers "$cand"; then
      axis2_home=$(cd "$cand" && pwd)
      break
    fi
  done
fi

if [[ -z "$axis2_home" ]]; then
  echo "Ошибка: не найден установленный Apache Axis2/C (файл axis2_http_server.h)." >&2
  echo "  Укажите префикс:  AXIS2C_HOME=/path/to/prefix ./scripts/build.sh" >&2
  echo "  или:            ./scripts/build.sh /path/to/prefix [...опции configure...]" >&2
  echo "  Сборка Axis2/C из исходников — см. README.md и tech.md/." >&2
  exit 1
fi

configure_args=("$@")

builddir=${DEMO_SIGN_BUILD_DIR:-"$root/build"}
mkdir -p "$builddir"

echo "Axis2/C: $axis2_home" >&2
echo "Каталог сборки: $builddir" >&2
(cd "$builddir" && "$root/configure" --with-axis2c="$axis2_home" "${configure_args[@]}")

j="-j${NPROC:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"

compile_commands_nonempty() {
  local f=$1
  [[ -f "$f" ]] && grep -q '"file"' "$f" 2>/dev/null
}

if command -v bear >/dev/null 2>&1; then
  (cd "$builddir" && bear -- make $j)
  if ! compile_commands_nonempty "$builddir/compile_commands.json"; then
    echo "compile_commands.json пуст — делается make clean и полная пересборка под bear (нормально для инкрементальных прогонов)." >&2
    (cd "$builddir" && rm -f compile_commands.json && bear -- make $j clean && bear -- make $j)
  fi
  if compile_commands_nonempty "$builddir/compile_commands.json"; then
    echo "compile_commands.json: $builddir/compile_commands.json (clangd: см. .clangd в корне репозитория)" >&2
  else
    echo "Предупреждение: не удалось заполнить compile_commands.json даже после clean; проверьте bear и логи make." >&2
  fi
else
  make -C "$builddir" $j
  echo "Установите bear (sudo apt-get install -y bear) и пересоберите — появится $builddir/compile_commands.json для IDE." >&2
fi

echo "Готово: $builddir/source/backend/src/demo-sign-server" >&2
echo "Запуск: cd $root && ./scripts/run.sh" >&2
