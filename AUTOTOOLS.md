# Autotools в этом репозитории

Краткое описание роли файлов сборки (GNU Autoconf / Automake / Libtool).

## Корень проекта

| Файл | Назначение |
|------|------------|
| `configure.ac` | Вход Autoconf: версия пакета, проверка компилятора, `LT_INIT`, поиск префикса Axis2/C (`--with-axis2c`), проверка заголовка и линковки, подстановка `AXIS2C_*` в Makefile’ы. |
| `Makefile.am` | Вход Automake: список подкаталогов `SUBDIRS`, `EXTRA_DIST` (не собираемые, но попадающие в `make dist`). В `EXTRA_DIST` также **`.clangd`** (указание каталога `CompileDatabase` для clangd). |
| `configure`, `Makefile.in`, `aclocal.m4`, … | **Генерируются** командой `autoreconf -fi`; в git не коммитятся (см. `.gitignore`). |

## Подкаталоги (`source/backend/`)

| Путь | Назначение |
|------|------------|
| `source/backend/include/Makefile.am` | Установка публичных заголовков `include_HEADERS` (`demosign.h`, `demoposix.h`). |
| `source/backend/services/Makefile.am` | Подкаталог `demo_sign`. |
| `source/backend/services/demo_sign/Makefile.am` | Сервис Axis2: `libdemo_sign.la` (в т.ч. `$(top_srcdir)/source/backend/src/demosign.c`); `all-local` копирует `axis2.xml` в `$(top_builddir)/axis2_repo/` и сервис в `$(top_builddir)/axis2_repo/services/demo_sign/` (при сборке в `build/` всё оказывается под `build/`). |
| `source/backend/src/Makefile.am` | Бинарник `demo-sign-server` (`main.c`, `demoposix.c`), флаги и линковка с Axis2/C. |

Пример конфигурации **Nginx** для reverse-proxy описан в **`tech.md/nginx-reverse-proxy-example.md`** (указатель на `*.ubuntu.md` / `*.windows.md`; не участвует в Automake).

## Полезные команды

- Регенерация скриптов сборки в корне исходников: `autoreconf -fi`
- Типовая сборка из репозитория: **`python3 scripts/build.py`** (configure + make в **`build/`**; при наличии **`bear`** — перехват компиляции и запись **`build/compile_commands.json`**)
- Вручную вне дерева исходников: `mkdir -p build && cd build && ../configure --with-axis2c="$AXIS2C_HOME" && make`
- Очистка: **`python3 scripts/clean.py`** (в т.ч. удаление `build/`) или `make distclean` внутри `build/`

Подробнее про установку зависимостей и полный цикл — в **`README.ubuntu.md`** (сборка на Linux).
