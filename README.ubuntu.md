# Сборка, запуск и тесты (Ubuntu / Debian, Linux)

Сборка демо-сервера **Axis2/C**, запуск и проверки **curl** / **Python-клиент** на Linux. Общее описание проекта и структура репозитория — в корневом [`README.md`](README.md).

---

## Документация по ОС

- **Сборочное окружение и VSCodium (подробно)**: [`tech.md/environment.ubuntu.md`](tech.md/environment.ubuntu.md)
- **Онбординг по Axis2/C**: [`tech.md/README.md`](tech.md/README.md)
- **Указатель environment**: [`tech.md/environment.md`](tech.md/environment.md)
- **Git**: `git@github.com:nekdfl/test-axios2c-sign-server.git`

---

## Зависимости (Ubuntu / Debian)

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
**bear** — по желанию: при наличии **`./scripts/build.sh`** пишет **`build/compile_commands.json`** для **clangd** (файл **`.clangd`** в корне указывает каталог с базой).

**Apache Axis2/C** должен быть установлен в префикс (например `/usr/local/axis2c` или `$HOME/axis2c-built`). Укажите путь через **`AXIS2C_HOME`** или флаг **`./configure --with-axis2c=...`**.

Сборка Axis2/C из исходников: репозиторий [axis-axis2-c-core](https://github.com/apache/axis-axis2-c-core) и [официальная документация](https://axis.apache.org/axis2/c/core/). Для релиза **1.6.0** с archive.apache.org на amd64 собирайте из **исходников** (`axis2c-src-1.6.0.tar.gz`): готовый бинарный `axis2c-bin-*-linux` в архиве часто **32-bit** и не подойдёт для x86_64.

Если `./configure` ругается на отсутствие **`libxml2.so`** / **`libz.so`** при проверке линковки, установите **`libxml2-dev`** и **`zlib1g-dev`** (см. список выше) или передайте при конфигурировании, например:

```bash
LDFLAGS='-L/usr/lib/x86_64-linux-gnu' ./configure --with-axis2c="$AXIS2C_HOME"
```

---

## Сборка скриптом

Из корня репозитория:

```bash
export AXIS2C_HOME=/path/to/axis2c/prefix   # пример
./scripts/build.sh
```

`./scripts/build.sh` выполняет: `autoreconf -fi` в корне исходников → `configure` и `make` **в каталоге `build/`** (объекты и генерируемые Makefile’ы не попадают в `source/backend/...`). Каталог сборки можно задать переменной **`DEMO_SIGN_BUILD_DIR`**.

---

## Сборка вручную

```bash
autoreconf -fi
mkdir -p build
cd build
../configure --with-axis2c="${AXIS2C_HOME:-/usr/local/axis2c}"
make -j"$(nproc)"
```

Описание `configure.ac` и `Makefile.am` — в **`AUTOTOOLS.md`**.

---

## IDE (VSCodium / clangd)

Минимум:

- Установите `clangd` (см. список APT выше) и расширение **clangd** в VSCodium.
- Выполните **`./scripts/build.sh`**; при наличии **Bear** появится **`build/compile_commands.json`**.
- Файл **`.clangd`** в корне указывает clangd на каталог базы (`CompileDatabase: build`).

Подробный гайд по VSCodium и офлайн‑VSIX на Linux — в **`tech.md/environment.ubuntu.md`**.

---

## Очистка

```bash
./scripts/clean.sh
```

Удаляет каталог **`build/`** (если был), затем сгенерированные в корне `configure`, `Makefile*`, объекты, кэш autotools и копии сервиса в **`source/backend/axis2_repo/`** (если остались от старой in-tree сборки).

---

## Запуск сервера

После `./scripts/build.sh` бинарник: **`build/source/backend/src/demo-sign-server`**, репозиторий для запуска (с копией `axis2.xml` и сервисом): **`build/axis2_repo/`**. Удобнее **`./scripts/run.sh`** (сам выбирает бинарник под `build/` или in-tree под `source/backend/`).

```bash
./build/source/backend/src/demo-sign-server -p 8080 -r "$PWD/build/axis2_repo"
```

Если не указать `-r`, сервер по умолчанию ищет `./axis2_repo` от текущего каталога; в **`./scripts/run.sh`** по умолчанию подставляется **`build/axis2_repo`**, если он есть. Также **`DEMO_SIGN_AXIS2_REPO`**, затем **`AXIS2C_HOME`** для путей репозитория в `main.c`.

---

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

---

## Nginx

Пример конфигурации: [`tech.md/nginx-reverse-proxy-example.ubuntu.md`](tech.md/nginx-reverse-proxy-example.ubuntu.md) — прокси на Axis2 (по умолчанию `http://127.0.0.1:8080`), пути вида `/services/demo_sign` проксируются как есть.

---

На хосте **Windows** (без WSL) для демо-сервера см. [`README.windows.md`](README.windows.md) и [`tech.md/environment.windows.md`](tech.md/environment.windows.md).
