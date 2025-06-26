# pymongo-api

## Как запустить

Запускаем mongodb и приложение

```shell
docker compose up -d
```

Запустить 2 шарда монго с 3 репликами

```bash
./scripts/shards-repl-init.sh
```

Запустить кластер Redis
```bash
./scripts/redis-cluster-init.sh
```

## Как проверить

### Если вы запускаете проект на локальной машине

Откройте в браузере http://localhost:8080

# Описание и документация
(Архитектурный документ)[/ARCH-DOCK.md]