# Среда разработки на Windows

Сборка **Apache Axis2/C** и демо-сервера на C в этом репозитории описана для **Linux** (см. `tech.md/environment.ubuntu.md`). На **Windows** типичный сценарий — **VSCodium (десктоп)** или подготовка артефактов для переноса на Linux/VM; ниже — то, что соответствует закоммиченным скриптам.

---

## Содержание

1. [Python 3](#1-python-3)
2. [VSCodium: скачать релиз](#2-vscodium-скачать-релиз)
3. [Список расширений и VSIX (Open VSX)](#3-список-расширений-и-vsix-open-vsx)
4. [Связка с Linux](#4-связка-с-linux)

---

## 1. Python 3

Скрипты в `scripts/` используют только стандартную библиотеку. Из корня репозитория удобно вызывать:

```powershell
py -3 scripts\vscodium_desktop_download.py --help
```

(или `python3`, если так настроен `PATH`).

---

## 2. VSCodium: скачать релиз

Последний релиз **portable ZIP**, **Setup** и **UserSetup** для архитектуры **x64** или **arm64**:

```bash
python3 scripts/vscodium_desktop_download.py --arch x64 --outdir .
```

Пример списка расширений для десктопа: `scripts/windows/vscodium-extensions.txt`.

---

## 3. Список расширений и VSIX (Open VSX)

**Экспорт** установленных расширений в файл (при необходимости вторым аргументом — путь к `VSCodium.exe`):

```bash
python3 scripts/vscodium_desktop_export_extensions.py vscodium-extensions.txt
```

**Скачать** пакеты `.vsix` по списку в каталог (например `vsix`):

```bash
python3 scripts/openvsx_download_vsix.py scripts/windows/vscodium-extensions.txt vsix
```

**Офлайн-установка** из каталога с VSIX:

```bash
python3 scripts/vscodium_desktop_install_vsix.py vsix
```

Общая логика поиска CLI — в `scripts/vscodium_common.py`. VSIX с нативными бинарниками, скачанные под Windows, **не переносите** на Linux и наоборот.

Дополнительно (подготовка **vscodium-server** и bash-скрипты для Linux) см. раздел про Windows в **части I** файла `tech.md/environment.ubuntu.md`, а также `scripts/README.md` и `scripts/README.ubuntu.md`.

---

## 4. Связка с Linux

- Офлайн-загрузка сервера и расширений для Linux-хоста: `scripts/linux/*.sh` и `*.cmd` — см. `scripts/README.ubuntu.md`.
- Полное сборочное окружение сервера: `tech.md/environment.ubuntu.md` (в т. ч. **часть II** с альтернативными оболочечными сценариями из бывшего каталога `_ubuntu`).
