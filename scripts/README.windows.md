# Скрипты: Windows (`scripts/windows/*.cmd`)

Общие таблицы Python-скриптов — в [`README.md`](README.md).

Тонкие обёртки для **`cmd.exe`**: вызывают `py -3` или `python` и передают аргументы в соответствующий `.py` в `scripts/`. Общая логика — в **`_invoke_python.cmd`**.

Список расширений по умолчанию: **`vscodium-extensions.txt`**. Примеры команд из корня репозитория — в корневом [`README.windows.md`](../README.windows.md) и в **`tech.md/environment.windows.md`**.

Дополнительно: **`install-extensions-from-list.cmd`** — по списку для **vscodium-server** (`%USERPROFILE%\.vscodium-server`); см. `python3 scripts/vscodium_install_extensions_from_list.py -h` (флаг **`--desktop`** — десктопный VSCodium).
