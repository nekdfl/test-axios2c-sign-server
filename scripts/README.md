# Скрипты (Python 3)

Запуск из **корня** репозитория. Нужен только интерпретатор Python 3 (стандартная библиотека).

## Сборка и запуск Axis2/C

| Скрипт | Назначение |
|--------|------------|
| `build.py` | `autoreconf` → `configure` + `make` в `build/`; опционально Bear для `compile_commands.json`. |
| `clean.py` | Удаление артефактов autotools и каталога `build/`. |
| `run.py` | Запуск `demo-sign-server` (переменные `PORT`, `DEMO_SIGN_AXIS2_REPO`). |

## VSCodium / Open VSX

| Скрипт | Назначение |
|--------|------------|
| `openvsx_download_vsix.py` | Скачать `.vsix` по списку `publisher.ext@version` с Open VSX. |
| `vscodium_common.py` | Общие функции поиска CLI (импортируется другими скриптами). |
| `vscodium_desktop_download.py` | Последний релиз VSCodium для Windows (zip + Setup + UserSetup). |
| `vscodium_desktop_export_extensions.py` | Экспорт расширений десктопного VSCodium. |
| `vscodium_desktop_install_vsix.py` | Установка `.vsix` в десктопный VSCodium. |
| `vscodium_server_download.py` | Скачать архив **vscodium-server** для Linux. |
| `vscodium_server_export_extensions.py` | Экспорт расширений из `~/.vscodium-server`. |
| `vscodium_server_install_vsix.py` | Установка `.vsix` в vscodium-server. |

Подробности и примеры — в `tech.md/environment.md`.

### Windows (`scripts/windows/*.cmd`)

Тонкие обёртки для `cmd.exe`: вызывают `py -3` или `python` и передают аргументы в соответствующий `.py` в `scripts/`. Общая логика — в `_invoke_python.cmd`.

### Linux / офлайн (`scripts/linux/`)

**На Linux без Python:** сценарии **`*.sh`** — чистый **bash**, плюс **`curl`** и **`jq`**. Общая логика CLI vscodium-server — в **`_vscodium_server_common.sh`** (подключается через `source`).

**Скачивание под Windows с Python:** **`*.cmd`** вызывают **`_invoke_python.cmd`** → `scripts/*.py` (то же назначение, что и `.sh`, но через Python).

| Файл | Назначение |
|------|------------|
| `_invoke_python.cmd` | Запуск `.py` из `scripts/` (Windows). |
| `_vscodium_server_common.sh` | Функции поиска `codium` CLI и замены `remote-cli/*` (для других `.sh`). |
| `download-vscodium-server.cmd` / `.sh` | Архив `vscodium-reh-linux-*.tar.gz` с GitHub в `scripts/linux/` (переменные `ARCH`, `FLAVOR`, `OUTDIR`). |
| `download-extensions.cmd` / `.sh` | VSIX с Open VSX по `vscodium-extensions.txt` → `vsix/`. |
| `install-vscodium-server-extensions.sh` | Установка всех `*.vsix` через бинарник сервера (не Python). |
| `export-vscodium-server-extensions.sh` | Список расширений: CLI или разбор `extensions.json` через `jq`. |
