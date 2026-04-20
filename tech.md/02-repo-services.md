# 2. Сервис в этом репозитории

## Каталог `source/backend/services/demo_sign/`


| Файл                   | Роль                                                                                                        |
| ---------------------- | ----------------------------------------------------------------------------------------------------------- |
| `services.xml`         | Декларация сервиса Axis2: имя, класс, список операций (`getHealth`, `signDocument`).                        |
| `demo_sign_skeleton.c` | Точка входа DLL: `axis2_get_instance`, `invoke`, диспетчеризация по имени операции / корневому элементу OM. |
| `demo_sign_svc.c`      | Разбор OM запроса, вызов `**DemoSign_ComputeDocumentSignature**` (`demosign.h`), сборка OM ответа.          |
| `demo_sign_svc.h`      | Заголовок только для внутренних функций сервиса (не публичный API продукта).                                |


## Связь с `source/backend/src/demosign.c`

Логика «подписи» (детерминированный хэш) в `**source/backend/src/demosign.c**` с публичным заголовком `**source/backend/include/demosign.h**` (интерфейс в стиле WinAPI: `BOOL`, `DWORD`, `WINAPI`). Исходник компилируется в состав `**libdemo_sign**`. Сервис Axis2 не должен дублировать эту математику — только вызывать API.

## Ось сборки

1. `**libdemo_sign**` (модуль сервиса) собирается из `demo_sign_skeleton.c`, `demo_sign_svc.c` и `**$(top_srcdir)/source/backend/src/demosign.c**`.
2. `all-local` копирует `axis2.xml` в `**$(top_builddir)/axis2_repo/**`, затем `libdemo_sign.so` и `services.xml` в `**$(top_builddir)/axis2_repo/services/demo_sign/**` (при типовой сборке `./scripts/build.sh` это каталог `**build/axis2_repo/...**`).

## Клиент

`source/frontend/client/demo.py` шлёт **SOAP** на `.../services/demo_sign` — путь совпадает с префиксом Axis2 по умолчанию (`/services/...`).