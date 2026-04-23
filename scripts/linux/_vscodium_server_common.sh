#!/usr/bin/env bash
# Общие функции для скриптов vscodium-server (без Python).
# shellcheck shell=bash

# Каталог этого файла (scripts/linux); для proxy.cfg — scripts/proxy.cfg.
_vscodium_common_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Читает scripts/proxy.cfg (или путь из VSCODIUM_PROXY_CFG): при use_proxy=true выставляет http_proxy/https_proxy для curl.
vscodium_apply_proxy_cfg() {
  local cfg
  if [[ -n "${VSCODIUM_PROXY_CFG:-}" ]]; then
    cfg="${VSCODIUM_PROXY_CFG/#\~/$HOME}"
  else
    cfg="${_vscodium_common_dir}/../proxy.cfg"
  fi
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
  [[ -f "$cfg" ]] || return 0
  local use addr line k v klc vl
  use=false
  addr=
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -z "$line" ]] && continue
    [[ "$line" != *"="* ]] && continue
    k="${line%%=*}"
    v="${line#*=}"
    k="$(echo "$k" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    v="$(echo "$v" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    klc=$(printf '%s' "$k" | tr '[:upper:]' '[:lower:]')
    case "$klc" in
      use_proxy)
        vl=$(printf '%s' "$v" | tr '[:upper:]' '[:lower:]')
        case "$vl" in
          true | yes | 1 | on) use=true ;;
          *) use=false ;;
        esac
        ;;
      address) addr="$v" ;;
    esac
  done < "$cfg"
  if [[ "$use" == true && -n "$addr" ]]; then
    export http_proxy="$addr"
    export https_proxy="$addr"
  fi
  return 0
}

vscodium_require_curl_jq() {
  command -v curl >/dev/null 2>&1 || {
    echo "Нужен curl (скачивание)." >&2
    return 1
  }
  command -v jq >/dev/null 2>&1 || {
    echo "Нужен jq (разбор JSON)." >&2
    return 1
  }
  return 0
}

# remote-cli/{code,codium} не подходит для SSH — заменить на ../codium или ../code.
vscodium_resolve_cli() {
  local cli="$1"
  if [[ ! -f "$cli" ]]; then
    printf '%s' "$cli"
    return 0
  fi
  if [[ "$cli" != *"/remote-cli/"* ]]; then
    printf '%s' "$cli"
    return 0
  fi
  local parent_bin
  parent_bin="$(dirname "$(dirname "$cli")")"
  if [[ -x "$parent_bin/codium" ]]; then
    printf '%s' "$parent_bin/codium"
    return 0
  fi
  if [[ -x "$parent_bin/code" ]]; then
    printf '%s' "$parent_bin/code"
    return 0
  fi
  printf '%s' "$cli"
}

vscodium_find_server_cli() {
  local root="${1%/}"
  local explicit="${2:-}"
  local c resolved

  if [[ -n "$explicit" ]]; then
    explicit="${explicit/#\~/$HOME}"
    resolved="$(vscodium_resolve_cli "$explicit")"
    if [[ -f "$resolved" ]]; then
      printf '%s' "$resolved"
      return 0
    fi
    return 1
  fi

  shopt -s nullglob
  for c in "$root"/bin/*/bin/codium "$root"/bin/*/bin/code; do
    [[ -f "$c" ]] || continue
    resolved="$(vscodium_resolve_cli "$c")"
    if [[ -x "$resolved" ]] || [[ -f "$resolved" ]]; then
      printf '%s' "$resolved"
      return 0
    fi
  done
  for c in "$root"/bin/*/bin/remote-cli/code "$root"/bin/*/bin/remote-cli/codium; do
    [[ -f "$c" ]] || continue
    resolved="$(vscodium_resolve_cli "$c")"
    if [[ -x "$resolved" ]] || [[ -f "$resolved" ]]; then
      printf '%s' "$resolved"
      return 0
    fi
  done
  return 1
}
