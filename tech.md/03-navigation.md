# 3. Навигация по репозиторию

## Сверху вниз

- `**configure.ac` / `Makefile.am**` — как собирается проект и где ищется Axis2/C (`--with-axis2c`, переменная `AXIS2C_HOME`). Подробности в `**AUTOTOOLS.md**`.
- `**source/backend/src/main.c**` — запуск встроенного HTTP-сервера Axis2, разбор опций `-p` / `-r`, репозиторий по умолчанию `./axis2_repo` (в `**scripts/run.py**` после сборки в `build/` подставляется `**build/axis2_repo**`).
- `**source/backend/axis2_repo/axis2.xml**` (в исходниках) — минимальный конфиг; при `make` копия попадает в `**build/axis2_repo/axis2.xml**` вместе с задеплоенным сервисом.
- `**source/backend/src/demosign.c**`, `**source/backend/src/demoposix.c**` — код без Axis2: подпись и обёртки POSIX (`sigaction`).
- `**source/backend/include/demosign.h**`, `**source/backend/include/demoposix.h**` — публичные заголовки, ставятся при `make install`.
- `**tech.md/nginx-reverse-proxy-example.md**` — пример reverse-proxy для Nginx.
- `**source/frontend/client/**` — Python (`urllib`) для ручной проверки SOAP.

## Куда смотреть при баге


| Симптом                             | Куда                                                                                                                               |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Не линкуется / нет заголовков Axis2 | `configure.ac`, переменные `AXIS2C_*`, префикс установки Axis2.                                                                    |
| Сервис не подхватывается            | `source/backend/axis2_repo/services/demo_sign/` (шаблон), либо `**build/axis2_repo/...**` после сборки; `services.xml`, имя `.so`. |
| Ошибка в теле SOAP / пустой ответ   | `demo_sign_svc.c`, разбор OM; сравнение localname.                                                                                 |
| Неверная «подпись»                  | `source/backend/src/demosign.c`, `source/backend/include/demosign.h`.                                                              |
| Сигналы / завершение                | `source/backend/src/main.c`, `source/backend/src/demoposix.c`.                                                                     |


## Документация рядом

- `**README.md**` — установка зависимостей, сборка, запуск, curl, клиент.
- `**AUTOTOOLS.md**` — роль `Makefile.am` в каждом каталоге.