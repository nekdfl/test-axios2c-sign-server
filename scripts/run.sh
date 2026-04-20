#!/usr/bin/env bash
# Запуск demo-sign-server (после успешной сборки scripts/build.sh).
#
# Из корня: ./scripts/run.sh
#
# Переменные окружения:
#   PORT                  — порт HTTP (по умолчанию 8080)
#   DEMO_SIGN_AXIS2_REPO  — каталог репозитория Axis2 (axis2.xml + services/); по умолчанию
#                            build/axis2_repo после сборки в build/, иначе source/backend/axis2_repo
#
# Дополнительные аргументы передаются серверу (см. build/source/backend/src/demo-sign-server -h после сборки).
#
# Примеры:
#   ./scripts/run.sh
#   PORT=9090 ./scripts/run.sh
#   ./scripts/run.sh -l 3
set -euo pipefail

axis2_prefix_has_headers() {
  local p=$1
  [[ -f "$p/include/axis2_http_server.h" ]] && return 0
  if [[ -n "$(find "$p/include" -maxdepth 2 -type f -name axis2_http_server.h 2>/dev/null | head -n 1)" ]]; then
    return 0
  fi
  return 1
}

resolve_axis2c_home() {
  local cand
  for cand in "${AXIS2C_HOME:-}" "${HOME}/axis2c-built" "${HOME}/axis2c" /usr/local/axis2c /opt/axis2c; do
    [[ -z "$cand" || ! -d "$cand" ]] && continue
    if axis2_prefix_has_headers "$cand"; then
      cd "$cand" && pwd
      return 0
    fi
  done
  return 1
}

ensure_repo_lib() {
  local repo=$1
  if [[ -f "$repo/lib/libaxis2_http_sender.so" ]]; then
    return 0
  fi
  local axhome
  if ! axhome=$(resolve_axis2c_home); then
    echo "Ошибка: Axis2/C ищет транспорты в \$REPO/lib (например libaxis2_http_sender.so), а каталога нет." >&2
    echo "Установите AXIS2C_HOME на корень установки Axis2/C (рядом include/ и lib/) или создайте симлинк $repo/lib -> .../lib." >&2
    exit 1
  fi
  if [[ -e "$repo/lib" && ! -L "$repo/lib" ]]; then
    echo "Ошибка: $repo/lib существует и не симлинк — удалите или переименуйте каталог." >&2
    exit 1
  fi
  ln -sfn "$axhome/lib" "$repo/lib"
}

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

if [[ -x "$root/build/source/backend/src/demo-sign-server" ]]; then
  bin="$root/build/source/backend/src/demo-sign-server"
elif [[ -x "$root/source/backend/src/demo-sign-server" ]]; then
  bin="$root/source/backend/src/demo-sign-server"
else
  echo "Не найден demo-sign-server (ожидалось $root/build/source/backend/src/demo-sign-server)." >&2
  echo "Сначала выполните: ./scripts/build.sh" >&2
  exit 1
fi

if [[ -n "${DEMO_SIGN_AXIS2_REPO:-}" ]]; then
  repo=$DEMO_SIGN_AXIS2_REPO
elif [[ -f "$root/build/axis2_repo/axis2.xml" ]]; then
  repo=$root/build/axis2_repo
else
  repo=$root/source/backend/axis2_repo
fi
port=${PORT:-8080}

if [[ ! -f "$repo/axis2.xml" ]]; then
  echo "Предупреждение: нет $repo/axis2.xml — проверьте путь DEMO_SIGN_AXIS2_REPO." >&2
fi

ensure_repo_lib "$repo"

exec "$bin" -p "$port" -r "$repo" "$@"
