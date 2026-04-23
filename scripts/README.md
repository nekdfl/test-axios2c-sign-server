# Скрипты

Запуск из **корня** репозитория.

## HTTP-прокси (скачивания)

Файл **`scripts/proxy.cfg`**: строки **`use_proxy=true|false`** и **`address=http://user:password@host:port`**. При `use_proxy=true` Python-скрипты скачивания и **curl** в `scripts/linux` (через `_vscodium_server_common.sh`) используют этот прокси; иначе прямой доступ. Альтернативный путь к конфигу: переменная **`VSCODIUM_PROXY_CFG`**.

## Сборка и запуск Axis2/C (Bash)

Нужен **bash** и обычные Unix-утилиты (`find`, `mkdir`, …).

| Скрипт | Назначение |
|--------|------------|
| `build.sh` | `autoreconf` → `configure` + `make` в `build/`; опционально Bear для `compile_commands.json`. |
| `clean.sh` | Удаление артефактов autotools и каталога `build/`. |
| `run.sh` | Запуск `demo-sign-server` (переменные `PORT`, `DEMO_SIGN_AXIS2_REPO`). |

## VSCodium / Open VSX (Python 3)

Нужен интерпретатор **Python 3** (стандартная библиотека + скрипты ниже).

| Скрипт | Назначение |
|--------|------------|
| `openvsx_download_vsix.py` | Скачать `.vsix` по списку `publisher.ext@version` с Open VSX. |
| `vscodium_install_extensions_from_list.py` | По списку для **vscodium-server** (`~/.vscodium-server`): `codium --extensions-dir …/extensions --install-extension …` (или `--openvsx` + `.vsix`; `--desktop` — десктоп). |
| `vscodium_common.py` | Общие функции поиска CLI (импортируется другими скриптами). |
| `vscodium_desktop_download.py` | Последний релиз VSCodium для Windows (zip + Setup + UserSetup). |
| `vscodium_desktop_export_extensions.py` | Экспорт расширений десктопного VSCodium. |
| `vscodium_desktop_install_vsix.py` | Установка `.vsix` в десктопный VSCodium. |
| `vscodium_server_download.py` | Скачать архив **vscodium-server** для Linux. |
| `vscodium_server_export_extensions.py` | Экспорт расширений из `~/.vscodium-server`. |
| `vscodium_server_install_vsix.py` | Установка `.vsix` в vscodium-server. |

Подробности и примеры — в `tech.md/environment.ubuntu.md` (Linux) и `tech.md/environment.windows.md` (Windows).

### По платформам

- **Linux / офлайн (`scripts/linux/`)** — [`README.ubuntu.md`](README.ubuntu.md)
- **Windows (`scripts/windows/*.cmd`)** — [`README.windows.md`](README.windows.md)
