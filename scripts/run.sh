#!/usr/bin/env bash
# Запуск demo-sign-server после сборки (./scripts/build.sh).
#
#   ./scripts/run.sh [...аргументы сервера...]
#
# Переменные: PORT (по умолчанию 8080), DEMO_SIGN_AXIS2_REPO, AXIS2C_HOME.

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

resolve_axis2c_home() {
  local cand
  for cand in "${AXIS2C_HOME:-}" "$HOME/axis2c-built" "$HOME/axis2c" /usr/local/axis2c /opt/axis2c; do
    [[ -z "$cand" ]] && continue
    cand="${cand/#\~/$HOME}"
    [[ -d "$cand" ]] || continue
    cand=$(CDPATH= cd -- "$cand" && pwd) || continue
    if axis2_prefix_has_headers "$cand"; then
      printf '%s\n' "$cand"
      return 0
    fi
  done
  return 1
}

axis2_sender_in() {
  local lib_parent=$1
  [[ -f "$lib_parent/libaxis2_http_sender.so" || -f "$lib_parent/libaxis2_http_sender.dylib" ]]
}

ensure_repo_lib() {
  local repo=$1 liblink ax axlib
  liblink="$repo/lib"
  if axis2_sender_in "$liblink"; then
    return 0
  fi
  ax=$(resolve_axis2c_home) || {
    echo "Ошибка: Axis2/C ищет транспорты в \$REPO/lib (например libaxis2_http_sender.so), а каталога нет." >&2
    echo "Установите AXIS2C_HOME на корень установки Axis2/C или создайте симлинк repo/lib -> .../lib." >&2
    exit 1
  }
  axlib="$ax/lib"
  [[ -d "$axlib" ]] || die "нет каталога $axlib"
  if [[ -e "$liblink" || -L "$liblink" ]]; then
    if [[ -L "$liblink" || -f "$liblink" ]]; then
      rm -f -- "$liblink"
    elif [[ -d "$liblink" ]]; then
      die "$liblink существует и не симлинк — удалите или переименуйте."
    fi
  fi
  ln -sfn "$axlib" "$liblink" || {
    echo "Не удалось создать симлинк $liblink -> $axlib" >&2
    echo "На Windows включите режим разработчика для symlink или создайте junction вручную." >&2
    exit 1
  }
}

cd "$ROOT" || exit 1

b1="$ROOT/build/source/backend/src/demo-sign-server"
b2="$ROOT/source/backend/src/demo-sign-server"
bin_path=""
if [[ -x "$b1" ]]; then
  bin_path=$b1
elif [[ -x "$b2" ]]; then
  bin_path=$b2
else
  echo "Не найден demo-sign-server (ожидалось $b1)." >&2
  echo "Сначала выполните: ./scripts/build.sh" >&2
  exit 1
fi

if [[ -n "${DEMO_SIGN_AXIS2_REPO:-}" ]]; then
  repo="${DEMO_SIGN_AXIS2_REPO/#\~/$HOME}"
  repo=$(CDPATH= cd -- "$repo" && pwd)
elif [[ -f "$ROOT/build/axis2_repo/axis2.xml" ]]; then
  repo=$(CDPATH= cd -- "$ROOT/build/axis2_repo" && pwd)
else
  repo=$(CDPATH= cd -- "$ROOT/source/backend/axis2_repo" && pwd)
fi

port=${PORT:-8080}
if [[ ! -f "$repo/axis2.xml" ]]; then
  echo "Предупреждение: нет $repo/axis2.xml — проверьте DEMO_SIGN_AXIS2_REPO." >&2
fi

ensure_repo_lib "$repo"

exec "$bin_path" -p "$port" -r "$repo" "$@"
