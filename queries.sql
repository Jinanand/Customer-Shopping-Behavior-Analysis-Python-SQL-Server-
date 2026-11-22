-- Customer shopping analysis: table dbo.customer_shopping (SQL Server)

-- 1. Revenue by gender
SELECT gender, SUM(purchase_amount) AS total_revenue
FROM dbo.customer_shopping
GROUP BY gender
ORDER BY total_revenue DESC;

-- 2. Discount users who spent more than the average purchase
SELECT customer_id, purchase_amount, discount_applied
FROM dbo.customer_shopping
WHERE discount_applied = 'Yes'
  AND purchase_amount > (SELECT AVG(purchase_amount) FROM dbo.customer_shopping)
ORDER BY purchase_amount DESC;

-- 3. Top 5 products by average rating
SELECT TOP 5 item_purchased, ROUND(AVG(review_rating),2) AS avg_rating
FROM dbo.customer_shopping
GROUP BY item_purchased
ORDER BY avg_rating DESC;

-- 4. Subscribers vs non-subscribers
SELECT subscription_status,
       ROUND(AVG(CAST(purchase_amount AS FLOAT)),2) AS avg_spend,
       SUM(purchase_amount) AS total_revenue,
       COUNT(*) AS total_orders
FROM dbo.customer_shopping
GROUP BY subscription_status;

-- 5. Top 5 products by discount percentage
SELECT TOP 5 item_purchased,
       ROUND(100.0 * SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS discount_percentage
FROM dbo.customer_shopping
GROUP BY item_purchased
ORDER BY discount_percentage DESC;

-- 6. Customer segments
SELECT CASE
           WHEN previous_purchases = 0 THEN 'New'
           WHEN previous_purchases BETWEEN 1 AND 5 THEN 'Returning'
           ELSE 'Loyal'
       END AS customer_segment,
       COUNT(*) AS customer_count
FROM dbo.customer_shopping
GROUP BY CASE
           WHEN previous_purchases = 0 THEN 'New'
           WHEN previous_purchases BETWEEN 1 AND 5 THEN 'Returning'
           ELSE 'Loyal'
         END;

-- 7. Top 3 products in each category
WITH ProductSales AS (
    SELECT category, item_purchased, COUNT(*) AS purchase_count,
           ROW_NUMBER() OVER (PARTITION BY category ORDER BY COUNT(*) DESC) AS rn
    FROM dbo.customer_shopping
    GROUP BY category, item_purchased
)
SELECT category, item_purchased, purchase_count
FROM ProductSales
WHERE rn <= 3
ORDER BY category, purchase_count DESC;

-- 8. Do repeat buyers subscribe?
SELECT subscription_status,
       COUNT(*) AS customer_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM dbo.customer_shopping
WHERE previous_purchases > 5
GROUP BY subscription_status;

-- 9. Revenue by age group
SELECT age_group,
       SUM(purchase_amount) AS total_revenue,
       ROUND(100.0 * SUM(purchase_amount) / SUM(SUM(purchase_amount)) OVER (), 2) AS revenue_contribution_percent
FROM dbo.customer_shopping
GROUP BY age_group
ORDER BY total_revenue DESC;

