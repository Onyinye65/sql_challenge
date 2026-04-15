CREATE database pizza_runner;
USE pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INT NOT NULL ,
  registration_date DATE,
  PRIMARY KEY  (runner_id)
);
INSERT INTO runners (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INT,
  customer_id INT,
  pizza_id INT,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time DATETIME

);

INSERT INTO customer_orders (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  (1, 101, 1, '', '', '2020-01-01 18:05:02'),
  (2, 101, 1, '', '', '2020-01-01 19:00:52'),
  (3, 102, 1, '', '', '2020-01-02 23:51:23'),
  (3, 102, 2, '', NULL, '2020-01-02 23:51:23'),
  (4, 103, 1, '4', '', '2020-01-04 13:23:46'),
  (4, 103, 1, '4', '', '2020-01-04 13:23:46'),
  (4, 103, 2, '4', '', '2020-01-04 13:23:46'),
  (5, 104, 1, 'null', '1', '2020-01-08 21:00:29'),
  (6, 101, 2, 'null', 'null', '2020-01-08 21:03:13'),
  (7, 105, 2, 'null', '1', '2020-01-08 21:20:29'),
  (8, 102, 1, 'null', 'null', '2020-01-09 23:54:33'),
  (9, 103, 1, '4', '1, 5', '2020-01-10 11:22:59'),
  (10, 104, 1, 'null', 'null', '2020-01-11 18:34:49'),
  (10, 104, 1, '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INT,
  runner_id INT,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  (1, 1, '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  (2, 1, '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  (3, 1, '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  (4, 2, '2020-01-04 13:53:03', '23.4', '40', NULL),
  (5, 3, '2020-01-08 21:10:57', '10', '15', NULL),
  (6, 3, 'null', 'null', 'null', 'Restaurant Cancellation'),
  (7, 2, '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  (8, 2, '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  (9, 2, 'null', 'null', 'null', 'Customer Cancellation'),
  (10, 1, '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INT,
  pizza_name VARCHAR(50)
);
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings VARCHAR(50)
);
INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INT,
  topping_name VARCHAR(50)
);
INSERT INTO pizza_toppings (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  
  

SET SQL_SAFE_UPDATES = 0;

UPDATE customer_orders
SET 
  exclusions = NULLIF(TRIM(exclusions), ''),
  extras = NULLIF(TRIM(extras), '')
WHERE exclusions IN ('', 'null') OR extras IN ('', 'null');

SET SQL_SAFE_UPDATES = 1;

ALTER TABLE customer_orders
  MODIFY exclusions VARCHAR(10) NULL,
  MODIFY extras VARCHAR(10) NULL;
 
 
 -- Clean runner_orders
 SET SQL_SAFE_UPDATES = 0;
 UPDATE runner_orders
 SET 
   pickup_time = NULLIF(TRIM(pickup_time), 'null'),
   distance = NULLIF(TRIM(REPLACE(REPLACE(distance, 'km',''), ' ','')), 'null'),
   duration = NULLIF(TRIM(REGEXP_REPLACE(duration, '[^0-9]', '')), 'null'),
   cancellation = NULLIF(TRIM(cancellation), '')
WHERE pickup_time = 'null' OR distance= 'null' OR duration = 'null' OR cancellation IN ('', 'null');

 -- A. Pizza Metrics
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS total_pizzas_ordered
FROM customer_orders;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM customer_orders;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) AS successful_deliveries
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- 4 How many of each type of pizza was delivered?
SELECT pn.pizza_name, count(*) AS pizza_delivered
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
WHERE ro.cancellation IS NULL
group by pn.pizza_name;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT 
  co.customer_id,
  SUM(CASE WHEN pn.pizza_name = 'Meatlovers' THEN 1 ELSE 0 END) AS meatlovers,
  SUM(CASE WHEN pn.pizza_name = 'Vegetarian' THEN 1 ELSE 0 END) AS vegetarian
FROM customer_orders co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
GROUP BY co.customer_id;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT co.order_id, COUNT(*) AS pizza_count
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.order_id
ORDER BY pizza_count DESC
LIMIT 1;

-- 7. Delivered pizzas with at least 1 change vs no changes per customer?
SELECT 
  co.customer_id,
  SUM(CASE WHEN co.exclusions IS NOT NULL OR co.extras IS NOT NULL THEN 1 ELSE 0 END) AS with_changes,
  SUM(CASE WHEN co.exclusions IS NULL AND co.extras IS NULL THEN 1 ELSE 0 END) AS no_changes
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id;

-- 8. How many pizzas were delivered with both exclusions AND extras?
SELECT COUNT(*) AS both_exclusions_and_extras
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
  AND co.exclusions IS NOT NULL
  AND co.extras IS NOT NULL;
  
 -- 9. Total volume of pizzas ordered for each hour of the day?
 SELECT HOUR(order_time) AS hour_of_day, COUNT(*) AS total_pizzas
FROM customer_orders
GROUP BY HOUR(order_time)
ORDER BY hour_of_day;

-- 10. Volume of orders for each day of the week?
SELECT DAYNAME(order_time) AS day_of_week, COUNT(*) AS total_orders
FROM customer_orders
GROUP BY DAYNAME(order_time), DAYOFWEEK(order_time)
ORDER BY DAYOFWEEK(order_time);

-- B. Runner and Customer Experience
-- 1. How many runners signed up per week?
SELECT 
  FLOOR(DATEDIFF(registration_date, '2021-01-01') / 7) + 1 AS week_number,
  COUNT(*) AS runners_signed_up
FROM runners
GROUP BY week_number;

-- 2. Average pickup time per runner (in minutes)?
SELECT 
  ro.runner_id,
  ROUND(AVG(TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)), 2) AS avg_pickup_minutes
FROM runner_orders ro
JOIN customer_orders co ON ro.order_id = co.order_id
WHERE ro.pickup_time IS NOT NULL
GROUP BY ro.runner_id;

-- 3. Relationship between number of pizzas and preparation time?
SELECT 
  co.order_id,
  COUNT(*) AS pizza_count,
  TIMESTAMPDIFF(MINUTE, MIN(co.order_time), MIN(ro.pickup_time)) AS prep_time_minutes
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.pickup_time IS NOT NULL
GROUP BY co.order_id
ORDER BY pizza_count;

-- 4. Average distance travelled per customer?
SELECT 
  co.customer_id,
  ROUND(AVG(CAST(ro.distance AS DECIMAL(5,2))), 2) AS avg_distance_km
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL
GROUP BY co.customer_id;

-- 5. Difference between longest and shortest delivery times?
SELECT 
  MAX(CAST(duration AS UNSIGNED)) - MIN(CAST(duration AS UNSIGNED)) AS delivery_time_difference
FROM runner_orders
WHERE duration IS NOT NULL;

-- 6. Average speed per runner per delivery?
SELECT 
  runner_id,
  order_id,
  CAST(distance AS DECIMAL(5,2)) AS distance_km,
  CAST(duration AS UNSIGNED) AS duration_mins,
  ROUND((CAST(distance AS DECIMAL(5,2)) / CAST(duration AS UNSIGNED)) * 60, 2) AS avg_speed_kmh
FROM runner_orders
WHERE cancellation IS NULL
ORDER BY runner_id, order_id;

-- 7. Successful delivery percentage per runner?
SELECT 
  runner_id,
  COUNT(*) AS total_orders,
  SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) AS successful,
  ROUND(SUM(CASE WHEN cancellation IS NULL THEN 1 ELSE 0 END) / COUNT(*) * 100, 0) AS success_percentage
FROM runner_orders
GROUP BY runner_id;

-- C. Ingredient Optimisation
-- 1. Standard ingredients for each pizza?
SELECT 
  pn.pizza_name,
  GROUP_CONCAT(pt.topping_name ORDER BY pt.topping_name SEPARATOR ', ') AS ingredients
FROM pizza_recipes pr
JOIN pizza_names pn ON pr.pizza_id = pn.pizza_id
JOIN pizza_toppings pt 
  ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', ''))
GROUP BY pn.pizza_name;


-- 2. Most commonly added extra?
SELECT pt.topping_name, COUNT(*) AS times_added
FROM customer_orders co
JOIN pizza_toppings pt 
  ON FIND_IN_SET(pt.topping_id, REPLACE(co.extras, ' ', ''))
WHERE co.extras IS NOT NULL
GROUP BY pt.topping_name
ORDER BY times_added DESC
LIMIT 1;
-- 3. Most common exclusion?
SELECT pt.topping_name, COUNT(*) AS times_excluded
FROM customer_orders co
JOIN pizza_toppings pt 
  ON FIND_IN_SET(pt.topping_id, REPLACE(co.exclusions, ' ', ''))
WHERE co.exclusions IS NOT NULL
GROUP BY pt.topping_name
ORDER BY times_excluded DESC
LIMIT 1;


-- 4. Generate order item description per record?
SELECT 
  co.order_id,
  co.customer_id,
  pn.pizza_name,
  co.exclusions,
  co.extras,
  CONCAT(
    pn.pizza_name,
    CASE WHEN co.exclusions IS NOT NULL 
      THEN CONCAT(' - Exclude ', (
        SELECT GROUP_CONCAT(pt.topping_name SEPARATOR ', ')
        FROM pizza_toppings pt
        WHERE FIND_IN_SET(pt.topping_id, REPLACE(co.exclusions, ' ', ''))
      ))
      ELSE '' END,
    CASE WHEN co.extras IS NOT NULL 
      THEN CONCAT(' - Extra ', (
        SELECT GROUP_CONCAT(pt.topping_name SEPARATOR ', ')
        FROM pizza_toppings pt
        WHERE FIND_IN_SET(pt.topping_id, REPLACE(co.extras, ' ', ''))
      ))
      ELSE '' END
  ) AS order_item
FROM customer_orders co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id;


-- 5. Alphabetically ordered ingredient list with 2x for extras?
SELECT 
  co.order_id,
  co.customer_id,
  CONCAT(pn.pizza_name, ': ',
    GROUP_CONCAT(
      CASE WHEN FIND_IN_SET(pt.topping_id, REPLACE(co.extras, ' ', '')) THEN CONCAT('2x', pt.topping_name)
           ELSE pt.topping_name END
      ORDER BY pt.topping_name SEPARATOR ', '
    )
  ) AS ingredient_list
FROM customer_orders co
JOIN pizza_names pn ON co.pizza_id = pn.pizza_id
JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
JOIN pizza_toppings pt ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', ''))
WHERE NOT FIND_IN_SET(pt.topping_id, REPLACE(COALESCE(co.exclusions, ''), ' ', ''))
GROUP BY co.order_id, co.customer_id, pn.pizza_name, co.extras;


-- 6. Total quantity of each ingredient used in delivered pizzas?
SELECT 
  pt.topping_name,
  COUNT(*) AS times_used
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN pizza_recipes pr ON co.pizza_id = pr.pizza_id
JOIN pizza_toppings pt ON FIND_IN_SET(pt.topping_id, REPLACE(pr.toppings, ' ', ''))
WHERE ro.cancellation IS NULL
  AND NOT FIND_IN_SET(pt.topping_id, REPLACE(COALESCE(co.exclusions, ''), ' ', ''))
GROUP BY pt.topping_name
ORDER BY times_used DESC;


-- D. Pricing and Ratings
-- 1. Total revenue — no delivery fees, no charge for changes?
SELECT 
  SUM(CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END) AS total_revenue
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;


-- 2. Revenue with $1 charge per extra topping?
SELECT 
  SUM(
    CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END +
    CASE WHEN co.extras IS NOT NULL 
      THEN LENGTH(co.extras) - LENGTH(REPLACE(co.extras, ',', '')) + 1
      ELSE 0 END
  ) AS total_revenue_with_extras
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;


-- 3. Runner ratings table schema + data?
DROP TABLE IF EXISTS runner_ratings;
CREATE TABLE runner_ratings (
  rating_id    INTEGER AUTO_INCREMENT PRIMARY KEY,
  order_id     INTEGER NOT NULL,
  customer_id  INTEGER NOT NULL,
  runner_id    INTEGER NOT NULL,
  rating       INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
  rated_at     DATETIME DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO runner_ratings (order_id, customer_id, runner_id, rating)
VALUES
  (1,  101, 1, 4),
  (2,  101, 1, 5),
  (3,  102, 1, 3),
  (4,  103, 2, 4),
  (5,  104, 3, 5),
  (7,  105, 2, 3),
  (8,  102, 2, 4),
  (10, 104, 1, 5);


-- 4. Full successful delivery summary table?
SELECT 
  co.customer_id,
  co.order_id,
  ro.runner_id,
  rr.rating,
  co.order_time,
  ro.pickup_time,
  TIMESTAMPDIFF(MINUTE, co.order_time, ro.pickup_time)    AS mins_between_order_and_pickup,
  CAST(ro.duration AS UNSIGNED)                           AS delivery_duration_mins,
  ROUND(CAST(ro.distance AS DECIMAL(5,2)) / 
        CAST(ro.duration AS UNSIGNED) * 60, 2)            AS avg_speed_kmh,
  COUNT(co.pizza_id) OVER (PARTITION BY co.order_id)      AS total_pizzas
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
JOIN runner_ratings rr ON co.order_id = rr.order_id
WHERE ro.cancellation IS NULL
ORDER BY co.order_id;


-- 5. Profit after paying runners $0.30/km?
SELECT 
  SUM(CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END) AS total_revenue,
  ROUND(SUM(CAST(ro.distance AS DECIMAL(5,2)) * 0.30), 2) AS runner_cost,
  ROUND(SUM(CASE WHEN co.pizza_id = 1 THEN 12 ELSE 10 END) - 
        SUM(CAST(ro.distance AS DECIMAL(5,2)) * 0.30), 2) AS net_profit
FROM customer_orders co
JOIN runner_orders ro ON co.order_id = ro.order_id
WHERE ro.cancellation IS NULL;


-- E. Bonus — Adding a Supreme Pizza
-- Add to pizza_names







