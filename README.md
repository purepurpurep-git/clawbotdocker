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

Dashboard откроется в Chrome внутри контейнера: `http://127.0.0.1:18789/?token=...`

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

- Gateway слушает `0.0.0.0:18789`, доступен с хоста через проброс порта.
- Токен gateway обязателен, иначе dashboard не откроется.
- Telegram включается автоматически при заполненном `TELEGRAM_BOT_TOKEN`.
