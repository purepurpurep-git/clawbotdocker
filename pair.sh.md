# pair.sh

Автоматически подтверждает все pending‑устройства для Control UI (pairing).

Запуск:
```bash
./pair.sh
```

Скрипт вызывает `openclaw devices list --json` и подтверждает все requestId.
