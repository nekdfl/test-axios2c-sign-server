#!/usr/bin/env bash
# Скачивание VSIX из Open VSX по списку vscodium-server расширений.
# Формат списка: publisher.extension@version (по строке).
#
# Аргументы:
#   1) файл списка   (по умолчанию vscodium-server-extensions.txt)
#   2) каталог VSIX  (по умолчанию vsix)
set -euo pipefail

LIST="${1:-vscodium-server-extensions.txt}"
OUT="${2:-vsix}"

if [[ ! -f "$LIST" ]]; then
  echo "Файл списка не найден: $LIST" >&2
  exit 1
fi

mkdir -p "$OUT"

python3 - "$LIST" "$OUT" <<'PY'
import json, pathlib, sys, urllib.error, urllib.request

def fetch_json(url: str):
    req = urllib.request.Request(url, headers={"User-Agent": "vscodium-server-vsix-fetch"})
    with urllib.request.urlopen(req, timeout=120) as r:
        return json.loads(r.read().decode())

def main():
    list_path, out_dir = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    for raw in list_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#"):
            continue
        if "@" not in line:
            print("пропуск (нет @):", line, file=sys.stderr)
            continue

        ext_id, _, ver = line.partition("@")
        ext_id, ver = ext_id.strip(), ver.strip()
        if "." not in ext_id:
            print("пропуск (ожидался publisher.extension):", line, file=sys.stderr)
            continue

        dot = ext_id.index(".")
        namespace, name = ext_id[:dot], ext_id[dot + 1:]
        meta_url = f"https://open-vsx.org/api/{namespace}/{name}/{ver}"
        try:
            meta = fetch_json(meta_url)
            dl = meta["files"]["download"]
            leaf = dl.rsplit("/", 1)[-1]
            dest = out_dir / leaf
            req = urllib.request.Request(dl, headers={"User-Agent": "vscodium-server-vsix-fetch"})
            with urllib.request.urlopen(req, timeout=120) as resp, dest.open("wb") as out:
                out.write(resp.read())
            print(dest)
        except urllib.error.HTTPError as e:
            print(f"HTTP {e.code}: {line}", file=sys.stderr)
        except Exception as e:
            print(f"ошибка {line}: {e}", file=sys.stderr)

if __name__ == "__main__":
    main()
PY

echo "Готово. Каталог: $OUT"
