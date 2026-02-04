# clawbotdocker — контейнер OpenClaw с браузерным dashboard

Этот проект собирает Docker‑контейнер, в котором:
- устанавливается OpenClaw CLI
- автоматически стартует Gateway
- открывается Chrome с Control UI (dashboard)

Поддерживаются два режима:
- **dev** — терминал + браузер (GUI)
- **user** — без GUI, только ссылка на dashboard в лог

---

## 0) Что нужно заранее (самые простые шаги)

1. **Установите Docker**
   - Windows/macOS: Docker Desktop
   - Linux: docker + docker‑compose

2. **Проверьте, что Docker работает**
   ```bash
   docker --version
   docker compose version
   ```

3. **Скачайте проект**
   ```bash
   git clone https://github.com/purepurpurep-git/clawbotdocker.git
   cd clawbotdocker
   ```

---

## 1) Быстрый старт (минимум действий)

```bash
./init.sh
# отредактируйте .env (OPENCLAW_GATEWAY_TOKEN и OPENROUTER_API_KEY обязательны)

# режим dev (терминал + браузер)
docker compose --profile dev up --build

# режим user (без GUI, только ссылка)
docker compose --profile user up --build
```

### Привилегии

Compose уже задаёт `privileged: true` для обоих режимов.
Если запускаете вручную через `docker run`, используйте:

```bash
docker run -it --rm --privileged \
  -p ${HOST_PORT:-18789}:${GATEWAY_PORT:-18789} \
  -e DISPLAY=:0 -e WAYLAND_DISPLAY=wayland-0 \
  -v /mnt/wslg:/mnt/wslg \
  -v /mnt/wslg/.X11-unix:/tmp/.X11-unix \
  -v "$(pwd)/data":/data \
  -v "$(pwd)/workspace":/workspace \
  -w /workspace \
  clawbotdocker-clawbot-dev
```

Если .env не настроен, контейнер запустится, но модель работать не будет.

---

## 3) Важно про порты и режимы

`dev` и `user` используют один и тот же порт `${HOST_PORT}` — **их нельзя запускать одновременно**.
Перед переключением остановите текущий режим:
```bash
docker compose --profile dev down
# или
docker compose --profile user down
```

---

## 4) Настройки (.env)

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

## 2) Где смотреть dashboard

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
./pair.sh
# или вручную:
# openclaw devices list
# openclaw devices approve <requestId>
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
docker compose --profile dev up --build
# или
# docker compose --profile user up --build
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

Эти файлы создаются автоматически в репозитории.
