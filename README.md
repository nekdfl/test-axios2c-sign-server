# demo-sign-server (Apache Axis2/C) + Python SOAP client

Демо-проект: **SOAP/HTTP бэкенд на C** на базе **Apache Axis2/C** (встроенный simple HTTP server), сервис «подписи» как **динамическая библиотека** + `services.xml`, сборка через **autotools**, плюс **Python-клиент** для вызовов SOAP и пример **Nginx**.

## Оглавление

### По операционной системе

- **[Ubuntu / Debian / Linux](README.ubuntu.md)** — зависимости APT, сборка, запуск, тесты `curl` / клиент, ссылка на пример Nginx
- **[Windows](README.windows.md)** — VSCodium (десктоп), VSIX, Python-скрипты; сборка сервера — на Linux

### Общее

- [Что внутри](#что-внутри)
- [Онбординг по Axis2/C](#онбординг-по-axis2c)
- [Документация в `tech.md/`](#документация-в-techmd)

## Что внутри

- **`scripts/`** — `build.sh`, `clean.sh`, `run.sh` (сборка, очистка, запуск; из корня: `./scripts/…`), плюс Python-утилиты VSCodium/Open VSX (`vscodium_*.py`, `openvsx_download_vsix.py`).
- **`scripts/windows/`** — пример списка расширений `vscodium-extensions.txt` (и при необходимости каталог `vsix/`); сами команды — из корня через `python3 scripts/…` (утилиты VSIX) или см. [`scripts/README.windows.md`](scripts/README.windows.md).
- **`scripts/linux/`** — **`*.sh`** (bash, `curl`, `jq`): скачивание сервера/VSIX и офлайн-установка; **`*.cmd`** для тех же задач под Windows через Python; см. [`scripts/README.ubuntu.md`](scripts/README.ubuntu.md) и [`scripts/README.md`](scripts/README.md).
- **`source/backend/`** — исходники C и Axis2: `src/`, `include/`, `services/`, шаблон **`axis2_repo/`**.
- **`source/frontend/client/`** — Python-скрипт для вызовов SOAP (`urllib`, без сторонних пакетов).
- `source/backend/src/main.c` — точка входа (адаптирован из `http_server_main.c` Axis2/C, лицензия Apache 2.0).
- `source/backend/services/demo_sign/` — сервис `demo_sign` (`libdemo_sign.so`, `services.xml`, OM/SOAP логика).
- `source/backend/include/demosign.h` — публичный API подписи в стиле WinAPI (`BOOL`/`DWORD`/`WINAPI`, только POSIX в реализации).
- `source/backend/include/demoposix.h` — обёртки POSIX (`sigaction`) в том же стиле именования.
- `source/backend/src/demosign.c`, `source/backend/src/demoposix.c` — реализации (линкуются в `libdemo_sign.so` и в `demo-sign-server` соответственно).
- `source/backend/axis2_repo/axis2.xml` — минимальный `axis2.xml`; после `make` в `build/axis2_repo/services/demo_sign/` появляются копии `services.xml` и `libdemo_sign.so`.
- **`tech.md/nginx-reverse-proxy-example.md`** — указатель на примеры Nginx по ОС (`*.ubuntu.md` / `*.windows.md`).
- `AUTOTOOLS.md` — назначение файлов autotools.
- **`tech.md/`** — онбординг по Axis2/C и структуре репозитория.

----

## Онбординг по Axis2/C

См. каталог **`tech.md/`** — оглавление в [`tech.md/README.md`](tech.md/README.md) (файлы `01-…` … `04-…` плюс ссылки на гайды по ОС).

----

## Документация в `tech.md/`

| Тема | Файлы |
| ---- | ----- |
| Сборочное окружение | [`environment.md`](tech.md/environment.md) → [`environment.ubuntu.md`](tech.md/environment.ubuntu.md), [`environment.windows.md`](tech.md/environment.windows.md) |
| Nginx | [`nginx-reverse-proxy-example.md`](tech.md/nginx-reverse-proxy-example.md) → [`nginx-reverse-proxy-example.ubuntu.md`](tech.md/nginx-reverse-proxy-example.ubuntu.md), [`nginx-reverse-proxy-example.windows.md`](tech.md/nginx-reverse-proxy-example.windows.md) |
| Маршруты по ОС в `tech.md/` | [`README.ubuntu.md`](tech.md/README.ubuntu.md), [`README.windows.md`](tech.md/README.windows.md) |
| Онбординг Axis2 | [`tech.md/README.md`](tech.md/README.md) |
