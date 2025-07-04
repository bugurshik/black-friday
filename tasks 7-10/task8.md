# Стратегия балансировки нагрузки в шардинге MongoDB

### Контекст проблемы
В текущей системе произошёл дисбаланс нагрузки между шардами из-за концентрации 70% запросов на категории "Электроника". Это привело к перегрузке одного из шардов и ухудшению общей производительности. Необходимо разработать механизм проактивного мониторинга и автоматического балансирования нагрузки.

### Цель
Разработать стратегию:
   * Для выявления горячих шардов.
   * Для устранения дисбаланса.
   * Для предотвращения подобных ситуаций в будущем с помощью мониторинга и автоматизации.

# Диагностика
Для эффективного контроля состояния шардов необходимо отслеживать следующие ключевые метрики:

|Описание|Команда|
|--|--|
|Интенсивность операций по типам| db.serverStatus().opcounters|
|Текущее количество активных операций|db.serverStatus().globalLock.currentQueue|
|Количество активных клиентских соединений| db.serverStatus().globalLock.activeClients|
|Объём входящего/исходящего сетевого трафика|db.serverStatus().network|
|Статистика по коллекциям в каждом шарде|db.collection.stats()|
|Распределение чанков по шардам|sh.status()|
|Задержка выполнения запросов|db.collection.aggregate([{$indexStats: {}}])|Число активных соединений на шард|db.curr|

# Способы устранение дисбаланса MongoDB

|Цель|Рекомендация||
|--|--|--|
|Автоматизация| Включить балансировщик |
|Холодные данные | Использовать hash-ключ |
|Горячие данные | Использовать составной ключ, чтобы дробить коллекции  |
|Масштабирование | Добавить новый шард |

## Способ 1 - Включить автоматический балансировщик (Balancer)
### MongoDB имеет встроенный балансировщик чанков между шардами
```
sh.getBalancerState() //проверить включен ли балансировщик
```
Включи балансировку, если выключено
```
sh.startBalancer()
```

### Можно мастроить время работы Balancer, для регулярной ребалансировки в определенное время.
По умолчанию работает круглосуточно, но можно задать временной интервал

Например, ограничить работу балансировщика ночным временем:
```
use config
db.settings.updateOne(
  { _id: "balancer" },
  {
    $set: {
      activeWindow : { start : "02:00", stop : "06:00" }
    }
  },
  { upsert: true }
)
```

## Способ 2 - Изменение ключа
### 2.1. Хэш-ключ
Варинт по умолчанию.

Но может случиться так, что все популярные позиции СЛУЧАЙНО придутся на один шард.

```
sh.shardCollection("store.products", { productId: "hashed" })
```
### 2.2. Составной ключ

Можно использовать составной ключ, чтобы "дробить" попурярные разделы.
Например, вместо ключа ```{ categoryId }``` использовать ```{ categoryId, brandId }```


## Способ 3 - Ручная балансировка шардов
Если нужно немедленно разгрузить шард — можно вручную переместить чанки
```
use admin
db.runCommand({
  moveChunk: "your_db.products",
  find: { categoryId: "electronics" },  // какой документ/диапазон перемещаем
  to: "target_shard_name"               // куда перемещаем
})
```

## Способ 4 - Добавление новых шардов
При росте общей регулярной нагрузки нужно добавить новые шарды:

```
sh.addShard("new-shard-hostname:27018") // Создать новый шард
sh.status() // сразу проверь
```