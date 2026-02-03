# clawbotdocker

Готовый контейнер OpenClaw с двумя режимами запуска:

1) **full** — терминал + браузер с открытым dashboard
2) **browser** — только браузер с dashboard

## Быстрый старт

```bash
./init.sh
# отредактируйте .env (OPENCLAW_GATEWAY_TOKEN и OPENROUTER_API_KEY обязательны)

# режим full (терминал + браузер)
docker compose --profile full up --build

# режим browser (только браузер)
docker compose --profile browser up --build
```

Если .env не настроен, контейнер запустится, но модель работать не будет.

### Ссылки на dashboard

**Если контейнер запускается напрямую на хосте (Windows/Linux):**
```
http://127.0.0.1:${HOST_PORT}/?token=<OPENCLAW_GATEWAY_TOKEN>
```

**Если контейнер запускается внутри другого контейнера (Docker-in-Docker):**
- Внутри внешнего контейнера: `http://127.0.0.1:${HOST_PORT}/?token=<OPENCLAW_GATEWAY_TOKEN>`
- С хоста: нужно пробросить порт внешнего контейнера: `-p ${HOST_PORT}:${HOST_PORT}`

Если порт занят — поменяйте `HOST_PORT` в `.env`.

## .env

Все токены и настройки хранятся в `.env`. Файл **не коммитится**.
В репозитории хранится только `.env.example` с инструкциями.

Обязательные переменные:
- `OPENCLAW_GATEWAY_TOKEN`
- `OPENROUTER_API_KEY`

Опционально:
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_*` политики

## GUI и буфер обмена

Контейнер рассчитан на GUI через WSLg или X11:
- **Windows + WSLg**: монтируем `/mnt/wslg` (уже в compose). В WSLg общий буфер обмена с Windows работает автоматически.
- **Linux X11**: монтируем `/tmp/.X11-unix`. Убедитесь, что X-сервер запущен (например, Xorg/Wayland с XWayland).

Если вы запускаете контейнер НЕ в WSL/не в Linux с X11 — GUI окна не появятся.

Для буфера обмена установлены `xclip` и `xsel`. Копирование из терминала не блокирует выполнение.

## Примечания

- Gateway слушает `${GATEWAY_PORT}` внутри контейнера и пробрасывается на `HOST_PORT`.
- Токен gateway обязателен, иначе dashboard не откроется.
- Telegram включается автоматически при заполненном `TELEGRAM_BOT_TOKEN`.
