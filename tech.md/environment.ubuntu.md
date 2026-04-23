# Сборочное окружение Ubuntu 24.04 (объединённый документ)

В одном файле сохранены **два варианта** инструкций:

| Часть | Источник | Сборка / запуск / очистка | VSCodium и офлайн |
| ----- | -------- | ------------------------- | ------------------- |
| **I** | полный текст в разделе ниже (краткий указатель: [`environment.md`](environment.md)) | `./scripts/build.sh`, `./scripts/run.sh`, `./scripts/clean.sh` | Сборка/запуск на **bash**; для VSIX и VSCodium — **Python** в `scripts/` + `scripts/linux/*.sh` (см. `scripts/README.md`, по Linux — `scripts/README.ubuntu.md`) |
| **II** | материал из `_ubuntu` | `./scripts/build.sh`, `./scripts/run.sh`, `./scripts/clean.sh` | `scripts/linux/*.sh` и `scripts/windows/*.ps1` (оболочечный контур) |

**Практика:** в текущем дереве репозитория **части I и II** согласованы: сборка и запуск сервера — через `**./scripts/*.sh**`. Различия в основном в оформлении и в разделе про VSCodium.

---

# Часть I — Bash-скрипты (сборка и запуск)

# Сборочное окружение с нуля (Ubuntu 24.04)

Этот документ описывает, как на **чистой Ubuntu 24.04** воспроизвести окружение для **сборки**, **запуска** и **комфортной работы в VSCodium** (подсветка, автодополнение C, отладка) для репозитория **demo-sign-server**.

---

## Содержание

1. [Краткий порядок действий](#1-краткий-порядок-действий)
2. [Пакеты APT](#2-пакеты-apt)
3. [Apache Axis2/C: установка префикса](#3-apache-axis2c-установка-префикса)
4. [Клонирование проекта и первый запуск сборки](#4-клонирование-проекта-и-первый-запуск-сборки)
5. [Скрипт scripts/build.sh](#5-скрипт-scriptsbuildsh)
6. [Скрипт scripts/run.sh](#6-скрипт-scriptsrunsh)
7. [Скрипт scripts/clean.sh](#7-скрипт-scriptscleansh)
8. [VSCodium: расширения и настройки для C](#8-vscodium-расширения-и-настройки-для-c) (Python-скрипты в `**scripts/`** — см. подраздел ниже в том же разделе)
9. [Проверочный чеклист](#9-проверочный-чеклист)

---

## 1. Краткий порядок действий

1. Обновить индекс пакетов и установить зависимости из [раздела 2](#2-пакеты-apt).
2. Собрать и установить **Apache Axis2/C** в каталог-префикс (например `$HOME/axis2c-built`), см. [раздел 3](#3-apache-axis2c-установка-префикса).
3. Клонировать этот репозиторий, задать `AXIS2C_HOME`, выполнить `./scripts/build.sh`.
4. Один раз запустить `./scripts/run.sh` (или убедиться в симлинке `axis2_repo/lib`) — см. [раздел 6](#6-скрипт-scriptsrunsh).
5. Настроить **VSCodium** по [разделу 8](#8-vscodium-расширения-и-настройки-для-c).

---

## 2. Пакеты APT

Установите инструменты сборки C, Autotools, заголовки для типичной связки Axis2 (libxml2, zlib), а также **Bear** для генерации базы компиляции под IDE:

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential pkg-config \
  git curl ca-certificates \
  autoconf automake libtool m4 \
  libxml2-dev zlib1g-dev \
  bear \
  clangd \
  gdb
```


| Пакет / группа                                  | Зачем                                                                                  |
| ----------------------------------------------- | -------------------------------------------------------------------------------------- |
| **build-essential**                             | gcc, g++, make                                                                         |
| **pkg-config**                                  | подсказки зависимостей при сборке Axis2/C и связанных библиотек                        |
| **git**, **curl**                               | клонирование репозиториев и загрузка архивов                                           |
| **autoconf**, **automake**, **libtool**, **m4** | `./autoreconf`, Libtool для проекта и часто для Axis2/C из исходников                  |
| **libxml2-dev**, **zlib1g-dev**                 | заголовки и symlink’и для `-lxml2`/`-lz` при проверке линковки в `configure`           |
| **bear**                                        | запись `**build/compile_commands.json`** при сборке под Bear (clangd / автодополнение) |
| **clangd**                                      | language server для C/C++ (нужен для расширения clangd в VSCodium)                     |
| **gdb**                                         | отладка из `**.vscode/launch.json`**                                                   |


Клиент `**source/frontend/client/demo.py`** использует только стандартную библиотеку Python 3; отдельные пакеты не нужны. При необходимости установите интерпретатор:

```bash
sudo apt-get install -y python3
```

---

## 3. Apache Axis2/C: установка префикса

Проект **не поставляет** бинарники Axis2 внутри себя: нужен **установленный префикс** с заголовками (`include/…/axis2_http_server.h` или `include/axis2-*/…`) и библиотеками в `**lib/`**.

Рекомендации для **Ubuntu 24.04 amd64**:

- Собирать Axis2/C **из исходников** в пользовательский префикс, например `**$HOME/axis2c-built`**. Готовые старые бинарные сборки с archive.apache.org часто **32-bit** и не подходят.
- Исходники и инструкции: [Apache Axis2/C](https://axis.apache.org/axis2/c/core/), репозиторий [axis-axis2-c-core](https://github.com/apache/axis-axis2-c-core).

После установки задайте переменную окружения (добавьте в `~/.bashrc` при необходимости):

```bash
export AXIS2C_HOME="$HOME/axis2c-built"
```

Проверка:

```bash
test -f "$AXIS2C_HOME/include/axis2_http_server.h" || \
  find "$AXIS2C_HOME/include" -name axis2_http_server.h -print -quit
```

Если `./configure` проекта или Axis2 ругается на **libxml2**/**zlib**, убедитесь, что установлены `**libxml2-dev`** и `**zlib1g-dev`** (см. раздел 2). При необходимости при конфигурировании можно передать, например:

```bash
LDFLAGS='-L/usr/lib/x86_64-linux-gnu' ./configure --with-axis2c="$AXIS2C_HOME"
```

---

## 4. Клонирование проекта и первый запуск сборки

```bash
git clone git@github.com:nekdfl/test-axios2c-sign-server.git demo-sign-server
cd demo-sign-server
chmod +x scripts/build.sh scripts/clean.sh scripts/run.sh
export AXIS2C_HOME="$HOME/axis2c-built"   # ваш префикс Axis2/C
./scripts/build.sh
```

Успешный результат: появляются `**build/source/backend/src/demo-sign-server**` и дерево `**build/axis2_repo/**` (включая копию `**axis2.xml**` и сервис `**demo_sign**`).

Запуск сервера удобнее через `**./scripts/run.sh**` (см. [раздел 6](#6-скрипт-scriptsrunsh)).

---

## 5. Скрипт `scripts/build.sh`

**Назначение:** одна команда для полного цикла **autoreconf → configure → make** в **отдельном каталоге сборки** (по умолчанию `**build/`** в корне проекта).

Кратко по шагам:

1. `**autoreconf -fi`** в корне исходников — генерируются `**configure`** и `**Makefile.in`** рядом с `**Makefile.am**` (эти файлы обычно не коммитятся).
2. Поиск префикса Axis2/C с заголовком `**axis2_http_server.h**`: первый аргумент скрипта (если это каталог с заголовками), затем `**$AXIS2C_HOME**`, затем перебор типичных путей (`$HOME/axis2c-built`, `$HOME/axis2c`, `/usr/local/axis2c`, `/opt/axis2c`).
3. `**mkdir**` каталога сборки (`**DEMO_SIGN_BUILD_DIR**`, по умолчанию `**build/**`).
4. Запуск `**../configure**` из этого каталога с `**--with-axis2c=...**` и любыми дополнительными аргументами, переданными в `**./scripts/build.sh**` после префикса Axis2 (если есть).
5. `**make**` в каталоге сборки. Если установлен `**bear**`, сборка выполняется под `**bear**` и создаётся `**build/compile_commands.json**` для IDE. Если после инкрементальной сборки файл пустой (`**[]**`), скрипт выполняет `**make clean**` и повторную сборку под Bear — иначе clangd не получает команд компиляции.

Примеры:

```bash
./scripts/build.sh
AXIS2C_HOME="$HOME/axis2c-built" ./scripts/build.sh
./scripts/build.sh "$HOME/axis2c-built" --prefix=/usr/local
DEMO_SIGN_BUILD_DIR="$PWD/out" ./scripts/build.sh
```

---

## 6. Скрипт `scripts/run.sh`

**Назначение:** запуск `**demo-sign-server`** с разумными значениями по умолчанию.

Поведение:

- Выбирает бинарник: сначала `**build/source/backend/src/demo-sign-server`**, иначе `**source/backend/src/demo-sign-server`** (in-tree сборка).
- Репозиторий Axis2 (`**-r**`): переменная `**DEMO_SIGN_AXIS2_REPO**`, иначе если есть `**build/axis2_repo/axis2.xml**` — `**build/axis2_repo**`, иначе `**source/backend/axis2_repo**`.
- Порт: `**PORT**` (по умолчанию **8080**); остальные аргументы передаются серверу (например `**-l 3`**).
- `**ensure_repo_lib`:** в каталоге репозитория должен быть каталог `**lib/`** с библиотеками транспорта Axis2 (например `**libaxis2_http_sender.so`**). Если его нет, скрипт создаёт симлинк `**$REPO/lib` → `$AXIS2C_HOME/lib`** (или другой найденный префикс с заголовками Axis2). Без этого движок Axis2 не стартует.

Примеры:

```bash
./scripts/run.sh
PORT=9090 ./scripts/run.sh
DEMO_SIGN_AXIS2_REPO=/path/to/repo ./scripts/run.sh -l 3
```

---

## 7. Скрипт `scripts/clean.sh`

**Назначение:** убрать локально сгенерированные артефакты Autotools и сборки, **не удаляя исходники** `.c`/`.h`/`.md`.

Порядок (упрощённо):

1. Если есть `**build/Makefile`** — `**make distclean`** в `**build/`**, затем удаление всего каталога `**build/`**.
2. Если в корне есть `**Makefile**` — `**make distclean**` (остатки in-tree сборки).
3. Удаление `**Makefile**` и `**Makefile.in**` в перечисленных подкаталогах исходников.
4. Удаление `**autom4te.cache**`, корневых `**configure**`, `**config.***`, вспомогательных скриптов autotools, `**libtool**`, `**stamp-h1**` и т.д.
5. Удаление каталогов `**.deps**` / `**.libs**`, объектных и libtool-файлов (`***.o**`, `***.lo**`, `***.la**`, `***.a**`).
6. Удаление копии `**source/backend/axis2_repo/services/demo_sign/libdemo_sign.so**` в исходном дереве (если осталась от старой схемы).

После `**./scripts/clean.sh**` снова нужны `**./scripts/build.sh**` (или ручной **autoreconf** + **configure** + **make**).

---

## 8. VSCodium: расширения и настройки для C

### Расширения

Рекомендуется одно из двух (не оба одновременно во избежание конфликтов интеллисенса):

1. **clangd** (LLVM) — хорошо дружит с `**compile_commands.json`**.
2. Либо **C/C++** (Microsoft / openvsx-сборка для VSCodium) — тогда можно использовать `**c_cpp_properties.json`**; для Autotools удобнее всё же опираться на `**compile_commands.json`**.

Для **отладки** по `**launch.json`** нужен отладчик из набора **C/C++** (**cppdbg** + **gdb**) или альтернатива (**CodeLLDB**) с перенастройкой конфигураций.

### База компиляции и `.clangd`

1. Установите `**bear`** (раздел 2) и выполните `**./scripts/build.sh`**, чтобы в `**build/`** появился непустой `**compile_commands.json**`.
2. В корне репозитория файл `**.clangd**` содержит указание каталога базы:
  ```yaml
   CompileDatabase: build
  ```
3. Если каталог сборки другой (`**DEMO_SIGN_BUILD_DIR**`), поправьте `**CompileDatabase**` в `**.clangd**` на соответствующее имя каталога относительно корня проекта.

### Файлы в `.vscode/` (в репозитории или скопируйте вручную)

- `**tasks.json**` — задача **«Autotools: make in build»** для пре-сборки перед отладкой.
- `**launch.json`** — профили **Debug: demo-sign-server** (порт 8080 или 9090 и т.д.).
- `**settings.json`** — при необходимости скрытие служебных файлов из проводника (`**files.exclude`** для `**.clangd`** и т.п.).
- `**c_cpp_properties.json`** — базовые пути; при наличии `**compile_commands.json**` основная нагрузка на интеллисенс ложится на него и **clangd**.

### Переменные окружения в терминале VSCodium

Чтобы `**./scripts/run.sh`** и поиск Axis2 находили префикс, в `**~/.bashrc`** или в настройках терминала IDE задайте:

```bash
export AXIS2C_HOME="$HOME/axis2c-built"
```

### Готовые скрипты в репозитории (`scripts/`)

Ниже — сценарии на **Python 3** (только стандартная библиотека): **экспорт списка расширений**, **скачивание VSIX с Open VSX**, **офлайн-установка**, **загрузка VSCodium** (десктоп Windows и **vscodium-server** для Linux). Запуск из **корня** репозитория: `python3 scripts/<имя>.py …` (на Windows подойдёт и `py -3`).

**Linux: vscodium-server (удалённая машина / VM)**


| Файл | Назначение |
| ---- | ---------- |
| `scripts/vscodium_server_download.py` | Скачивает архив **vscodium-server** с GitHub: `vscodium-reh-linux-${ARCH}-*.tar.gz` или `vscodium-reh-web-linux-…`. Аргументы: `--arch`, `--flavor` (`reh` или `reh-web`), `--outdir`; те же значения можно задать переменными `ARCH`, `FLAVOR`, `OUTDIR`. |
| `scripts/vscodium_server_export_extensions.py` | Экспорт из `~/.vscodium-server`: CLI или `extensions.json` → файл (`--out`, по умолчанию `vscodium-server-extensions.txt`). Переменные: `OUT`, `SERVER_ROOT`, `SERVER_CLI`, `SERVER_EXTENSIONS_JSON`. |
| `scripts/openvsx_download_vsix.py` | Список VSIX с Open VSX: аргументы `[файл_списка] [каталог_vsix]` (по умолчанию `vscodium-server-extensions.txt` и `vsix`). |
| `scripts/vscodium_server_install_vsix.py` | Установка всех `*.vsix` в `~/.vscodium-server/extensions` через server CLI. Переменные / флаги: `VSIX_DIR`, `SERVER_ROOT`, `SERVER_CLI`. |

Для `--server-cli` в обычной консоли/SSH используйте **`bin/<commit>/bin/codium`** (или **`code`**), а не **`bin/.../remote-cli/...`** — иначе возможно сообщение *«Command is only available in WSL or inside a Visual Studio Code terminal»*.

Примеры:

```bash
FLAVOR=reh ARCH=x64 OUTDIR="$HOME/dist" python3 scripts/vscodium_server_download.py
OUT=my-ext.txt python3 scripts/vscodium_server_export_extensions.py
python3 scripts/openvsx_download_vsix.py vscodium-server-extensions.txt vsix
VSIX_DIR=vsix python3 scripts/vscodium_server_install_vsix.py
```

**Офлайн:** на машине **с интернетом** скачайте архив сервера и VSIX в **`scripts/linux/`**: под **Linux** — **`scripts/linux/vscodium-server-download.sh`** и **`download-extensions.sh`** (bash, нужны **`curl`** и **`jq`**); под **Windows** — **`scripts/linux/*.cmd`** и Python 3. Затем скопируйте репозиторий на изолированный Linux и выполните установку **`vscodium-server-install-vsix.sh`** (без Python). Подробности — `scripts/README.ubuntu.md` (и общий `scripts/README.md`).

```bash
# машина с интернетом — Linux:
#   ./scripts/linux/vscodium-server-download.sh
#   ./scripts/linux/download-extensions.sh
# или Windows + Python:
#   scripts\linux\vscodium-server-download.cmd
#   scripts\linux\download-extensions.cmd

# офлайн Linux-хост — распаковка vscodium-server, затем:
./scripts/linux/vscodium-server-install-vsix.sh
```

**Windows: VSCodium (десктоп)**


| Файл | Назначение |
| ---- | ---------- |
| `scripts/vscodium_desktop_download.py` | Последний релиз: portable **ZIP**, **Setup.exe**, **UserSetup.exe**. Флаги: `--arch` (`x64` или `arm64`), `--outdir`. |
| `scripts/vscodium_desktop_export_extensions.py` | Список расширений в файл; опционально путь к `VSCodium.exe` вторым аргументом. |
| `scripts/openvsx_download_vsix.py` | Тот же сценарий VSIX; по умолчанию список `vscodium-extensions.txt` в `scripts/windows/` — укажите путь явно при необходимости. |
| `scripts/vscodium_desktop_install_vsix.py` | Установка всех `*.vsix` из каталога через CLI десктопа. |

Примеры:

```bash
python3 scripts/vscodium_desktop_download.py --arch x64 --outdir .
python3 scripts/vscodium_desktop_export_extensions.py vscodium-extensions.txt
python3 scripts/openvsx_download_vsix.py scripts/windows/vscodium-extensions.txt vsix
python3 scripts/vscodium_desktop_install_vsix.py vsix
```

Общая логика поиска CLI для десктопа — в `scripts/vscodium_common.py`.

**Замечание по платформам:** VSIX, скачанные под **Windows**, не переносите на **Linux** (и наоборот), если в расширении есть нативные двоичные файлы — ставьте пакеты под целевую ОС и архитектуру.

### Снимок установленных расширений (узел разработки)

Ниже — расширения, обнаруженные при анализе каталога `**~/.vscodium-server/extensions`** (типичный путь для **Remote SSH**: расширения ставятся на удалённую машину). На локальной установке без SSH список совпадает с содержимым `**~/.vscode-oss/extensions`** или `**~/.VSCodium/extensions`** (или выводом CLI, см. ниже).


| Идентификатор (`publisher.name`)             | Версия    |
| -------------------------------------------- | --------- |
| `13xforever.language-x86-64-assembly`        | 3.1.5     |
| `batisteo.vscode-django`                     | 1.8.0     |
| `bbenoist.doxygen`                           | 1.0.0     |
| `cheshirekow.cmake-format`                   | 0.6.13    |
| `cschlosser.doxdocgen`                       | 1.4.0     |
| `donjayamanne.githistory`                    | 0.6.20    |
| `donjayamanne.python-environment-manager`    | 1.2.7     |
| `donjayamanne.python-extension-pack`         | 1.7.0     |
| `franneck94.c-cpp-runner`                    | 9.4.7     |
| `franneck94.vscode-c-cpp-config`             | 6.3.0     |
| `franneck94.vscode-c-cpp-dev-extension-pack` | 0.10.0    |
| `hbenl.vscode-test-explorer`                 | 2.22.1    |
| `jeff-hykin.better-cpp-syntax`               | 1.27.1    |
| `kevinrose.vsc-python-indent`                | 1.21.0    |
| `kylinideteam.cppdebug`                      | 0.2.0     |
| `llvm-vs-code-extensions.vscode-clangd`      | 0.4.0     |
| `mhutchie.git-graph`                         | 1.30.0    |
| `ms-azuretools.vscode-containers`            | 2.4.1     |
| `ms-azuretools.vscode-docker`                | 2.0.0     |
| `ms-ceintl.vscode-language-pack-ru`          | 1.110.0   |
| `ms-python.autopep8`                         | 2025.2.0  |
| `ms-python.black-formatter`                  | 2025.2.0  |
| `ms-python.debugpy`                          | 2025.18.0 |
| `ms-python.python`                           | 2026.4.0  |
| `ms-python.vscode-python-envs`               | 1.28.0    |
| `ms-vscode.cmake-tools`                      | 1.23.51   |
| `ms-vscode.cpptools-themes`                  | 2.0.0     |
| `ms-vscode.test-adapter-converter`           | 0.2.1     |
| `njpwerner.autodocstring`                    | 0.6.1     |
| `oderwat.indent-rainbow`                     | 8.3.1     |
| `redhat.vscode-yaml`                         | 1.22.0    |
| `shd101wyy.markdown-preview-enhanced`        | 0.8.22    |
| `streetsidesoftware.code-spell-checker`      | 4.5.6     |
| `vadimcn.vscode-lldb`                        | 1.12.1    |
| `wholroyd.jinja`                             | 0.0.8     |


**Экспорт актуального списка на машине с интернетом** — для Linux VM: `**python3 scripts/vscodium_server_export_extensions.py**` (экспорт из `~/.vscodium-server/extensions`). Для Windows (десктоп): `**python3 scripts/vscodium_desktop_export_extensions.py**`.

```bash
# Linux VM (vscodium-server)
python3 scripts/vscodium_server_export_extensions.py

# при необходимости путь к серверу можно переопределить
SERVER_ROOT=$HOME/.vscodium-server OUT=my-ext.txt python3 scripts/vscodium_server_export_extensions.py
```

Если команда недоступна в PATH, но известен каталог расширений, можно вытащить пары `id@version` из `**extensions.json**`:

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / ".vscodium-server/extensions/extensions.json"
for item in json.loads(p.read_text(encoding="utf-8")):
    ident = item.get("identifier") or {}
    ext_id = ident.get("id")
    if ext_id:
        print(f"{ext_id}@{item.get('version','?')}")
PY
```

Путь к `**extensions.json**` замените на свой (например `**~/.vscode-oss/extensions/extensions.json**` для локального VSCodium).

### Офлайн: скачивание VSIX и установка в VSCodium

**Идея:** на компьютере с интернетом скачать файлы `**.vsix`** из каталога [Open VSX](https://open-vsx.org/) (его использует VSCodium по умолчанию), перенести каталог на изолированную машину (флешка, внутренняя сеть), установить локально через `**--install-extension`**.

**1. Файл со списком** `vscodium-server-extensions.txt`, по строке на расширение (`publisher.extension@version`):

```text
llvm-vs-code-extensions.vscode-clangd@0.4.0
ms-python.python@2026.4.0
```

**2. Скачивание VSIX** — из корня репозитория, на **той же платформе**, где будет установка расширений (см. `**scripts/openvsx_download_vsix.py**` в таблице выше). Логика: запрос `**GET https://open-vsx.org/api/{namespace}/{name}/{version}`**, поле `**files.download`**; разбор id — первый символ `**.**` перед именем расширения в пути API (как в скрипте).

```bash
# Linux или Windows (один и тот же скрипт)
python3 scripts/openvsx_download_vsix.py vscodium-server-extensions.txt vsix
```

Если какое‑то расширение отсутствует в Open VSX (или нужна сборка только под **VS Marketplace**), его придётся получить `**.vsix`** вручную с машины, где есть доступ к нужному источнику, либо использовать уже установленную копию из каталога расширений (подмножество расширений можно **заархивировать целиком** каталог `**…/extensions/`** и перенести на однотипную ОС/архитектуру — это быстрее, но менее переносимо между разными платформами).

**3. Установка без интернета** на целевом компьютере:

```bash
# Linux (vscodium-server)
VSIX_DIR=vsix python3 scripts/vscodium_server_install_vsix.py
```

```bash
# Windows (десктоп VSCodium)
python3 scripts/vscodium_desktop_install_vsix.py vsix
```

Вручную одной командой (server):

```bash
VSIX_DIR=vsix python3 scripts/vscodium_server_install_vsix.py
```

Одиночный пакет: задайте `**SERVER_CLI**` / `--server-cli` и каталог `**VSIX_DIR**` с одним `.vsix`.

---

## 9. Проверочный чеклист


| Шаг | Действие                                                                                                    |
| --- | ----------------------------------------------------------------------------------------------------------- |
| 1   | `apt-get install` из [раздела 2](#2-пакеты-apt) выполнен                                                    |
| 2   | Axis2/C собран, `**AXIS2C_HOME**` указывает на префикс с `**include**` и `**lib**`                          |
| 3   | `**./scripts/build.sh**` завершается без ошибки, есть `**build/source/backend/src/demo-sign-server**`       |
| 4   | `**./scripts/run.sh**` запускает сервер; при необходимости создан симлинк `**…/axis2_repo/lib**`            |
| 5   | `**build/compile_commands.json**` не пустой (после Bear); **clangd** подхватывает проект при открытии корня |
| 6   | (Опционально) отладка по **F5** с конфигурации из `**.vscode/launch.json`**                                 |


Дальше по коду и Axis2: остальные файлы в `**tech.md/`** ([README](README.md)).

---

# Часть II — оболочечные скрипты (материал из `_ubuntu`)

# Сборочное окружение с нуля (Ubuntu 24.04)

Этот документ описывает, как на **чистой Ubuntu 24.04** воспроизвести окружение для **сборки**, **запуска** и **комфортной работы в VSCodium** (подсветка, автодополнение C, отладка) для репозитория **demo-sign-server**.

---

## Содержание

1. [Краткий порядок действий](#1-краткий-порядок-действий)
2. [Пакеты APT](#2-пакеты-apt)
3. [Apache Axis2/C: установка префикса](#3-apache-axis2c-установка-префикса)
4. [Клонирование проекта и первый запуск сборки](#4-клонирование-проекта-и-первый-запуск-сборки)
5. [Скрипт scripts/build.sh](#5-скрипт-scriptsbuildsh)
6. [Скрипт scripts/run.sh](#6-скрипт-scriptsrunsh)
7. [Скрипт scripts/clean.sh](#7-скрипт-scriptscleansh)
8. [VSCodium: расширения и настройки для C](#8-vscodium-расширения-и-настройки-для-c) (скрипты `**scripts/linux/`** и `**scripts/windows/`** для VSIX и релизов — см. подраздел ниже в том же разделе)
9. [Проверочный чеклист](#9-проверочный-чеклист)

---

## 1. Краткий порядок действий

1. Обновить индекс пакетов и установить зависимости из [раздела 2](#2-пакеты-apt).
2. Собрать и установить **Apache Axis2/C** в каталог-префикс (например `$HOME/axis2c-built`), см. [раздел 3](#3-apache-axis2c-установка-префикса).
3. Клонировать этот репозиторий, выставить права на скрипты, задать `AXIS2C_HOME`, выполнить `./scripts/build.sh`.
4. Один раз запустить `./scripts/run.sh` (или убедиться в симлинке `axis2_repo/lib`) — см. [раздел 6](#6-скрипт-scriptsrunsh).
5. Настроить **VSCodium** по [разделу 8](#8-vscodium-расширения-и-настройки-для-c).

---

## 2. Пакеты APT

Установите инструменты сборки C, Autotools, заголовки для типичной связки Axis2 (libxml2, zlib), а также **Bear** для генерации базы компиляции под IDE:

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential pkg-config \
  git curl ca-certificates \
  autoconf automake libtool m4 \
  libxml2-dev zlib1g-dev \
  bear \
  clangd \
  gdb
```


| Пакет / группа                                  | Зачем                                                                                  |
| ----------------------------------------------- | -------------------------------------------------------------------------------------- |
| **build-essential**                             | gcc, g++, make                                                                         |
| **pkg-config**                                  | подсказки зависимостей при сборке Axis2/C и связанных библиотек                        |
| **git**, **curl**                               | клонирование репозиториев и загрузка архивов                                           |
| **autoconf**, **automake**, **libtool**, **m4** | `./autoreconf`, Libtool для проекта и часто для Axis2/C из исходников                  |
| **libxml2-dev**, **zlib1g-dev**                 | заголовки и symlink’и для `-lxml2`/`-lz` при проверке линковки в `configure`           |
| **bear**                                        | запись `**build/compile_commands.json`** при сборке под Bear (clangd / автодополнение) |
| **clangd**                                      | language server для C/C++ (нужен для расширения clangd в VSCodium)                     |
| **gdb**                                         | отладка из `**.vscode/launch.json`**                                                   |


Клиент `**source/frontend/client/demo.py`** использует только стандартную библиотеку Python 3; отдельные пакеты не нужны. При необходимости установите интерпретатор:

```bash
sudo apt-get install -y python3
```

---

## 3. Apache Axis2/C: установка префикса

Проект **не поставляет** бинарники Axis2 внутри себя: нужен **установленный префикс** с заголовками (`include/…/axis2_http_server.h` или `include/axis2-*/…`) и библиотеками в `**lib/`**.

Рекомендации для **Ubuntu 24.04 amd64**:

- Собирать Axis2/C **из исходников** в пользовательский префикс, например `**$HOME/axis2c-built`**. Готовые старые бинарные сборки с archive.apache.org часто **32-bit** и не подходят.
- Исходники и инструкции: [Apache Axis2/C](https://axis.apache.org/axis2/c/core/), репозиторий [axis-axis2-c-core](https://github.com/apache/axis-axis2-c-core).

После установки задайте переменную окружения (добавьте в `~/.bashrc` при необходимости):

```bash
export AXIS2C_HOME="$HOME/axis2c-built"
```

Проверка:

```bash
test -f "$AXIS2C_HOME/include/axis2_http_server.h" || \
  find "$AXIS2C_HOME/include" -name axis2_http_server.h -print -quit
```

Если `./configure` проекта или Axis2 ругается на **libxml2**/**zlib**, убедитесь, что установлены `**libxml2-dev`** и `**zlib1g-dev`** (см. раздел 2). При необходимости при конфигурировании можно передать, например:

```bash
LDFLAGS='-L/usr/lib/x86_64-linux-gnu' ./configure --with-axis2c="$AXIS2C_HOME"
```

---

## 4. Клонирование проекта и первый запуск сборки

```bash
git clone git@github.com:nekdfl/test-axios2c-sign-server.git demo-sign-server
cd demo-sign-server
chmod +x scripts/build.sh scripts/clean.sh scripts/run.sh
export AXIS2C_HOME="$HOME/axis2c-built"   # ваш префикс Axis2/C
./scripts/build.sh
```

Успешный результат: появляются `**build/source/backend/src/demo-sign-server**` и дерево `**build/axis2_repo/**` (включая копию `**axis2.xml**` и сервис `**demo_sign**`).

Запуск сервера удобнее через `**./scripts/run.sh**` (см. [раздел 6](#6-скрипт-scriptsrunsh)).

---

## 5. Скрипт `scripts/build.sh`

**Назначение:** одна команда для полного цикла **autoreconf → configure → make** в **отдельном каталоге сборки** (по умолчанию `**build/`** в корне проекта).

Кратко по шагам:

1. `**autoreconf -fi`** в корне исходников — генерируются `**configure`** и `**Makefile.in`** рядом с `**Makefile.am**` (эти файлы обычно не коммитятся).
2. Поиск префикса Axis2/C с заголовком `**axis2_http_server.h**`: первый аргумент скрипта (если это каталог с заголовками), затем `**$AXIS2C_HOME**`, затем перебор типичных путей (`$HOME/axis2c-built`, `$HOME/axis2c`, `/usr/local/axis2c`, `/opt/axis2c`).
3. `**mkdir**` каталога сборки (`**DEMO_SIGN_BUILD_DIR**`, по умолчанию `**build/**`).
4. Запуск `**../configure**` из этого каталога с `**--with-axis2c=...**` и любыми дополнительными аргументами, переданными в `**./scripts/build.sh**` после префикса Axis2 (если есть).
5. `**make**` в каталоге сборки. Если установлен `**bear**`, сборка выполняется под `**bear**` и создаётся `**build/compile_commands.json**` для IDE. Если после инкрементальной сборки файл пустой (`**[]**`), скрипт выполняет `**make clean**` и повторную сборку под Bear — иначе clangd не получает команд компиляции.

Примеры:

```bash
./scripts/build.sh
AXIS2C_HOME="$HOME/axis2c-built" ./scripts/build.sh
./scripts/build.sh "$HOME/axis2c-built" --prefix=/usr/local
DEMO_SIGN_BUILD_DIR="$PWD/out" ./scripts/build.sh
```

---

## 6. Скрипт `scripts/run.sh`

**Назначение:** запуск `**demo-sign-server`** с разумными значениями по умолчанию.

Поведение:

- Выбирает бинарник: сначала `**build/source/backend/src/demo-sign-server`**, иначе `**source/backend/src/demo-sign-server`** (in-tree сборка).
- Репозиторий Axis2 (`**-r**`): переменная `**DEMO_SIGN_AXIS2_REPO**`, иначе если есть `**build/axis2_repo/axis2.xml**` — `**build/axis2_repo**`, иначе `**source/backend/axis2_repo**`.
- Порт: `**PORT**` (по умолчанию **8080**); остальные аргументы передаются серверу (например `**-l 3`**).
- `**ensure_repo_lib`:** в каталоге репозитория должен быть каталог `**lib/`** с библиотеками транспорта Axis2 (например `**libaxis2_http_sender.so`**). Если его нет, скрипт создаёт симлинк `**$REPO/lib` → `$AXIS2C_HOME/lib`** (или другой найденный префикс с заголовками Axis2). Без этого движок Axis2 не стартует.

Примеры:

```bash
./scripts/run.sh
PORT=9090 ./scripts/run.sh
DEMO_SIGN_AXIS2_REPO=/path/to/repo ./scripts/run.sh -l 3
```

---

## 7. Скрипт `scripts/clean.sh`

**Назначение:** убрать локально сгенерированные артефакты Autotools и сборки, **не удаляя исходники** `.c`/`.h`/`.md`.

Порядок (упрощённо):

1. Если есть `**build/Makefile`** — `**make distclean`** в `**build/`**, затем удаление всего каталога `**build/`**.
2. Если в корне есть `**Makefile**` — `**make distclean**` (остатки in-tree сборки).
3. Удаление `**Makefile**` и `**Makefile.in**` в перечисленных подкаталогах исходников.
4. Удаление `**autom4te.cache**`, корневых `**configure**`, `**config.***`, вспомогательных скриптов autotools, `**libtool**`, `**stamp-h1**` и т.д.
5. Удаление каталогов `**.deps**` / `**.libs**`, объектных и libtool-файлов (`***.o**`, `***.lo**`, `***.la**`, `***.a**`).
6. Удаление копии `**source/backend/axis2_repo/services/demo_sign/libdemo_sign.so**` в исходном дереве (если осталась от старой схемы).

После `**./scripts/clean.sh**` снова нужны `**./scripts/build.sh**` (или ручной **autoreconf** + **configure** + **make**).

---

## 8. VSCodium: расширения и настройки для C

### Расширения

Рекомендуется одно из двух (не оба одновременно во избежание конфликтов интеллисенса):

1. **clangd** (LLVM) — хорошо дружит с `**compile_commands.json`**.
2. Либо **C/C++** (Microsoft / openvsx-сборка для VSCodium) — тогда можно использовать `**c_cpp_properties.json`**; для Autotools удобнее всё же опираться на `**compile_commands.json`**.

Для **отладки** по `**launch.json`** нужен отладчик из набора **C/C++** (**cppdbg** + **gdb**) или альтернатива (**CodeLLDB**) с перенастройкой конфигураций.

### База компиляции и `.clangd`

1. Установите `**bear`** (раздел 2) и выполните `**./scripts/build.sh`**, чтобы в `**build/`** появился непустой `**compile_commands.json**`.
2. В корне репозитория файл `**.clangd**` содержит указание каталога базы:
  ```yaml
   CompileDatabase: build
  ```
3. Если каталог сборки другой (`**DEMO_SIGN_BUILD_DIR**`), поправьте `**CompileDatabase**` в `**.clangd**` на соответствующее имя каталога относительно корня проекта.

### Файлы в `.vscode/` (в репозитории или скопируйте вручную)

- `**tasks.json**` — задача **«Autotools: make in build»** для пре-сборки перед отладкой.
- `**launch.json`** — профили **Debug: demo-sign-server** (порт 8080 или 9090 и т.д.).
- `**settings.json`** — при необходимости скрытие служебных файлов из проводника (`**files.exclude`** для `**.clangd`** и т.п.).
- `**c_cpp_properties.json`** — базовые пути; при наличии `**compile_commands.json**` основная нагрузка на интеллисенс ложится на него и **clangd**.

### Переменные окружения в терминале VSCodium

Чтобы `**./scripts/run.sh`** и поиск Axis2 находили префикс, в `**~/.bashrc`** или в настройках терминала IDE задайте:

```bash
export AXIS2C_HOME="$HOME/axis2c-built"
```

### Готовые скрипты в репозитории (`scripts/linux`, `scripts/windows`)

Ниже — сценарии для **экспорта списка расширений**, **скачивания VSIX с Open VSX**, **офлайн-установки** и **загрузки актуального релиза VSCodium** с GitHub. Пути указаны **относительно корня клонированного репозитория**. На Windows используйте **PowerShell**; если выполнение сценариев запрещено политикой, разрешите для текущего пользователя: `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned`.

**Linux (`scripts/linux/`)**


| Файл                                   | Назначение                                                                                                                                                                                                                                                                                     |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vscodium-server-download.sh`          | Скачивает архив **vscodium-server** из GitHub Releases: `**vscodium-reh-linux-${ARCH}-*.tar.gz`** (`FLAVOR=reh`, по умолчанию) или web-вариант `**vscodium-reh-web-linux-${ARCH}-*.tar.gz`** (`FLAVOR=reh-web`). Переменные: `**ARCH`** (`x64`, `arm64`, `armhf`), `**FLAVOR`**, `**OUTDIR**`. |
| `vscodium-server-export-extensions.sh` | Экспортирует расширения из `**~/.vscodium-server**`: сначала через `**SERVER_CLI**` (если найден), иначе из `**extensions.json**`; результат в `**OUT**` (по умолчанию `vscodium-server-extensions.txt`).                                                                                      |
| `download-extensions.sh`     | Аргументы: `**[список]**` `**[каталог_vsix]**` (по умолчанию `vscodium-extensions.txt` и `vsix` в `scripts/linux/`). **bash** + **curl** + **jq**; разбор id: первый символ `**.**` делит namespace и имя расширения для API Open VSX.                                                                      |
| `vscodium-server-install-vsix.sh`      | Устанавливает все `***.vsix`** в `**~/.vscodium-server/extensions`** через server CLI. Переменные: `**VSIX_DIR`**, `**SERVER_ROOT**`, `**SERVER_CLI**`.                                                                                                                                        |


Примеры из корня репозитория:

```bash
chmod +x scripts/linux/*.sh   # один раз
FLAVOR=reh ARCH=x64 OUTDIR="$HOME/dist" ./scripts/linux/vscodium-server-download.sh
OUT=my-ext.txt ./scripts/linux/vscodium-server-export-extensions.sh
./scripts/linux/download-extensions.sh vscodium-server-extensions.txt vsix
VSIX_DIR=vsix ./scripts/linux/vscodium-server-install-vsix.sh
```

**Windows (`scripts/windows/`)**


| Файл                      | Назначение                                                                                                                                                |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `vscodium-desktop-download.cmd`   | Последний релиз десктопного VSCodium (аргументы: `--arch`, `--outdir` — см. `vscodium_desktop_download.py`).                                                                 |
| `vscodium-desktop-export-extensions.cmd`   | Список расширений в файл (аргументы как у `vscodium_desktop_export_extensions.py`; опционально путь к `VSCodium.exe`). |
| `download-extensions.cmd` | Скачивание VSIX с Open VSX (аргументы: список и каталог — см. `openvsx_download_vsix.py`).                                           |
| `vscodium-desktop-install-vsix.cmd`  | Установка всех `*.vsix` из каталога в десктопный VSCodium (аргументы как у `vscodium_desktop_install_vsix.py`).                                                                        |


Примеры из корня репозитория (**cmd**; аргументы как у соответствующих `.py`):

```bat
scripts\windows\vscodium-desktop-download.cmd --arch x64 --outdir .
scripts\windows\vscodium-desktop-export-extensions.cmd vscodium-server-extensions.txt
scripts\windows\download-extensions.cmd scripts\windows\vscodium-extensions.txt vsix
scripts\windows\vscodium-desktop-install-vsix.cmd vsix
```

**Замечание по платформам:** VSIX, скачанные под **Windows**, не переносите на **Linux** (и наоборот), если в расширении есть нативные двоичные файлы — ставьте пакеты, собранные для целевой ОС и архитектуры (на Linux для VM используйте сценарии `**scripts/linux`**).

### Снимок установленных расширений (узел разработки)

Ниже — расширения, обнаруженные при анализе каталога `**~/.vscodium-server/extensions`** (типичный путь для **Remote SSH**: расширения ставятся на удалённую машину). На локальной установке без SSH список совпадает с содержимым `**~/.vscode-oss/extensions`** или `**~/.VSCodium/extensions`** (или выводом CLI, см. ниже).


| Идентификатор (`publisher.name`)             | Версия    |
| -------------------------------------------- | --------- |
| `13xforever.language-x86-64-assembly`        | 3.1.5     |
| `batisteo.vscode-django`                     | 1.8.0     |
| `bbenoist.doxygen`                           | 1.0.0     |
| `cheshirekow.cmake-format`                   | 0.6.13    |
| `cschlosser.doxdocgen`                       | 1.4.0     |
| `donjayamanne.githistory`                    | 0.6.20    |
| `donjayamanne.python-environment-manager`    | 1.2.7     |
| `donjayamanne.python-extension-pack`         | 1.7.0     |
| `franneck94.c-cpp-runner`                    | 9.4.7     |
| `franneck94.vscode-c-cpp-config`             | 6.3.0     |
| `franneck94.vscode-c-cpp-dev-extension-pack` | 0.10.0    |
| `hbenl.vscode-test-explorer`                 | 2.22.1    |
| `jeff-hykin.better-cpp-syntax`               | 1.27.1    |
| `kevinrose.vsc-python-indent`                | 1.21.0    |
| `kylinideteam.cppdebug`                      | 0.2.0     |
| `llvm-vs-code-extensions.vscode-clangd`      | 0.4.0     |
| `mhutchie.git-graph`                         | 1.30.0    |
| `ms-azuretools.vscode-containers`            | 2.4.1     |
| `ms-azuretools.vscode-docker`                | 2.0.0     |
| `ms-ceintl.vscode-language-pack-ru`          | 1.110.0   |
| `ms-python.autopep8`                         | 2025.2.0  |
| `ms-python.black-formatter`                  | 2025.2.0  |
| `ms-python.debugpy`                          | 2025.18.0 |
| `ms-python.python`                           | 2026.4.0  |
| `ms-python.vscode-python-envs`               | 1.28.0    |
| `ms-vscode.cmake-tools`                      | 1.23.51   |
| `ms-vscode.cpptools-themes`                  | 2.0.0     |
| `ms-vscode.test-adapter-converter`           | 0.2.1     |
| `njpwerner.autodocstring`                    | 0.6.1     |
| `oderwat.indent-rainbow`                     | 8.3.1     |
| `redhat.vscode-yaml`                         | 1.22.0    |
| `shd101wyy.markdown-preview-enhanced`        | 0.8.22    |
| `streetsidesoftware.code-spell-checker`      | 4.5.6     |
| `vadimcn.vscode-lldb`                        | 1.12.1    |
| `wholroyd.jinja`                             | 0.0.8     |


**Экспорт актуального списка на машине с интернетом** — для Linux VM используйте `**scripts/linux/vscodium-server-export-extensions.sh`** (экспорт именно из `~/.vscodium-server/extensions`). Для Windows host — `**scripts/windows/vscodium-desktop-export-extensions.cmd**` (или `python3 scripts/vscodium_desktop_export_extensions.py`).

```bash
# Linux VM (vscodium-server)
./scripts/linux/vscodium-server-export-extensions.sh

# при необходимости путь к серверу можно переопределить
SERVER_ROOT=$HOME/.vscodium-server OUT=my-ext.txt ./scripts/linux/vscodium-server-export-extensions.sh
```

Если команда недоступна в PATH, но известен каталог расширений, можно вытащить пары `id@version` из `**extensions.json**`:

```bash
python3 - <<'PY'
import json, pathlib
p = pathlib.Path.home() / ".vscodium-server/extensions/extensions.json"
for item in json.loads(p.read_text(encoding="utf-8")):
    ident = item.get("identifier") or {}
    ext_id = ident.get("id")
    if ext_id:
        print(f"{ext_id}@{item.get('version','?')}")
PY
```

Путь к `**extensions.json**` замените на свой (например `**~/.vscode-oss/extensions/extensions.json**` для локального VSCodium).

### Офлайн: скачивание VSIX и установка в VSCodium

**Идея:** на компьютере с интернетом скачать файлы `**.vsix`** из каталога [Open VSX](https://open-vsx.org/) (его использует VSCodium по умолчанию), перенести каталог на изолированную машину (флешка, внутренняя сеть), установить локально через `**--install-extension`**.

**1. Файл со списком** `vscodium-server-extensions.txt`, по строке на расширение (`publisher.extension@version`):

```text
llvm-vs-code-extensions.vscode-clangd@0.4.0
ms-python.python@2026.4.0
```

**2. Скачивание VSIX** — из корня репозитория, на **той же платформе**, где будет установка расширений (см. `**scripts/linux/download-extensions.sh`** или `**scripts/windows/download-extensions.cmd`** в таблице выше). Логика: запрос `**GET https://open-vsx.org/api/{namespace}/{name}/{version}`**, поле `**files.download`**; разбор id — первый символ `**.**` перед именем расширения в пути API (как в скриптах).

```bash
# Linux
./scripts/linux/download-extensions.sh vscodium-server-extensions.txt vsix
```

```bat
REM Windows (cmd из корня)
scripts\windows\download-extensions.cmd vscodium-server-extensions.txt vsix
```

Если какое‑то расширение отсутствует в Open VSX (или нужна сборка только под **VS Marketplace**), его придётся получить `**.vsix`** вручную с машины, где есть доступ к нужному источнику, либо использовать уже установленную копию из каталога расширений (подмножество расширений можно **заархивировать целиком** каталог `**…/extensions/`** и перенести на однотипную ОС/архитектуру — это быстрее, но менее переносимо между разными платформами).

**3. Установка без интернета** на целевом компьютере:

```bash
# Linux
VSIX_DIR=vsix ./scripts/linux/vscodium-server-install-vsix.sh
```

```bat
REM Windows
scripts\windows\vscodium-desktop-install-vsix.cmd vsix
```

Вручную одной командой:

```bash
# Linux VM (vscodium-server)
VSIX_DIR=vsix ./scripts/linux/vscodium-server-install-vsix.sh
```

Одиночный пакет: `**SERVER_CLI=/path/to/code ./scripts/linux/vscodium-server-install-vsix.sh**` (с `VSIX_DIR`, содержащим один `.vsix`).

---

## 9. Проверочный чеклист


| Шаг | Действие                                                                                                    |
| --- | ----------------------------------------------------------------------------------------------------------- |
| 1   | `apt-get install` из [раздела 2](#2-пакеты-apt) выполнен                                                    |
| 2   | Axis2/C собран, `**AXIS2C_HOME**` указывает на префикс с `**include**` и `**lib**`                          |
| 3   | `**./scripts/build.sh**` завершается без ошибки, есть `**build/source/backend/src/demo-sign-server**`       |
| 4   | `**./scripts/run.sh**` запускает сервер; при необходимости создан симлинк `**…/axis2_repo/lib**`            |
| 5   | `**build/compile_commands.json**` не пустой (после Bear); **clangd** подхватывает проект при открытии корня |
| 6   | (Опционально) отладка по **F5** с конфигурации из `**.vscode/launch.json`**                                 |


Дальше по коду и Axis2: остальные файлы в `**tech.md/`** ([README](README.md)).