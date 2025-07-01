/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор: Андриив И.И.
 * Дата: 26.02
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
-- Напишите ваш запрос здесь
--общее количество игроков
WITH count_users AS (
SELECT COUNT(DISTINCT id) AS total_count,
-- количество платящих игроков в подзапросе
(SELECT COUNT(DISTINCT id) 
FROM fantasy.users 
WHERE payer = 1) AS count_pay
FROM fantasy.users
)
-- доля платящих игроков от всех зарегистрированных
SELECT *, 
ROUND(count_pay / total_count::numeric, 2) AS share_pay
FROM count_users;


-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
-- Напишите ваш запрос здесь
-- количество платящих игроков в разрезе расы в CTE
WITH table_1 AS (
SELECT r.race,
COUNT(u.id) AS count_pay,
total_count
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id = r.race_id
-- общее количество зарегистрированных игроков в разрезе расы в подзапросе
JOIN (SELECT race,
COUNT(u.id) AS total_count
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id = r.race_id
GROUP BY r.race) AS table_2 ON table_2.race = r.race
WHERE payer = 1
GROUP BY r.race, total_count
)
-- в основном запросе доля платящих игроков от общего количества игроков в разрезе расы
SELECT race,
count_pay,
total_count,
ROUND(count_pay / total_count::NUMERIC, 2) AS share_race
FROM table_1
ORDER BY share_race DESC;


-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
-- Напишите ваш запрос здесь
-- попробовала объединить оба варианта через UNION
SELECT COUNT(amount) AS total_count,
SUM(amount) AS total_sum,
MIN(amount) AS min_amount,
MAX(amount) AS max_amount,
ROUND(AVG(amount)::numeric,2) AS avg_amount,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
ROUND(STDDEV(amount)::NUMERIC, 2) AS standard_deviation
FROM fantasy.events
UNION 
SELECT COUNT(amount) AS total_count,
SUM(amount) AS total_sum,
MIN(amount) AS min_amount,
MAX(amount) AS max_amount,
ROUND(AVG(amount)::numeric,2) AS avg_amount,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) AS median_amount,
ROUND(STDDEV(amount)::NUMERIC, 2) AS standard_deviation
FROM fantasy.events
WHERE amount != 0;

-- 2.2: Аномальные нулевые покупки:
-- Напишите ваш запрос здесь
-- абсолютное количество
SELECT COUNT(amount) AS zero_cost_count,
-- доля от общего количества
ROUND(COUNT(amount)::numeric / (SELECT COUNT(amount) FROM fantasy.events), 4) AS zero_share
FROM fantasy.events
WHERE amount = 0;

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
-- Напишите ваш запрос здесь

--  общее количество покупок, общая стоимость покупок для платящих и неплатящих в CTE:
WITH player_purchases AS (
SELECT u.payer, 
e.id AS player_id, 
COUNT(e.transaction_id) AS total_purchases, 
SUM(e.amount) AS total_amount
FROM fantasy.users AS u
JOIN fantasy.events AS e ON u.id = e.id
WHERE amount != 0
GROUP BY u.payer, e.id
)
-- общее количество игроков, выводим среднее из количества и стоимости покупок по группам 
-- добавила названия групп
SELECT CASE
	WHEN payer = 0
	THEN 'Неплатящие'
	ELSE 'Платящие'
END AS players,
COUNT(DISTINCT player_id) AS total_players,
ROUND(AVG(total_purchases)::NUMERIC, 2) AS avg_purchases_player,
ROUND(AVG(total_amount)::NUMERIC,2) AS avg_total_amount_player
FROM player_purchases
GROUP BY payer;

-- 2.4: Популярные эпические предметы:
-- Напишите ваш запрос здесь

SELECT i.game_items,
-- общее количество внутриигровых продаж
COUNT(e.transaction_id) AS count_transaction,
-- доля продажи каждого предмета от всех продаж
ROUND(COUNT(e.transaction_id)::numeric / (SELECT COUNT(transaction_id) FROM fantasy.events WHERE amount != 0), 7) AS share_transaction,
-- доля игроков, которые хотя бы раз покупали предмет
ROUND(COUNT(DISTINCT e.id)::numeric / (SELECT COUNT(DISTINCT id) FROM fantasy.events WHERE amount != 0), 5) AS share_players
FROM fantasy.events AS e
JOIN fantasy.items AS i ON e.item_code = i.item_code
WHERE amount != 0
GROUP BY i.game_items
ORDER BY share_transaction DESC;

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
-- Напишите ваш запрос здесь


--количество игроков, которые совершают внутриигровые покупки, и их доля от общего количества зарегистрированных игроков в разрезе расы
WITH table_1 AS (
SELECT r.race,
total_count,
COUNT(DISTINCT e.id) AS buy_players_count,
ROUND(COUNT(DISTINCT e.id)::numeric / total_count, 2) AS share_buy_players
FROM fantasy.users AS u 
JOIN fantasy.race AS r ON u.race_id = r.race_id
LEFT JOIN fantasy.events AS e ON e.id = u.id
--общее количество зарегистрированных игроков для каждой расы в подзапросе 
JOIN (SELECT race, 
COUNT(u.id) AS total_count
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id = r.race_id
GROUP BY r.race) AS tc ON r.race = tc.race
-- добавлена фильтрация нулевых покупок для buy_players_count и share_buy_players
WHERE amount != 0
GROUP BY r.race, total_count
),
--доля платящих игроков от количества игроков, которые совершили покупки в разрезе расы
table_2 AS (
SELECT r.race,
ROUND(COUNT(u.id)::numeric / total_count_race, 2) AS share_payer_players
FROM fantasy.users AS u
JOIN fantasy.race AS r ON u.race_id = r.race_id
JOIN (SELECT race,
COUNT(DISTINCT e.id) AS total_count_race
FROM fantasy.events AS e
JOIN fantasy.users AS u ON u.id= e.id
JOIN fantasy.race AS r ON u.race_id = r.race_id
GROUP BY r.race) AS tcr ON r.race = tcr.race
WHERE payer = 1
GROUP BY r.race, total_count_race
),
table_3 AS (
SELECT r.race,
u.id, 
--количество покупок на одного игрока
COUNT (e.transaction_id)  AS count_player,
--суммарная стоимость всех покупок на одного игрока
SUM(e.amount) AS sum_amount_player
FROM fantasy.users AS u
JOIN fantasy.events AS e ON u.id = e.id
JOIN fantasy.race AS r ON u.race_id = r.race_id
WHERE amount != 0
GROUP BY r.race, u.id
),
table_4 AS (
SELECT race,
--среднее количество покупок на одного игрока для расы
ROUND(AVG(count_player)::numeric, 2) AS avg_count_player,
--средняя суммарная стоимость всех покупок
ROUND(AVG(sum_amount_player)::numeric, 2) AS avg_sum_amount_player
FROM table_3
GROUP BY race
)
SELECT t.race,
t.total_count,
t.buy_players_count,
t.share_buy_players,
t2.share_payer_players,
t4.avg_count_player,
--средняя стоимость одной покупки на одного игрока для расы
ROUND(avg_sum_amount_player::numeric / avg_count_player, 2) AS avg_amount_player,
avg_sum_amount_player
FROM table_1 AS t
JOIN table_2 AS t2 ON t.race = t2.race
JOIN table_4 AS t4 ON t.race = t4.race;



