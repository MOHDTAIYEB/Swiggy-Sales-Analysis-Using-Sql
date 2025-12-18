/* =============================================================================
   PROJECT: Swiggy Data Analysis Case Study (Star Schema Implementation)
   AUTHOR: [Your Name]
   DATABASE: MySQL
   
   DESCRIPTION: 
   This script transforms raw Swiggy delivery data into a structured Star Schema 
   to perform deep-dive business analysis. It covers ETL, Data Engineering, 
   and Business Intelligence reporting.
   ============================================================================= */

-- -----------------------------------------------------------------------------
-- 1. DATABASE & ENVIRONMENT SETUP
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS swiggy_db;
USE swiggy_db;

-- -----------------------------------------------------------------------------
-- 2. DATA CLEANING & PRE-PROCESSING
-- -----------------------------------------------------------------------------

-- Fix hidden BOM characters in the primary table (if applicable)
-- Note: Replace `ï»¿State` with whatever hidden header was found in DESCRIBE
ALTER TABLE swiggy_data CHANGE COLUMN `ï»¿State` `State` TEXT;

-- Convert text-based 'Order Date' into a proper MySQL DATE format
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE swiggy_data ADD COLUMN formatted_date DATE;

-- Update with backticks to handle spaces in 'Order Date'
UPDATE swiggy_data 
SET formatted_date = STR_TO_DATE(`Order Date`, '%d-%m-%Y');

-- -----------------------------------------------------------------------------
-- 3. DATA VALIDATION (Checking for Nulls/Blanks)
-- -----------------------------------------------------------------------------
SELECT 
    SUM(CASE WHEN `Order Date` IS NULL OR `Order Date` = '' THEN 1 ELSE 0 END) AS missing_date,
    SUM(CASE WHEN `Restaurant Name` IS NULL OR `Restaurant Name` = '' THEN 1 ELSE 0 END) AS missing_restaurant,
    SUM(CASE WHEN `City` IS NULL OR `City` = '' THEN 1 ELSE 0 END) AS missing_city,
    SUM(CASE WHEN `Price (INR)` IS NULL THEN 1 ELSE 0 END) AS missing_price,
    SUM(CASE WHEN `Rating` IS NULL THEN 1 ELSE 0 END) AS missing_rating
FROM swiggy_data;

-- -----------------------------------------------------------------------------
-- 4. STAR SCHEMA ARCHITECTURE (Dimension Tables)
-- -----------------------------------------------------------------------------

-- A. Location Dimension
CREATE TABLE dim_location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    state VARCHAR(100),
    city VARCHAR(100),
    location VARCHAR(200)
);
INSERT INTO dim_location (state, city, location)
SELECT DISTINCT `State`, `City`, `Location` FROM swiggy_data;

-- B. Restaurant Dimension
CREATE TABLE dim_restaurant (
    restaurant_id INT AUTO_INCREMENT PRIMARY KEY,
    restaurant_name VARCHAR(255)
);
INSERT INTO dim_restaurant (restaurant_name)
SELECT DISTINCT `Restaurant Name` FROM swiggy_data;

-- C. Category Dimension
CREATE TABLE dim_category (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(255)
);
INSERT INTO dim_category (category_name)
SELECT DISTINCT `Category` FROM swiggy_data;

-- D. Dish Dimension
CREATE TABLE dim_dish (
    dish_id INT AUTO_INCREMENT PRIMARY KEY,
    dish_name VARCHAR(255)
);
INSERT INTO dim_dish (dish_name)
SELECT DISTINCT `Dish Name` FROM swiggy_data;

-- -----------------------------------------------------------------------------
-- 5. FACT TABLE LOADING
-- -----------------------------------------------------------------------------
CREATE TABLE fact_swiggy_orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    location_id INT,
    restaurant_id INT,
    category_id INT,
    dish_id INT,
    price_inr DOUBLE,
    rating DOUBLE,
    rating_count INT,
    order_date DATE,
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id),
    FOREIGN KEY (restaurant_id) REFERENCES dim_restaurant(restaurant_id),
    FOREIGN KEY (category_id) REFERENCES dim_category(category_id),
    FOREIGN KEY (dish_id) REFERENCES dim_dish(dish_id)
);

INSERT INTO fact_swiggy_orders (location_id, restaurant_id, category_id, dish_id, price_inr, rating, rating_count, order_date)
SELECT 
    l.location_id, r.restaurant_id, c.category_id, d.dish_id, 
    s.`Price (INR)`, s.Rating, s.`Rating Count`, s.formatted_date
FROM swiggy_data s
JOIN dim_location l ON s.State = l.state AND s.City = l.city AND s.Location = l.location
JOIN dim_restaurant r ON s.`Restaurant Name` = r.restaurant_name
JOIN dim_category c ON s.Category = c.category_name
JOIN dim_dish d ON s.`Dish Name` = d.dish_name;

-- -----------------------------------------------------------------------------
-- 6. BUSINESS INSIGHTS & ANALYTICS
-- -----------------------------------------------------------------------------

-- A. Basic KPIs
SELECT 
    COUNT(order_id) AS total_orders,
    CONCAT('INR ', FORMAT(SUM(price_inr)/1000000, 2), 'M') AS total_revenue_million,
    ROUND(AVG(price_inr), 2) AS avg_dish_price,
    ROUND(AVG(rating), 2) AS avg_rating
FROM fact_swiggy_orders;

-- B. Monthly Order Trend
SELECT 
    MONTHNAME(order_date) AS month_name, 
    COUNT(order_id) AS total_orders
FROM fact_swiggy_orders
GROUP BY month_name, MONTH(order_date)
ORDER BY MONTH(order_date);

-- C. Top 10 Cities by Order Volume
SELECT 
    l.city, 
    COUNT(f.order_id) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_location l ON f.location_id = l.location_id
GROUP BY l.city
ORDER BY total_orders DESC
LIMIT 10;

-- D. Customer Spending Buckets
SELECT 
    CASE 
        WHEN price_inr < 100 THEN 'Under 100'
        WHEN price_inr BETWEEN 100 AND 199 THEN '100-199'
        WHEN price_inr BETWEEN 200 AND 299 THEN '200-299'
        WHEN price_inr BETWEEN 300 AND 499 THEN '300-499'
        ELSE '500+'
    END AS spending_bucket,
    COUNT(*) AS total_orders
FROM fact_swiggy_orders
GROUP BY spending_bucket
ORDER BY FIELD(spending_bucket, 'Under 100', '100-199', '200-299', '300-499', '500+');

-- E. Cuisine / Category Performance (Top 10)
SELECT 
    c.category_name, 
    COUNT(f.order_id) AS total_orders,
    ROUND(AVG(f.rating), 2) AS avg_rating
FROM fact_swiggy_orders f
JOIN dim_category c ON f.category_id = c.category_id
GROUP BY c.category_name
ORDER BY total_orders DESC
LIMIT 10;

-- F. Rating Distribution (Star Levels)
SELECT 
    FLOOR(rating) AS rating_star, 
    COUNT(*) AS total_dishes
FROM fact_swiggy_orders
WHERE rating IS NOT NULL
GROUP BY rating_star
ORDER BY rating_star DESC;

-- G. Top 5 Most Popular Dishes
SELECT 
    d.dish_name, 
    COUNT(f.order_id) AS order_count
FROM fact_swiggy_orders f
JOIN dim_dish d ON f.dish_id = d.dish_id
GROUP BY d.dish_name
ORDER BY order_count DESC
LIMIT 5;

-- H. Top 10 Restaurants by Order Volume
SELECT 
    r.restaurant_name, 
    COUNT(f.order_id) AS total_orders
FROM fact_swiggy_orders f
JOIN dim_restaurant r ON f.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_name
ORDER BY total_orders DESC
LIMIT 10;

-- I. Quarterly Order Trends
SELECT 
    QUARTER(order_date) AS quarter, 
    COUNT(order_id) AS total_orders
FROM fact_swiggy_orders
GROUP BY quarter
ORDER BY quarter;

-- J. Day-of-Week Order Patterns (Busiest Days)
SELECT 
    DAYNAME(order_date) AS day_of_week, 
    COUNT(order_id) AS total_orders
FROM fact_swiggy_orders
GROUP BY day_of_week, DAYOFWEEK(order_date)
ORDER BY DAYOFWEEK(order_date);

/* ============================ END OF SCRIPT ================================ */