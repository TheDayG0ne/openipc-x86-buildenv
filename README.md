# OpenIPC x86 — окружение сборки Buildroot

Экспериментальная сборка OpenIPC на базе Buildroot 2024.02.10 и внешнего дерева `../buildroot-x86`. Используются `../sources/firmware/general` из оригинального OpenIPC firmware и локальный `../sources/divinus`; оба источника и внешнее дерево подключаются только для чтения. Для UVC нужны соответствующие изменения в Divinus. Зафиксируйте версии этих репозиториев для воспроизводимости. x264 включает GPL-код.

## Сборка

Нужны Docker Desktop с Linux engine, доступ к сети и свободное место для исходников, инструментов и результатов. Деревья `buildroot-x86`, `sources/firmware` и `sources/divinus` должны располагаться рядом с этим репозиторием, как указано выше. Настройте хранение Docker на нужном диске отдельно: том Docker не обязательно находится на диске проекта.

```powershell
Set-Location D:\OpenIPC-x86\build-environment
docker compose build
docker compose run --rm buildroot
```

При необходимости задайте `$env:JOBS = '4'` до запуска. Сборка выполняется в отдельном именованном Docker-томе `buildroot-work`, на Linux-файловой системе, и не использует `buildroot-x86/output` или его уже работающую сборку. Не запускайте параллельно две сборки данного Compose-проекта: они используют один том. Изменение имени Compose-проекта (`-p`) создаёт независимый том. При каждом запуске применяется defconfig, поэтому ручные изменения конфигурации перезаписываются. Скрипт скачивает Buildroot по тегу без проверки контрольной суммы; используйте проверенные источники для доверенной сборки.

Результаты находятся в `/work/output/images` тома: `bzImage` и `rootfs.ext4`. Например, чтобы скопировать их в отдельный каталог на хосте, после сборки:

```powershell
New-Item -ItemType Directory -Force ..\tmp\buildroot-artifacts | Out-Null
docker compose run --rm -v "${PWD}/../tmp/buildroot-artifacts:/artifacts" --entrypoint sh buildroot -c 'cp /work/output/images/bzImage /work/output/images/rootfs.ext4 /artifacts/'
```

Не удаляйте том, пока нужны результаты; `docker compose down -v` удаляет его и всю сборку.

Это не загрузочный диск: загрузчик и параметр `root=` нужно настроить отдельно. Не записывайте на рабочий диск. Полный firmware overlay не применяется: он рассчитан на embedded SoC и flash. Установка, persistent overlayfs и полноценный OpenIPC UX не реализованы; наличие поддержки overlayfs в ядре не означает его монтирование. UVC, RTSP и безопасность требуют проверки на оборудовании; изолируйте образ от недоверенных сетей. Старый Debian/VMDK прототип удалён из активного дерева, но доступен в истории Git.
