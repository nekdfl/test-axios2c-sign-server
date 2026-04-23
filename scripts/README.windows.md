# Скрипты: Windows (`scripts/windows/*.cmd`)

Общие таблицы Python-скриптов — в [`README.md`](README.md).

Тонкие обёртки для **`cmd.exe`**: вызывают `py -3` или `python` и передают аргументы в соответствующий `.py` в `scripts/`. Общая логика — в **`_invoke_python.cmd`**.

| Файл | Назначение |
|------|------------|
| `vscodium-desktop-download.cmd` | Релиз десктопного VSCodium (zip, Setup, UserSetup). |
| `vscodium-desktop-export-extensions.cmd` | Список расширений десктопа. |
| `vscodium-desktop-install-vsix.cmd` | Установка `.vsix` в десктопный VSCodium. |
| `vscodium-desktop-install-from-list.cmd` | По списку для **десктопного** VSCodium (`--desktop` зашит в обёртку). |
| `vscodium-server-install-from-list.cmd` | По списку для **vscodium-server** (`%USERPROFILE%\.vscodium-server` и т.п.). |
| `download-extensions.cmd` | VSIX с Open VSX по списку. |
| `vscodium-server-*.cmd` | Сервер: скачать архив, экспорт списка, установка `.vsix`. |

См. также `python3 scripts/vscodium_install_extensions_from_list.py -h`.
