/* =====================================================================
   PIZZA SALES ANALYSIS - PostgreSQL
   Dataset : pizza_sales.csv (48,620 rows, 1 Jan 2015 - 31 Dec 2015)
   Sections: 0. Setup  |  A. KPIs  |  B-H. Chart queries  |  I. Filters
             |  J. Business questions
   ===================================================================== */


/* ---------------------------------------------------------------------
   0. SETUP: create table, load CSV, sanity checks
   --------------------------------------------------------------------- */

DROP TABLE IF EXISTS pizza_sales;

CREATE TABLE pizza_sales (
    pizza_id          INT PRIMARY KEY,
    order_id          INT,
    pizza_name_id     VARCHAR(50),
    quantity          INT,
    order_date        DATE,
    order_time        TIME,
    unit_price        NUMERIC(10,2),
    total_price       NUMERIC(10,2),
    pizza_size        VARCHAR(10),
    pizza_category    VARCHAR(50),
    pizza_ingredients TEXT,
    pizza_name        VARCHAR(100)
);

-- The CSV stores dates as DD-MM-YYYY, so tell Postgres to read day first.
SET datestyle = 'ISO, DMY';

-- Option 1 (psql): run from the folder that contains the CSV
-- \copy pizza_sales FROM 'data/pizza_sales.csv' WITH (FORMAT csv, HEADER true);
-- Option 2 (pgAdmin): right-click the table > Import/Export Data > CSV, Header = Yes

-- Sanity checks
SELECT COUNT(*)                         AS total_rows FROM pizza_sales;   -- 48620
SELECT MIN(order_date) AS first_date,
       MAX(order_date) AS last_date     FROM pizza_sales;                 -- 2015-01-01 to 2015-12-31
SELECT COUNT(*) AS null_rows
FROM pizza_sales
WHERE order_id IS NULL OR quantity IS NULL OR order_date IS NULL
   OR order_time IS NULL OR total_price IS NULL;                          -- 0


/* ---------------------------------------------------------------------
   A. KPIs
   --------------------------------------------------------------------- */

-- 1. Total Revenue
SELECT SUM(total_price) AS total_revenue
FROM pizza_sales;

-- 2. Average Order Value
SELECT SUM(total_price) / COUNT(DISTINCT order_id) AS avg_order_value
FROM pizza_sales;

-- 3. Total Pizzas Sold
SELECT SUM(quantity) AS total_pizza_sold
FROM pizza_sales;

-- 4. Total Orders
SELECT COUNT(DISTINCT order_id) AS total_orders
FROM pizza_sales;

-- 5. Average Pizzas Per Order
SELECT CAST(
           CAST(SUM(quantity) AS DECIMAL(10,2)) /
           CAST(COUNT(DISTINCT order_id) AS DECIMAL(10,2))
       AS DECIMAL(10,2)) AS avg_pizzas_per_order
FROM pizza_sales;


/* ---------------------------------------------------------------------
   B. Daily Trend for Total Orders
   (TO_CHAR 'Day' pads with spaces in Postgres, so TRIM is needed;
    ISODOW makes Monday = 1 ... Sunday = 7 for correct ordering)
   --------------------------------------------------------------------- */
SELECT
    TRIM(TO_CHAR(order_date, 'Day')) AS order_day,
    COUNT(DISTINCT order_id)         AS total_orders
FROM pizza_sales
GROUP BY TRIM(TO_CHAR(order_date, 'Day')), EXTRACT(ISODOW FROM order_date)
ORDER BY EXTRACT(ISODOW FROM order_date);


/* ---------------------------------------------------------------------
   C. Hourly Trend for Orders
   --------------------------------------------------------------------- */
SELECT
    EXTRACT(HOUR FROM order_time) AS order_hour,
    COUNT(DISTINCT order_id)      AS total_orders
FROM pizza_sales
GROUP BY EXTRACT(HOUR FROM order_time)
ORDER BY order_hour;


/* ---------------------------------------------------------------------
   D. % of Sales by Pizza Category
   --------------------------------------------------------------------- */
SELECT
    pizza_category,
    CAST(SUM(total_price) AS DECIMAL(10,2)) AS total_revenue,
    CAST(SUM(total_price) * 100.0 /
         (SELECT SUM(total_price) FROM pizza_sales) AS DECIMAL(10,2)) AS pct
FROM pizza_sales
GROUP BY pizza_category
ORDER BY pct DESC;


/* ---------------------------------------------------------------------
   E. % of Sales by Pizza Size   (S = Small/Regular, M, L, XL, XXL)
   --------------------------------------------------------------------- */
SELECT
    pizza_size,
    CAST(SUM(total_price) AS DECIMAL(10,2)) AS total_revenue,
    CAST(SUM(total_price) * 100.0 /
         (SELECT SUM(total_price) FROM pizza_sales) AS DECIMAL(10,2)) AS pct
FROM pizza_sales
GROUP BY pizza_size
ORDER BY pct DESC;


/* ---------------------------------------------------------------------
   F. Total Pizzas Sold by Pizza Category
   --------------------------------------------------------------------- */
SELECT
    pizza_category,
    SUM(quantity) AS total_quantity_sold
FROM pizza_sales
GROUP BY pizza_category
ORDER BY total_quantity_sold DESC;

-- Same query for one month only (example: February). Change the number 1-12.
SELECT
    pizza_category,
    SUM(quantity) AS total_quantity_sold
FROM pizza_sales
WHERE EXTRACT(MONTH FROM order_date) = 2
GROUP BY pizza_category
ORDER BY total_quantity_sold DESC;


/* ---------------------------------------------------------------------
   G. Top 5 Best Sellers by Total Pizzas Sold
   --------------------------------------------------------------------- */
SELECT
    pizza_name,
    SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_pizza_sold DESC
LIMIT 5;


/* ---------------------------------------------------------------------
   H. Bottom 5 Sellers by Total Pizzas Sold
   --------------------------------------------------------------------- */
SELECT
    pizza_name,
    SUM(quantity) AS total_pizza_sold
FROM pizza_sales
GROUP BY pizza_name
ORDER BY total_pizza_sold ASC
LIMIT 5;


/* ---------------------------------------------------------------------
   I. Month / Quarter / Week filters
   Add a WHERE clause to any query above. Examples:
   --------------------------------------------------------------------- */

-- I-1. Total orders by day of the week for January
SELECT
    TRIM(TO_CHAR(order_date, 'Day')) AS order_day,
    COUNT(DISTINCT order_id)         AS total_orders
FROM pizza_sales
WHERE EXTRACT(MONTH FROM order_date) = 1
GROUP BY TRIM(TO_CHAR(order_date, 'Day')), EXTRACT(ISODOW FROM order_date)
ORDER BY EXTRACT(ISODOW FROM order_date);

-- I-2. Total orders by day of the week for Quarter 1 (Jan-Mar)
SELECT
    TRIM(TO_CHAR(order_date, 'Day')) AS order_day,
    COUNT(DISTINCT order_id)         AS total_orders
FROM pizza_sales
WHERE EXTRACT(QUARTER FROM order_date) = 1
GROUP BY TRIM(TO_CHAR(order_date, 'Day')), EXTRACT(ISODOW FROM order_date)
ORDER BY total_orders DESC;


/* ---------------------------------------------------------------------
   J. Business questions
   --------------------------------------------------------------------- */

-- J-1. Total revenue and number of orders in Q1 (Jan-Mar) of each year
SELECT
    EXTRACT(YEAR FROM order_date)    AS order_year,
    EXTRACT(QUARTER FROM order_date) AS order_quarter,
    SUM(total_price)                 AS total_revenue,
    COUNT(DISTINCT order_id)         AS total_orders
FROM pizza_sales
WHERE EXTRACT(QUARTER FROM order_date) = 1
GROUP BY EXTRACT(YEAR FROM order_date), EXTRACT(QUARTER FROM order_date)
ORDER BY order_year;

-- J-2. Monthly revenue trend
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS order_month,
    SUM(total_price)               AS total_revenue,
    COUNT(DISTINCT order_id)       AS total_orders
FROM pizza_sales
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY order_month;
