#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:${PATH:-}"
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
printf 'Добавьте отдельный ключ для проверки из https://openrouter.ai/settings/keys\nВвод ключа скрыт; открытым текстом он не сохраняется.\n'
if ! /usr/bin/python3 Scripts/embed_key.py; then
    printf '\nНе удалось добавить ключ. Если выше написано Operation not permitted:\n'
    printf 'Системные настройки → Конфиденциальность и безопасность → Файлы и папки → Terminal → Документы.\n'
    printf 'Разрешите доступ, полностью закройте Terminal и повторите запуск.\n'
    if [ -t 0 ]; then read -r -p 'Нажмите Enter… ' _answer || true; fi
    exit 1
fi
printf '\nГотово. Теперь запустите Build.command.\n'
if [ -t 0 ]; then read -r -p 'Нажмите Enter… ' _answer || true; fi
