# clawbotdocker — контейнер OpenClaw с браузерным dashboard

Этот проект собирает Docker‑контейнер, в котором:
- устанавливается OpenClaw CLI
- автоматически стартует Gateway
- открывается Chrome с Control UI (dashboard)

Поддерживаются два режима:
- **full** — терминал + браузер
- **browser** — только браузер

---

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

---

## Настройки (.env)

Файл `.env` **не коммитится**. В репозитории есть `.env.example`.

**Обязательные переменные:**
- `OPENCLAW_GATEWAY_TOKEN` — токен доступа в dashboard
- `OPENROUTER_API_KEY` — ключ модели по умолчанию (OpenRouter)

**Рекомендуемые:**
- `OPENCLAW_CONFIG_REWRITE=true` — всегда пересобирать openclaw.json из .env
- `OPENCLAW_GATEWAY_BIND=custom` — чтобы gateway слушал 0.0.0.0 внутри контейнера

**Опциональные:**
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_DM_POLICY`, `TELEGRAM_GROUP_POLICY`, `TELEGRAM_REQUIRE_MENTION`
- `OPENCLAW_MODEL`

---

## Доступ к dashboard

Если контейнер запущен на той же машине:
```
http://127.0.0.1:${HOST_PORT}/?token=<OPENCLAW_GATEWAY_TOKEN>
```

Если контейнер запускается внутри другого контейнера — пробросьте порт наружу
и используйте тот же URL.

---

## Первое подключение: pairing

При первом открытии Control UI новый браузер требует **pairing**.
Если видите сообщение:
```
disconnected (1008): pairing required
```
выполните внутри контейнера:

```bash
openclaw devices list
openclaw devices approve <requestId>
```

После approval браузер сохраняется как устройство, и pairing больше не нужен.

---

## Переустановка / сброс

Полный сброс состояния:
```bash
docker compose down -v
rm -rf data workspace
```

Пересборка и запуск:
```bash
docker compose --profile browser up --build
```

---

## Что внутри контейнера

- **entrypoint.sh** синхронизирует `openclaw.json` из `.env`
- запускает `openclaw gateway run`
- стартует Chrome и открывает dashboard

---

## Описание файлов

Для каждого файла есть отдельное описание в файле `<имя>.md`.
Примеры:
- `Dockerfile.md`
- `entrypoint.sh.md`
- `docker-compose.yml.md`
- `data.md`
- `workspace.md`

Эти файлы создаются автоматически в репозитории.
