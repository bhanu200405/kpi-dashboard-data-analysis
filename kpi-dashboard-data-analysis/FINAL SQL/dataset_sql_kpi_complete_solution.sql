-- =========================================================
-- Flipkart Dataset: Complete SQL KPI Solution
-- Dataset period: 2023-01-01 to 2024-12-30
-- SQL dialect: MySQL 8+
-- Table name used below: flipkart
-- =========================================================

-- ---------------------------------------------------------
-- OPTIONAL: Create a clean view (ignores unwanted unnamed columns)
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW flipkart_clean AS
SELECT
    Order_ID,
    Customer_ID,
    Product_ID,
    Category,
    Sub_Category,
    Brand,
    Quantity,
    Unit_Price,
    Discount,
    Sales,
    Profit,
    Rating,
    CAST(Order_Date AS DATE) AS Order_Date,
    Region,
    Payment_Mode
FROM flipkart;

-- Quick check
SELECT MIN(Order_Date) AS min_date, MAX(Order_Date) AS max_date
FROM flipkart_clean;

-- =========================================================
-- KPI 1. Top 10 products by total sales across all categories
-- =========================================================
SELECT
    Product_ID,
    Brand,
    Category,
    Sub_Category,
    ROUND(SUM(Sales), 2) AS total_sales
FROM flipkart_clean
GROUP BY Product_ID, Brand, Category, Sub_Category
ORDER BY total_sales DESC
LIMIT 10;

-- =========================================================
-- KPI 2. Monthly revenue trend for 2023-2024
-- =========================================================
SELECT
    YEAR(Order_Date) AS order_year,
    MONTH(Order_Date) AS order_month,
    DATE_FORMAT(Order_Date, '%Y-%m') AS year_month,
    ROUND(SUM(Sales), 2) AS monthly_sales
FROM flipkart_clean
WHERE Order_Date >= '2023-01-01'
  AND Order_Date <  '2025-01-01'
GROUP BY YEAR(Order_Date), MONTH(Order_Date), DATE_FORMAT(Order_Date, '%Y-%m')
ORDER BY order_year, order_month;

-- =========================================================
-- KPI 3. Category profit analysis
-- Compute total profit and profit margin for each category
-- Profit Margin % = (SUM(Profit) / SUM(Sales)) * 100
-- =========================================================
SELECT
    Category,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(SUM(Profit), 2) AS total_profit,
    ROUND((SUM(Profit) / NULLIF(SUM(Sales), 0)) * 100, 2) AS profit_margin_pct
FROM flipkart_clean
GROUP BY Category
ORDER BY total_profit DESC;

-- =========================================================
-- KPI 4. Customer repeat purchases
-- Customers with more than 3 orders during the 2-year period
-- =========================================================
SELECT
    Customer_ID,
    COUNT(DISTINCT Order_ID) AS total_orders,
    ROUND(SUM(Sales), 2) AS total_revenue
FROM flipkart_clean
WHERE Order_Date >= '2023-01-01'
  AND Order_Date <  '2025-01-01'
GROUP BY Customer_ID
HAVING COUNT(DISTINCT Order_ID) > 3
ORDER BY total_orders DESC, total_revenue DESC;

-- =========================================================
-- KPI 5. High discount products
-- Products with discount > 15% and their total sales
-- Note: Discount is stored as decimal (e.g. 0.20 = 20%)
-- =========================================================
SELECT
    Product_ID,
    Brand,
    Category,
    ROUND(AVG(Discount) * 100, 2) AS avg_discount_pct,
    ROUND(SUM(Sales), 2) AS total_sales
FROM flipkart_clean
WHERE Discount > 0.15
GROUP BY Product_ID, Brand, Category
ORDER BY total_sales DESC;

-- =========================================================
-- KPI 6. Region-wise sales
-- Show total sales and average profit for each region
-- =========================================================
SELECT
    Region,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(AVG(Profit), 2) AS avg_profit,
    ROUND(SUM(Profit), 2) AS total_profit
FROM flipkart_clean
GROUP BY Region
ORDER BY total_sales DESC;

-- =========================================================
-- KPI 7. Top 5 brands by revenue in each category
-- =========================================================
WITH brand_revenue AS (
    SELECT
        Category,
        Brand,
        ROUND(SUM(Sales), 2) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY Category
            ORDER BY SUM(Sales) DESC
        ) AS rn
    FROM flipkart_clean
    GROUP BY Category, Brand
)
SELECT
    Category,
    Brand,
    total_revenue
FROM brand_revenue
WHERE rn <= 5
ORDER BY Category, total_revenue DESC;

-- =========================================================
-- KPI 8. Payment mode analysis
-- Determine which payment mode contributed most to total sales
-- =========================================================
SELECT
    Payment_Mode,
    ROUND(SUM(Sales), 2) AS total_sales,
    ROUND(100 * SUM(Sales) / SUM(SUM(Sales)) OVER (), 2) AS sales_contribution_pct
FROM flipkart_clean
GROUP BY Payment_Mode
ORDER BY total_sales DESC;

-- =========================================================
-- KPI 9. Orders / products with average rating < 3
-- Retrieve products where average customer rating is less than 3
-- =========================================================
SELECT
    Product_ID,
    Brand,
    Category,
    ROUND(AVG(Rating), 2) AS avg_rating,
    COUNT(*) AS order_count,
    ROUND(SUM(Sales), 2) AS total_sales
FROM flipkart_clean
GROUP BY Product_ID, Brand, Category
HAVING AVG(Rating) < 3
ORDER BY avg_rating ASC, total_sales DESC;

-- =========================================================
-- KPI 10. Year-over-year monthly sales comparison (2023 vs 2024)
-- =========================================================
SELECT
    MONTH(Order_Date) AS month_num,
    MONTHNAME(MAKEDATE(2023, 1) + INTERVAL MONTH(Order_Date) - 1 MONTH) AS month_name,
    ROUND(SUM(CASE WHEN YEAR(Order_Date) = 2023 THEN Sales ELSE 0 END), 2) AS sales_2023,
    ROUND(SUM(CASE WHEN YEAR(Order_Date) = 2024 THEN Sales ELSE 0 END), 2) AS sales_2024,
    ROUND(
        (
            SUM(CASE WHEN YEAR(Order_Date) = 2024 THEN Sales ELSE 0 END) -
            SUM(CASE WHEN YEAR(Order_Date) = 2023 THEN Sales ELSE 0 END)
        ) / NULLIF(SUM(CASE WHEN YEAR(Order_Date) = 2023 THEN Sales ELSE 0 END), 0) * 100,
        2
    ) AS yoy_growth_pct
FROM flipkart_clean
WHERE Order_Date >= '2023-01-01'
  AND Order_Date <  '2025-01-01'
GROUP BY MONTH(Order_Date)
ORDER BY month_num;

-- =========================================================
-- OPTIONAL BONUS CHECKS FOR SUBMISSION QUALITY
-- =========================================================

-- Distinct counts snapshot
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT Order_ID) AS distinct_orders,
    COUNT(DISTINCT Customer_ID) AS distinct_customers,
    COUNT(DISTINCT Product_ID) AS distinct_products,
    COUNT(DISTINCT Brand) AS distinct_brands
FROM flipkart_clean;

-- Null check summary
SELECT
    SUM(CASE WHEN Order_ID IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN Customer_ID IS NULL THEN 1 ELSE 0 END) AS null_customer_id,
    SUM(CASE WHEN Product_ID IS NULL THEN 1 ELSE 0 END) AS null_product_id,
    SUM(CASE WHEN Sales IS NULL THEN 1 ELSE 0 END) AS null_sales,
    SUM(CASE WHEN Profit IS NULL THEN 1 ELSE 0 END) AS null_profit,
    SUM(CASE WHEN Order_Date IS NULL THEN 1 ELSE 0 END) AS null_order_date
FROM flipkart_clean;
