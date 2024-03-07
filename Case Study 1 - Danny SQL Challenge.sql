CREATE DATABASE danny_sql;

CREATE TABLE sales (
	"customer_id" VARCHAR(1),
	"order_date" DATE,
	"product_id" INTEGER
	);

INSERT INTO sales
	("customer_id", "order_date", "product_id")
VALUES
	 ('A', '2021-01-01', '1'),
	 ('A', '2021-01-01', '2'),
	 ('A', '2021-01-07', '2'),
	 ('A', '2021-01-10', '3'),
	 ('A', '2021-01-11', '3'),
	 ('A', '2021-01-11', '3'),
	 ('B', '2021-01-01', '2'),
	 ('B', '2021-01-02', '2'),
	 ('B', '2021-01-04', '1'),
	 ('B', '2021-01-11', '1'),
	 ('B', '2021-01-16', '3'),
	 ('B', '2021-02-01', '3'),
	 ('C', '2021-01-01', '3'),
	 ('C', '2021-01-01', '3'),
	 ('C', '2021-01-07', '3');

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


 ----------------------------------------------------Case Study Questions----------------------------------------------------

-- 1. What is the total amount each customer spent at the restaurant?

SELECT
customer_id,
SUM(price) AS total_amount
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT
customer_id,
COUNT(DISTINCT order_date) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH CTE AS (
  SELECT
  s.customer_id,
  s.order_date,
  m.product_name,
  ROW_NUMBER() OVER (PARTITION by s.customer_id ORDER BY s.order_date) AS first_item
  FROM sales s
  INNER JOIN menu m ON s.product_id = m.product_id
  )
SELECT
customer_id,
product_name
FROM CTE
WHERE first_item = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT TOP 1
m.product_name,
COUNT(s.order_date)
FROM sales s
INNER JOIN menu m on s.product_id = m.product_id
GROUP BY product_name
ORDER BY COUNT(order_date) DESC;

-- 5. Which item was the most popular for each customer?

WITH cte AS (
  SELECT
  m.product_name,
  s.customer_id,
  COUNT(s.order_date) orders,
  RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.order_date)DESC) popular_item
  FROM sales s
  INNER JOIN menu m on s.product_id = m.product_id
  GROUP BY m.product_name, s.customer_id
)
SELECT
customer_id,
product_name,
orders
FROM cte
where popular_item = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH cte AS (
  SELECT
  m.customer_id,
  m.join_date,
  s.order_date,
  s.product_id,
  me.product_name,
  ROW_NUMBER() OVER (PARTITION by m.join_date ORDER BY m.customer_id) first_purchase
  FROM members m
  JOIN sales s on m.customer_id = s.customer_id
  JOIN menu me on s.product_id = me.product_id
  WHERE m.join_date <= s.order_date
)
SELECT
customer_id,
product_name
FROM cte
WHERE first_purchase = 1;

-- 7. Which item was purchased just before the customer became a member?

WITH cte AS (
  SELECT
  s.customer_id,
  me.join_date,
  s.order_date,
  m.product_name,
  RANK() OVER (PARTITION BY me.join_date ORDER BY s.order_date DESC) item_before_member
  FROM members me
  JOIN sales s ON me.customer_id = s.customer_id
  JOIN menu m ON s.product_id = m.product_id
  WHERE s.order_date < me.join_date
)
SELECT
customer_id,
product_name
FROM cte
WHERE item_before_member = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
s.customer_id,
COUNT(s.order_date) total_items,
SUM(me.price) amount_spent
FROM sales s
JOIN members m ON s.customer_id = m.customer_id
JOIN menu me ON s.product_id = me.product_id
WHERE m.join_date > s.order_date
GROUP BY s.customer_id;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT
s.customer_id,
SUM(
  CASE
    WHEN product_name = 'sushi' THEN price * 10 * 2
    ELSE price * 10 
  END) points
FROM menu m
JOIN sales s ON s.product_id = m.product_id
GROUP BY s.customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT
s.customer_id,
SUM(
  CASE
  WHEN s.order_date BETWEEN me.join_date AND DATEADD(DAY, 6, me.join_date) THEN price * 10 * 2
  WHEN m.product_name = 'sushi' THEN price * 10 * 2
  ELSE price * 10
END) points
FROM menu m
INNER JOIN sales s on s.product_id = m.product_id
INNER JOIN members me ON me.customer_id = s.customer_id
WHERE DATETRUNC(MONTH, s.order_date) = '2021-01-01'
GROUP BY s.customer_id;

----------------------------BONUS QUESTION----------------------------

---------------Join All The Things---------------

SELECT
s.customer_id,
s.order_date,
m.product_name,
m.price,
CASE
  WHEN me.join_date is NULL THEN 'N'
  WHEN me.join_date > s.order_date THEN 'N'
  ELSE 'Y'
END member
FROM sales s
INNER JOIN menu m ON m.product_id = s.product_id
LEFT JOIN members me ON me.customer_id = s.customer_id
ORDER BY s.customer_id, s.order_date, m.price DESC;

---------------Rank All The Things--------------- 

WITH cte AS (
  SELECT
  s.customer_id,
  s.order_date,
  m.product_name,
  m.price,
  CASE
    WHEN me.join_date IS NULL THEN 'N'
    WHEN me.join_date > s.order_date THEN 'N'
    ELSE 'Y'
  END member
  FROM sales s
  JOIN menu m ON m.product_id = s.product_id
  JOIN members me ON me.customer_id = s.customer_id
)
SELECT
*,
CASE
  WHEN member = 'N' THEN 'null'
  ELSE CAST(RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) AS varchar)
END AS ranking
FROM cte;
