# demo-sign-server (Apache Axis2/C) + Python SOAP client

Демо-проект: **SOAP/HTTP бэкенд на C** на базе **Apache Axis2/C** (встроенный simple HTTP server), сервис «подписи» как **динамическая библиотека** + `services.xml`, сборка через **autotools**, плюс **Python-клиент** для вызовов SOAP и пример **Nginx**.

## Что внутри

- **`scripts/`** — `build.py`, `clean.py`, `run.py` (сборка, очистка, запуск; из корня: `python3 scripts/…`), плюс Python-утилиты VSCodium/Open VSX (`vscodium_*.py`, `openvsx_download_vsix.py`).
- **`scripts/windows/`** — пример списка расширений `vscodium-extensions.txt` (и при необходимости каталог `vsix/`); сами команды — из корня через `python3 scripts/…`.
- **`scripts/linux/`** — **`*.sh`** (bash, `curl`, `jq`): скачивание сервера/VSIX и офлайн-установка; **`*.cmd`** для тех же задач под Windows через Python; см. `scripts/README.md`.
- **`source/backend/`** — исходники C и Axis2: `src/`, `include/`, `services/`, шаблон **`axis2_repo/`**.
- **`source/frontend/client/`** — Python-скрипт для вызовов SOAP (`urllib`, без сторонних пакетов).
- `source/backend/src/main.c` — точка входа (адаптирован из `http_server_main.c` Axis2/C, лицензия Apache 2.0).
- `source/backend/services/demo_sign/` — сервис `demo_sign` (`libdemo_sign.so`, `services.xml`, OM/SOAP логика).
- `source/backend/include/demosign.h` — публичный API подписи в стиле WinAPI (`BOOL`/`DWORD`/`WINAPI`, только POSIX в реализации).
- `source/backend/include/demoposix.h` — обёртки POSIX (`sigaction`) в том же стиле именования.
- `source/backend/src/demosign.c`, `source/backend/src/demoposix.c` — реализации (линкуются в `libdemo_sign.so` и в `demo-sign-server` соответственно).
- `source/backend/axis2_repo/axis2.xml` — минимальный `axis2.xml`; после `make` в `build/axis2_repo/services/demo_sign/` появляются копии `services.xml` и `libdemo_sign.so`.
- **`tech.md/nginx-reverse-proxy-example.md`** — пример конфигурации Nginx как reverse-proxy на порт Axis2.
- `AUTOTOOLS.md` — назначение файлов autotools.
- `tech.md/` — онбординг по Axis2/C и структуре репозитория.

----

## Компиляция проекта

## Документация

- **Сборочное окружение и VSCodium (Ubuntu 24.04)**: `tech.md/environment.md`
- **Онбординг по Axis2/C и проекту**: `tech.md/README.md`
- **Git-репозиторий**: `git@github.com:nekdfl/test-axios2c-sign-server.git`

### Зависимости (Ubuntu / Debian)

Инструменты сборки и заголовки (для Axis2/C из исходников и для линковки с libxml2 при необходимости):

```bash
sudo apt-get update
sudo apt-get install -y \
  build-essential pkg-config \
  autoconf automake libtool m4 \
  libxml2-dev zlib1g-dev \
  bear \
  clangd
```

**clangd** — язык‑сервер для C/C++ (используется расширением *clangd* в VSCodium).  
**bear** — по желанию: при наличии **`python3 scripts/build.py`** пишет **`build/compile_commands.json`** для **clangd** (файл **`.clangd`** в корне указывает каталог с базой).

**Apache Axis2/C** должен быть установлен в префикс (например `/usr/local/axis2c` или `$HOME/axis2c-built`). Укажите путь через **`AXIS2C_HOME`** или флаг **`./configure --with-axis2c=...`**.

Сборка Axis2/C из исходников: репозиторий [axis-axis2-c-core](https://github.com/apache/axis-axis2-c-core) и [официальная документация](https://axis.apache.org/axis2/c/core/). Для релиза **1.6.0** с archive.apache.org на amd64 собирайте из **исходников** (`axis2c-src-1.6.0.tar.gz`): готовый бинарный `axis2c-bin-*-linux` в архиве часто **32-bit** и не подойдёт для x86_64.

Если `./configure` ругается на отсутствие **`libxml2.so`** / **`libz.so`** при проверке линковки, установите **`libxml2-dev`** и **`zlib1g-dev`** (см. список выше) или передайте при конфигурировании, например:

```bash
LDFLAGS='-L/usr/lib/x86_64-linux-gnu' ./configure --with-axis2c="$AXIS2C_HOME"
```

### Сборка скриптом

Из корня репозитория:

```bash
export AXIS2C_HOME=/path/to/axis2c/prefix   # пример
python3 scripts/build.py
```

`scripts/build.py` выполняет: `autoreconf -fi` в корне исходников → `configure` и `make` **в каталоге `build/`** (объекты и генерируемые Makefile’ы не попадают в `source/backend/...`). Каталог сборки можно задать переменной **`DEMO_SIGN_BUILD_DIR`**.

### Сборка вручную

```bash
autoreconf -fi
mkdir -p build
cd build
../configure --with-axis2c="${AXIS2C_HOME:-/usr/local/axis2c}"
make -j"$(nproc)"
```

Описание `configure.ac` и `Makefile.am` — в **`AUTOTOOLS.md`**.

### IDE (VSCodium / clangd)

Минимум:

- Установите `clangd` (см. список APT выше) и расширение **clangd** в VSCodium.
- Выполните **`python3 scripts/build.py`**; при наличии **Bear** появится **`build/compile_commands.json`**.
- Файл **`.clangd`** в корне указывает clangd на каталог базы (`CompileDatabase: build`).

Подробный гайд по VSCodium/расширениям/офлайн‑установке VSIX — в `tech.md/environment.md`.

### Очистка

```bash
python3 scripts/clean.py
```

Удаляет каталог **`build/`** (если был), затем сгенерированные в корне `configure`, `Makefile*`, объекты, кэш autotools и копии сервиса в **`source/backend/axis2_repo/`** (если остались от старой in-tree сборки).

----

## Запуск сервера

После `python3 scripts/build.py` бинарник: **`build/source/backend/src/demo-sign-server`**, репозиторий для запуска (с копией `axis2.xml` и сервисом): **`build/axis2_repo/`**. Удобнее **`python3 scripts/run.py`** (сам выбирает бинарник под `build/` или in-tree под `source/backend/`).

```bash
./build/source/backend/src/demo-sign-server -p 8080 -r "$PWD/build/axis2_repo"
```

Если не указать `-r`, сервер по умолчанию ищет `./axis2_repo` от текущего каталога; в **`scripts/run.py`** по умолчанию подставляется **`build/axis2_repo`**, если он есть. Также **`DEMO_SIGN_AXIS2_REPO`**, затем **`AXIS2C_HOME`** для путей репозитория в `main.c`.

----

## Тестирование

### SOAP через curl

Сервис: `http://127.0.0.1:8080/services/demo_sign`.

**getHealth**

```bash
curl -sS -X POST 'http://127.0.0.1:8080/services/demo_sign' \
  -H 'Content-Type: text/xml; charset=utf-8' \
  -H 'SOAPAction: getHealth' \
  --data-binary '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:p="http://demo.sign/axis2"><soapenv:Body><p:getHealth/></soapenv:Body></soapenv:Envelope>'
```

**signDocument**

```bash
curl -sS -X POST 'http://127.0.0.1:8080/services/demo_sign' \
  -H 'Content-Type: text/xml; charset=utf-8' \
  -H 'SOAPAction: signDocument' \
  --data-binary '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:p="http://demo.sign/axis2"><soapenv:Body><p:signDocument><key_id>demo-key-1</key_id><document>hello world</document></p:signDocument></soapenv:Body></soapenv:Envelope>'
```

### Клиент Python

Требуется Python 3.8+ (используется только стандартная библиотека).

```bash
cd source/frontend/client
./demo.py http://127.0.0.1:8080
# или: python3 demo.py http://127.0.0.1:8080
```

----

## Nginx

Пример конфигурации см. **`tech.md/nginx-reverse-proxy-example.md`**: прокси на Axis2 (по умолчанию `http://127.0.0.1:8080`), пути вида `/services/demo_sign` проксируются как есть.

----

## Онбординг по Axis2/C

См. каталог **`tech.md/`** (файлы `README.md`, `01-…` … `04-…`).

----

## VSCodium и офлайн VSIX (Python)

Из **корня** репозитория, с **Python 3** (только стандартная библиотека). Пример списка: `scripts/windows/vscodium-extensions.txt`.

### Скачать последний релиз VSCodium для Windows (zip + установщики)

```bash
python3 scripts/vscodium_desktop_download.py --arch x64 --outdir .
```

### Экспортировать список установленных расширений (десктоп)

```bash
python3 scripts/vscodium_desktop_export_extensions.py vscodium-extensions.txt
```

Вторым аргументом можно передать путь к `VSCodium.exe`, если CLI не в `PATH`.

### Скачать VSIX по списку (Open VSX)

```bash
python3 scripts/openvsx_download_vsix.py scripts/windows/vscodium-extensions.txt vsix
```

### Установить VSIX из каталога

```bash
python3 scripts/vscodium_desktop_install_vsix.py vsix
```
