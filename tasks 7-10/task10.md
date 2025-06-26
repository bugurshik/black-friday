## 10.1 - Обоснование применения Cassandra для указанных сущностей
Cassandra — это лидерless распределенная NoSQL БД, которая идеально подходит для сценариев:

- Высокой скорости записи : например, обработка множества событий от пользователей.
- Равномерного распределения данных : благодаря consistent hashing и token-aware роутингу.
- Горизонтального масштабирования : при добавлении новых узлов Cassandra не перераспределяет все данные сразу, а постепенно балансирует нагрузку.
- Отказоустойчивости : отсутствие single point of failure.

### Products
Особого прироста производительности перенос products в Cassandra не даст, т.к. это данные меняются редко. А самые популярные и запросы попадут в кэш.
- Единственный плюс -> высокая доступность и геораспределение

### Orders
Cassandra подходит благодаря отказоустойчивости, распределению нагрузки и возможности горизонтального масштабирования

- Это основной источник дохода.
- Требуется гарантированная запись без потерь.
- Частые изменения статусов
- Важна история заказов для пользователей и аналитики

```sql
CREATE TABLE orders (
    user_id UUID,
    order_id UUID,
    created_at TIMESTAMP,
    status TEXT,
    total_amount DECIMAL,
    zone TEXT,
    items LIST<FROZEN<ITEM>>,
    PRIMARY KEY ((user_id), created_at)
) WITH CLUSTERING ORDER BY (created_at DESC);
```
Обоснование структуры:
- user_id как partition key — все заказы одного пользователя попадают в одну партицию.
- created_at как clustering key — позволяет эффективно фильтровать по времени.
- items хранятся в виде списка вложенных объектов (FROZEN), чтобы избежать сложных JOIN’ов

### Carts
Cassandra подходит
- Хранят временные данные о товарах перед оформлением заказа.
- Частое изменение содержимого корзины.
- Важно сохранить корзину при переходе от гостя к авторизованному пользователю

```sql
CREATE TYPE item_type (
    product_id UUID,
    quantity INT,
    price DECIMAL
);

CREATE TABLE carts_by_user (
    user_id UUID PRIMARY KEY,
    cart_id UUID,
    expires_at TIMESTAMP,
    items LIST<FROZEN<item_type>>,
    updated_at TIMESTAMP
);

CREATE TABLE carts_by_session (
    session_id UUID PRIMARY KEY,
    cart_id UUID,
    expires_at TIMESTAMP,
    items LIST<FROZEN<item_type>>,
    created_at TIMESTAMP,
    updated_at TIMESTAMP
);

CREATE TABLE user_sessions (
    session_id UUID PRIMARY KEY,
    user_id UUID,
    data TEXT,
    expires_at TIMESTAMP
) WITH default_time_to_live = 86400;
```
Хранение информации о сессии пользователя.
Обоснование структуры:
- Хранение одной активной корзины на пользователя.
Удобство обновления/чтения по user_id.
- После входа пользователя можно легко получить гостевую корзину и объединить с пользовательской
- Каждая сессия уникальна и хранится как отдельная запись, кластерный ключ не нужен.
- TTL автоматически удаляет истекшие сессии.
- Преимущества:
    - Быстрое получение сессии.
    - Автоматическая очистка старых записей.


## 10.2 Концептуальная модель
|Коллекция| Partition Key|Clustering Key|Цель|
|-|-|-|-|
|orders|user_id|created_at|История заказов|
|carts_by_user|user_id|—|Корзина пользователя
|carts_by_session|session_id|—|Гостевая корзина
|user_sessions|session_id|—|Сессии

## 10.3 Стратегии восстановления целостности

Общие рекомендации:
|Коллекция|Hinted Handoff|Read Repair|Anti-entropy repair| Комментарий|
|--|--|--|--|--|
|orders|да|да|да|Критичные данные.Требуют максимальной надежности|
|carts_by_user|да|нет|да|Важно сохранять данные, но допустимы небольшие ошибки|
|carts_by_session|да|нет|нет|Гостевые данные, менее критичны|
|user_sessions|да|нет|да|Сессии должны восстанавливаться при решардинге|