-- Задача 1. Время активности объявлений
--Запрос 1. Всего объявлений в СПб и Ленобласти, доля от общего количества, данные по регионам
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
-- CTE с категориями:
categories AS (
SELECT CASE 
	WHEN c.city = 'Санкт-Петербург'
	THEN 'Санкт-Петербург'
	ELSE 'ЛенОбл'
END AS region, 
CASE 
	WHEN a.days_exposition BETWEEN 1 AND 30
	THEN 'Месяц'
	WHEN a.days_exposition BETWEEN 31 AND 90
	THEN 'Квартал'
	WHEN a.days_exposition BETWEEN 91 AND 180
	THEN 'Полгода'
	WHEN a.days_exposition > 181
	THEN 'Более полугода'
	ELSE 'Еще активны'
END AS activity,
a.last_price / f.total_area AS price1,
f.rooms,
f.balcony, 
f.floor,
a.id,
f.floors_total,
f.open_plan,
f.total_area,
a.last_price
FROM real_estate.flats AS f
INNER JOIN real_estate.advertisement AS a ON f.id = a.id
INNER JOIN real_estate.city AS c ON f.city_id = c.city_id
INNER JOIN real_estate.TYPE AS t ON f.type_id = t.type_id
WHERE f.id IN (SELECT * FROM filtered_id)
AND t.TYPE = 'город')
--основной запрос с основными показателями
SELECT region, COUNT(id) AS count_advertisement, 
ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER(), 2) AS share_total,
ROUND(AVG(price1)::NUMERIC,2) AS AVG_PRICE1,
ROUND(AVG(total_area)::NUMERIC, 2) AS AVG_total_area,
ROUND(AVG(floors_total)::NUMERIC, 0) AS avg_floors_total,
MAX(last_price) AS MAX_last_price,
AVG(last_price) AS AVG_last_price
FROM categories
GROUP BY region;


--Запрос 2. Всего объявлений в СПб и Ленобласти по времени публикации, статистические показатели по времени публикации
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
-- CTE с категориями:
categories AS (
SELECT CASE 
	WHEN c.city = 'Санкт-Петербург'
	THEN 'Санкт-Петербург'
	ELSE 'ЛенОбл'
END AS region, 
CASE 
	WHEN a.days_exposition BETWEEN 1 AND 30
	THEN 'Месяц'
	WHEN a.days_exposition BETWEEN 31 AND 90
	THEN 'Квартал'
	WHEN a.days_exposition BETWEEN 91 AND 180
	THEN 'Полгода'
	WHEN a.days_exposition > 181
	THEN 'Более полугода'
	ELSE 'Еще активны'
END AS activity,
a.last_price / f.total_area AS  price1,
f.total_area,
f.rooms,
f.balcony, 
f.floor,
a.id
FROM real_estate.flats AS f
JOIN real_estate.advertisement AS a ON f.id = a.id
JOIN real_estate.city AS c ON f.city_id = c.city_id
JOIN real_estate.TYPE AS t ON f.type_id = t.type_id
WHERE f.id IN (SELECT * FROM filtered_id)
AND t.TYPE = 'город')
--основной запрос, считаются показатели
SELECT region, activity,
COUNT(id) AS count_advertisement, 
ROUND(COUNT(*)::NUMERIC / SUM(COUNT(*)) OVER(), 2) AS share_total,
ROUND(AVG(price1)::NUMERIC,2) AS AVG_PRICE,
ROUND(AVG(total_area)::NUMERIC, 2) AS AVG_total_area,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY rooms) AS mediana_rooms,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY balcony) AS mediana_balcony,
PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY floor) AS mediana_floor
FROM categories 
GROUP BY region, activity

-- Задача 2. Сезонность объявлений

WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
--статистика для активных объявлений
table1 AS (
SELECT 
--месяц публикации объявления
DATE_TRUNC('month', first_day_exposition)::date AS date_publication,
count(a.id) AS count_active,
ROUND(AVG(a.last_price / f.total_area)::NUMERIC, 2) AS avg_price1_active,
ROUND(AVG(f.total_area)::numeric, 2) AS avg_area_active
FROM real_estate.flats AS f
JOIN real_estate.advertisement AS a ON f.id = a.id
JOIN real_estate.type AS t ON f.type_id = t.type_id
WHERE f.id IN (SELECT * FROM filtered_id) AND t.type = 'город' AND days_exposition IS NULL
GROUP BY DATE_TRUNC('month', first_day_exposition)::date
),
--статистика для снятых с публикации объявлений
table2 AS (
SELECT 
--месяц публикации объявления
DATE_TRUNC('month', first_day_exposition)::date AS date_publication,
count(a.id) AS count_removal,
ROUND(AVG(a.last_price / f.total_area)::NUMERIC, 2) AS avg_price1_removal,
ROUND(AVG(f.total_area)::numeric, 2) AS avg_area_removal
FROM real_estate.flats AS f
JOIN real_estate.advertisement AS a ON f.id = a.id
JOIN real_estate.type AS t ON f.type_id = t.type_id
WHERE f.id IN (SELECT * FROM filtered_id) AND t.type = 'город' AND days_exposition IS not NULL
GROUP BY DATE_TRUNC('month', first_day_exposition)::date
),
--общее количество опубликованных объявлений
table3 AS (
SELECT -- месяц публикации объявления
	DATE_TRUNC('month', first_day_exposition)::date AS date_publication,
	COUNT(a.id) AS total_count
	FROM real_estate.flats AS f
	JOIN real_estate.advertisement AS a ON f.id = a.id
	JOIN real_estate.type AS t ON f.type_id = t.type_id
	WHERE f.id IN (SELECT * FROM filtered_id) AND t.type = 'город'
	GROUP BY DATE_TRUNC('month', first_day_exposition)::date
	)
SELECT t1.date_publication,
total_count,
count_active,
--изменение публикации объявлений по сравнению с прошлым месяцем для активных объявлений
	count_active - LAG(count_active) OVER (ORDER BY t1.date_publication) AS absolut_difference_publication,
	CONCAT(ROUND(NULLIF((count_active - LAG(count_active) OVER (ORDER BY t1.date_publication)),0) / 
count_active::NUMERIC * 100.0, 0), '%') AS difference_publication,
avg_price1_active,
avg_area_active,
count_removal,
--изменение снятия объявлений по сравнению с прошлым месяцем для снятых объявлений
	count_removal - LAG(count_removal) OVER (ORDER BY t1.date_publication) AS absolut_difference_removal,
	CONCAT(ROUND(NULLIF((count_removal - LAG(count_removal) OVER (ORDER BY t1.date_publication)),0) / 
NULLIF(count_removal,0)::NUMERIC * 100.0, 0), '%') AS difference_removal,
avg_price1_removal,
avg_area_removal
FROM table1 AS t1
FULL JOIN table2 AS t2 ON t1.date_publication = t2.date_publication
FULL JOIN table3 AS t3 ON t1.date_publication = t3.date_publication
ORDER BY date_publication



-- Задача 3. Анализ рынка недвижимости Ленобласти
WITH limits AS (
    SELECT  
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY total_area) AS total_area_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY rooms) AS rooms_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY balcony) AS balcony_limit,
        PERCENTILE_DISC(0.99) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_h,
        PERCENTILE_DISC(0.01) WITHIN GROUP (ORDER BY ceiling_height) AS ceiling_height_limit_l
    FROM real_estate.flats     
),
-- Найдём id объявлений, которые не содержат выбросы:
filtered_id AS(
    SELECT id
    FROM real_estate.flats  
    WHERE 
        total_area < (SELECT total_area_limit FROM limits)
        AND (rooms < (SELECT rooms_limit FROM limits) OR rooms IS NULL)
        AND (balcony < (SELECT balcony_limit FROM limits) OR balcony IS NULL)
        AND ((ceiling_height < (SELECT ceiling_height_limit_h FROM limits)
            AND ceiling_height > (SELECT ceiling_height_limit_l FROM limits)) OR ceiling_height IS NULL)
    ),
table1 AS(
	SELECT city, 
--количество опубликованных объявлений
	COUNT(a.id) AS count_publication,
--количество снятых объявлений
	COUNT(a.id) FILTER (WHERE DATE_TRUNC('month', (first_day_exposition + (days_exposition || 'day')::INTERVAL))::date IS NOT NULL)
AS count_removal,
--доля снятых объявлений
	ROUND(COUNT(a.id) FILTER (WHERE DATE_TRUNC('month', (first_day_exposition + (days_exposition || 'day')::INTERVAL))::date IS NOT NULL) /
COUNT(a.id)::NUMERIC,2) AS share_removal,
--средняя стоимость квадратного метра
	ROUND(AVG(a.last_price / f.total_area)::numeric, 2) AS avg_price1,
-- средняя площадь 
	ROUND(AVG(f.total_area)::numeric, 2) AS avg_total_area,
	ROUND(AVG(floors_total)::NUMERIC,0) AS avg_floors_total,
	ROUND(AVG(days_exposition)::NUMERIC, 0) AS avg_days_exposition
	FROM real_estate.flats AS f
	JOIN real_estate.advertisement AS a ON f.id = a.id
	JOIN real_estate.city AS c ON f.city_id = c.city_id
	WHERE c.city !='Санкт-Петербург' AND f.id IN (SELECT * FROM filtered_id)
	GROUP BY city
)
SELECT *,
CASE 
	WHEN avg_days_exposition BETWEEN 1 AND 30
	THEN 'Месяц'
	WHEN avg_days_exposition BETWEEN 31 AND 90
	THEN 'Квартал'
	WHEN avg_days_exposition BETWEEN 91 AND 180
	THEN 'Полгода'
	WHEN avg_days_exposition > 181
	THEN 'Более полугода'
	ELSE 'Еще активны'
END AS activity,
RANK() OVER (ORDER BY count_publication DESC) AS rating
FROM table1
ORDER BY rating
LIMIT 15

    

