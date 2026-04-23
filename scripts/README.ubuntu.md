# Скрипты: Linux и офлайн (`scripts/linux/`)

Общие таблицы Python-скриптов — в [`README.md`](README.md).

**На Linux без Python:** сценарии **`*.sh`** — чистый **bash**, плюс **`curl`** и **`jq`**. Общая логика CLI vscodium-server — в **`_vscodium_server_common.sh`** (подключается через `source`).

**Скачивание под Windows с Python:** **`*.cmd`** вызывают **`_invoke_python.cmd`** → `scripts/*.py` (то же назначение, что и `.sh`, но через Python).

| Файл | Назначение |
|------|------------|
| `_invoke_python.cmd` | Запуск `.py` из `scripts/` (Windows). |
| `_vscodium_server_common.sh` | Функции поиска `codium` CLI и замены `remote-cli/*` (для других `.sh`). |
| `vscodium-server-download.cmd` / `.sh` | Архив `vscodium-reh-linux-*.tar.gz` с GitHub в `scripts/linux/` (переменные `ARCH`, `FLAVOR`, `OUTDIR`). |
| `download-extensions.cmd` / `.sh` | VSIX с Open VSX по `vscodium-extensions.txt` → `vsix/`. |
| `vscodium-server-install-from-list.cmd` / `.sh` | По списку для **vscodium-server** (или `--openvsx`). |
| `vscodium-desktop-install-from-list.sh` | По списку для **десктопного** VSCodium (`--desktop`). |
| `vscodium-server-install-vsix.sh` | Установка всех `*.vsix` через бинарник сервера (не Python). |
| `vscodium-server-export-extensions.sh` | Список расширений: CLI или разбор `extensions.json` через `jq`. |
