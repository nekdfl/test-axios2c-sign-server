# VSCodium и офлайн VSIX (Windows)

Сборка **Apache Axis2/C** и бинарника **`demo-sign-server`** в этом репозитории описана для **Linux** — см. [`README.ubuntu.md`](README.ubuntu.md) и [`tech.md/environment.ubuntu.md`](tech.md/environment.ubuntu.md). Ниже — сценарии для **десктопного VSCodium** на Windows через **Python 3** из корня репозитория (только стандартная библиотека). Пример списка расширений: `scripts/windows/vscodium-extensions.txt`.

Подробнее (в т. ч. связка с Linux и vscodium-server): [`tech.md/environment.windows.md`](tech.md/environment.windows.md).

---

## Скачать последний релиз VSCodium (zip + установщики)

```bash
python3 scripts/vscodium_desktop_download.py --arch x64 --outdir .
```

(В PowerShell при необходимости: `py -3` вместо `python3`.)

---

## Экспортировать список установленных расширений (десктоп)

```bash
python3 scripts/vscodium_desktop_export_extensions.py vscodium-extensions.txt
```

Вторым аргументом можно передать путь к `VSCodium.exe`, если CLI не в `PATH`.

---

## Скачать VSIX по списку (Open VSX)

```bash
python3 scripts/openvsx_download_vsix.py scripts/windows/vscodium-extensions.txt vsix
```

---

## Установить VSIX из каталога

```bash
python3 scripts/vscodium_desktop_install_vsix.py vsix
```

---

Обёртки **`scripts/windows/*.cmd`** — см. [`scripts/README.windows.md`](scripts/README.windows.md).
