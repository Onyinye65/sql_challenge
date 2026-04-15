-- Create database (MySQL uses DATABASE instead of SCHEMA)

DROP DATABASE IF EXISTS dannys_diner;
CREATE DATABASE dannys_diner;

-- Use the database
USE dannys_diner;

-- Create sales table
CREATE TABLE sales (
  customer_id VARCHAR(1) NOT NULL,
  order_date DATE,
  product_id VARCHAR(2)
) ENGINE=InnoDB;

-- Insert into sales
INSERT INTO sales (customer_id, order_date, product_id) VALUES
('A', '2021-01-01', 1),
('A', '2021-01-01', 2),
('A', '2021-01-07', 2),
('A', '2021-01-10', 3),
('A', '2021-01-11', 3),
('A', '2021-01-11', 3),
('B', '2021-01-01', 2),
('B', '2021-01-02', 2),
('B', '2021-01-04', 1),
('B', '2021-01-11', 1),
('B', '2021-01-16', 3),
('B', '2021-02-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-01', 3),
('C', '2021-01-07', 3);

-- Create menu table
CREATE TABLE menu (
  product_id VARCHAR(2) NOT NULL ,
  product_name VARCHAR(10) NOT NULL,
  price INT,
  PRIMARY KEY (product_id)
);

-- Insert into menu
INSERT INTO menu (product_id, product_name, price) VALUES
(1, 'sushi', 10),
(2, 'curry', 15),
(3, 'ramen', 12);

-- Create members table
CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE

);

-- Insert into members
INSERT INTO members (customer_id, join_date) VALUES
('A', '2021-01-07'),
('B', '2021-01-09');

SELECT *
from menu
order by price desc;


-- Total amount each customer spent
SELECT s.customer_id,sum(price) as total_spend
FROM sales s
JOIN menu m
on s.product_id = m.product_id
group by s.customer_id
order by total_spend desc;

-- Number of days each customer visited
SELECT
  customer_id,
  COUNT(DISTINCT order_date) AS visit_days
FROM sales
GROUP BY customer_id
ORDER BY visit_days DESC;

-- First item purchased by each customers
SELECT
  s.customer_id,
  m.product_name,
  s.order_date
FROM sales s
JOIN menu m ON s.product_id = m.product_id
WHERE s.order_date IN (
  SELECT MIN(order_date)
  FROM sales s2
  WHERE s2.customer_id = s.customer_id
)
ORDER BY s.customer_id;

WITH ranked AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date
    ) AS rnk
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
)
SELECT DISTINCT customer_id, product_name, order_date
FROM ranked
WHERE rnk = 1;

-- Most purchase item and total purchase count
select   m.product_name,count(s.product_id) as total_purchase
from sales s
join menu m on s.product_id=m.product_id
group by m.product_name
order by total_purchase
limit 1;

-- Most popular item for each customer
WITH ranked AS (
  SELECT
    s.customer_id,
    m.product_name,
    COUNT(s.product_id) AS order_count,
    DENSE_RANK() OVER (
      PARTITION BY s.customer_id
      ORDER BY COUNT(s.product_id) DESC
    ) AS rnk
  FROM sales s
  JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, order_count
FROM ranked
WHERE rnk = 1;

-- First item purchased after becoming a member
WITH ranked AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    ROW_NUMBER() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date
    ) AS rnk
  FROM sales s
  JOIN members mb ON s.customer_id = mb.customer_id
    AND s.order_date >= mb.join_date
  JOIN menu m ON s.product_id = m.product_id
)
SELECT customer_id, product_name, order_date
FROM ranked
WHERE rnk = 1;

-- Items purchased before becoming a member
WITH ranked AS (
  SELECT
    s.customer_id,
    m.product_name,
    s.order_date,
    ROW_NUMBER() OVER (
      PARTITION BY s.customer_id
      ORDER BY s.order_date DESC
    ) AS rnk
  FROM sales s
  JOIN members mb ON s.customer_id = mb.customer_id
    AND s.order_date < mb.join_date
  JOIN menu m ON s.product_id = m.product_id
)
SELECT customer_id, product_name, order_date
FROM ranked
WHERE rnk = 1;

-- Total items and amount spent before membership
SELECT
  s.customer_id,
  COUNT(s.product_id)  AS total_items,
  SUM(m.price)         AS total_spent
FROM sales s
JOIN members mb ON s.customer_id = mb.customer_id
  AND s.order_date < mb.join_date
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- points per customer(suschi=2* multiplier)
SELECT
  s.customer_id,
  SUM(
    CASE
      WHEN m.product_name = 'sushi'
        THEN m.price * 20   -- 2× multiplier × 10 pts/$
      ELSE m.price * 10
    END
  ) AS total_points
FROM sales s
JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_points DESC;

-- Points for A & B at the end of january (first week *2 bonus)
SELECT
  s.customer_id,
  SUM(
    CASE
      -- First 7 days after joining: 2× on everything
      WHEN s.order_date BETWEEN mb.join_date
        AND DATE_ADD(mb.join_date, INTERVAL 6 DAY)
        THEN m.price * 20
      -- Outside first week: sushi still 2×
      WHEN m.product_name = 'sushi'
        THEN m.price * 20
      ELSE m.price * 10
    END
  ) AS total_points
FROM sales s
JOIN members mb ON s.customer_id = mb.customer_id
JOIN menu m    ON s.product_id  = m.product_id
WHERE s.customer_id IN ('A', 'B')
  AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id
ORDER BY s.customer_id;