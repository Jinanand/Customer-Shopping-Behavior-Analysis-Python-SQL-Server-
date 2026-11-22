# Customer Shopping Behavior Analysis (Python + SQL Server)

An end-to-end analysis of customer shopping data: clean and prepare the data in Python, load it into SQL Server, and answer business questions with SQL.

> **Note on the data:** The dataset was generated with AI. It is not real customer data. The numbers below show how the analysis works. They should not be treated as real market facts.

---

## 1. Project Overview

- **Goal:** Understand who buys, what they buy, how discounts and subscriptions affect spending, and where the business can improve.
- **Dataset size:** 15,000 rows, 18 columns, one row per customer (Customer ID is unique).
- **Total revenue in the data:** $899,529
- **Average purchase:** about $60

### Columns in the raw data
Customer ID, Age, Gender, Item Purchased, Category, Purchase Amount (USD), Location, Size, Color, Season, Review Rating, Subscription Status, Shipping Type, Discount Applied, Promo Code Used, Previous Purchases, Payment Method, Frequency of Purchases

---

## 2. Workflow

1. **Data creation:** Dataset generated using AI.
2. **Python (Jupyter Notebook):** Cleaned the data and created new features (see Section 3 for details).
3. **Load to SQL Server:** Pushed the cleaned data straight from Python into a local MSSQL table: `dbo.customer_shopping` (using SQLAlchemy and pyodbc)
4. **SQL analysis:** Wrote queries to answer 9 business questions.
5. **Reporting:** Saved results in `SQL_Analysis.xlsx` (one sheet per question, with the query and the result).

**Tools:** Python (pandas), Jupyter Notebook, Microsoft SQL Server, SQL (CTEs, window functions, CASE), Excel

---

## 3. Data Cleaning and Feature Engineering (Python)

Notebook: [`data_cleaning.ipynb`](data_cleaning.ipynb). It takes the raw CSV (15,000 rows, 18 columns) and produces the cleaned table (15,000 rows, 18 columns).

| Step | What was done | Why |
|------|---------------|-----|
| Rename columns | Lower case, underscores, removed brackets (e.g. `Purchase Amount (USD)` becomes `purchase_amount`) | Easy to write in SQL, no quotes or brackets needed |
| Missing ratings | 149 missing `review_rating` values filled with the **median rating of the product category** | Keeps all rows. A category median is fairer than one number for every product |
| Drop column | Removed `promo_code_used` | It had the same value as `discount_applied` in every row, so it added nothing |
| Frequency to days | `frequency_of_purchases` changed from text to number of days: Weekly 7, Bi-Weekly / Fortnightly 14, Monthly 30, Quarterly / Every 3 Months 90, Annually 365 | Text cannot be sorted or averaged, numbers can |
| New feature | `age_group` created from age quartiles: Young Adult (18-31), Adult (32-44), Middle Aged (45-57), Senior (58-70) | Gives four groups of similar size for revenue analysis |
| Checks | No duplicate customer IDs, no missing values after cleaning | Confirms the table is safe to analyse |

**Notes on the cleaning choices**
- "Quarterly" and "Every 3 Months" mean the same thing, and so do "Bi-Weekly" and "Fortnightly". The raw data lists them separately, which is a quirk of the AI-generated data. They are merged after the day conversion.
- Filling missing ratings with the median makes those rows look average. This affects only about 1% of rows.

**Load to SQL Server**
```python
from sqlalchemy import create_engine
import urllib

params = urllib.parse.quote_plus(
    'DRIVER={ODBC Driver 17 for SQL Server};SERVER=localhost;DATABASE=YourDatabaseName;Trusted_Connection=yes;'
)
engine = create_engine(f'mssql+pyodbc:///?odbc_connect={params}')
df.to_sql('customer_shopping', engine, schema='dbo', if_exists='replace', index=False, chunksize=1000)
```

### Final table: `dbo.customer_shopping`
`customer_id, age, gender, item_purchased, category, purchase_amount, location, size, color, season, review_rating, subscription_status, shipping_type, discount_applied, previous_purchases, payment_method, frequency_of_purchases, age_group`

---

## 4. Business Questions and Results

| # | Question | Result |
|---|----------|--------|
| 1 | Revenue by gender | Male $611,471 vs Female $288,058 |
| 2 | Discount users who spent above average | Large group of customers, many at the $97-$100 mark |
| 3 | Top 5 products by average rating | T-shirt 3.81, Dress 3.81, Scarf 3.80, Hat 3.79, Backpack 3.78 |
| 4 | Subscribers vs non-subscribers | Avg spend $59.76 vs $60.05 |
| 5 | Top 5 products by discount usage | Jeans 47.8%, Scarf 46.6%, Shorts 46.5%, Gloves 45.8%, T-shirt 45.6% |
| 6 | Customer segments (New / Returning / Loyal) | Returning 1,625, Loyal 13,375, New 0 |
| 7 | Top 3 products in each category | Sunglasses, Blouse, Sandals, Coat lead their categories |
| 8 | Do repeat buyers (>5 purchases) subscribe? | Only 27.1% subscribe, 72.9% do not |
| 9 | Revenue by age group | Young Adult 26.3%, Middle Aged 25.3%, Adult 24.2%, Senior 24.2% |

---

## 5. Key Findings and Business Summary

### 4.1 Subscription program is not working
- Only **27%** of customers are subscribers.
- Repeat buyers (more than 5 previous purchases) subscribe at almost the same rate: **27.1%**. Loyal customers are not choosing to subscribe.
- Subscribers spend the same as non-subscribers: **$59.76 vs $60.05** per order.
- Subscribers do not buy more often either. The subscription rate is flat across every purchase frequency (weekly buyers 28%, annual buyers 27%).
- Subscribers also have similar previous purchase counts and similar review ratings.
- **Meaning:** The subscription gives customers no strong reason to join, and it does not change their behaviour. In this data, every subscriber also has a discount applied, so the business may be giving up margin without getting extra spend in return.

### 4.2 Discounts do not increase spending
- 43% of all orders use a discount.
- Discounted orders average about **$60.20**; non-discounted orders average about **$59.79**. There is almost no difference.
- Products with the highest discount usage (Jeans, Scarf, Shorts, Gloves, T-shirt) sit between 45% and 48%. This is only slightly above the overall rate, so no product is truly "discount dependent".
- **Meaning:** Blanket discounts are reducing revenue per sale without pushing customers to spend more.

### 4.3 Male customers bring more revenue because there are more of them
- Males generate **68%** of revenue ($611K vs $288K).
- But males are also 68% of customers. Average spend per order is nearly the same (Male about $60.07, Female about $59.76).
- **Meaning:** Women do not spend less. The business is simply reaching fewer women. This is a customer acquisition gap, not a spending gap.

### 4.4 Revenue is evenly spread across age groups
- All four age groups contribute 24% to 26% of revenue.
- **Meaning:** No single age group is carrying the business. Age-based targeting is unlikely to give a big win on its own.

### 4.5 Products
- Top sellers: **Blouse** (674), **Sunglasses** (660), **Shirt** (658), **Belt** (651), **Jewelry** (641), **Sandals** (626).
- Top-rated products (T-shirt, Dress, Scarf, Hat, Backpack) differ by only 0.03 rating points. The differences are too small to say one product is truly better.
- Average rating across all products is about 3.75 out of 5, so there is room to improve product quality overall.

### 4.6 Customer segmentation needs a redesign
- **89%** of customers (13,375 of 15,000) fall in the "Loyal" group, and there are **no "New" customers** in the data (the lowest previous purchase count is 1).
- **Meaning:** The segment rules (0 / 1-5 / 6+) do not separate customers in a useful way for this dataset. Thresholds should be set from the real data spread (for example, quartiles of previous purchases).

---

## 6. Recommendations

1. **Redesign the subscription.** Add benefits people actually value (free shipping, early access, member-only products) and test it before a full rollout.
2. **Stop blanket discounts.** Use targeted offers (for example, for customers who have not purchased for a long time) and run an A/B test to confirm the offer increases spend.
3. **Attract more female customers.** Their spend per order is already equal to male customers.
4. **Focus on the best-selling products** in each category for promotions, and review low-rated items for quality issues.
5. **Rebuild customer segments** using data-driven thresholds so marketing can target groups that really differ.

---

## 7. Limitations

- Data is AI-generated, so patterns (such as "subscribers behave the same as non-subscribers") may come from how the data was created, not from real behaviour.
- The data has no dates, so trends over time, repeat purchase timing, and revenue growth cannot be analysed.
- Each customer appears once, so "customers" and "orders" are treated as the same thing.
- No profit or cost data, so the real cost of discounts cannot be measured.
- About 1% of review ratings were filled with category medians, so rating-based results are slightly smoothed.
- Findings show averages and shares. No statistical tests were run, so small differences (like $59.76 vs $60.05) should be read as "no clear difference", not as proof.

---

## 8. SQL Queries

<details>
<summary>Click to view all queries</summary>

**1. Revenue by gender**
```sql
SELECT gender, SUM(purchase_amount) AS total_revenue
FROM dbo.customer_shopping
GROUP BY gender
ORDER BY total_revenue DESC;
```

**2. Discount users who spent more than the average purchase**
```sql
SELECT customer_id, purchase_amount, discount_applied
FROM dbo.customer_shopping
WHERE discount_applied = 'Yes'
  AND purchase_amount > (SELECT AVG(purchase_amount) FROM dbo.customer_shopping)
ORDER BY purchase_amount DESC;
```
*(Reconstructed from the sheet title. Replace with your exact query if different.)*

**3. Top 5 products by average rating**
```sql
SELECT TOP 5 item_purchased, ROUND(AVG(review_rating),2) AS avg_rating
FROM dbo.customer_shopping
GROUP BY item_purchased
ORDER BY avg_rating DESC;
```

**4. Subscribers vs non-subscribers**
```sql
SELECT subscription_status,
       ROUND(AVG(CAST(purchase_amount AS FLOAT)),2) AS avg_spend,
       SUM(purchase_amount) AS total_revenue,
       COUNT(*) AS total_orders
FROM dbo.customer_shopping
GROUP BY subscription_status;
```

**5. Top 5 products by discount percentage**
```sql
SELECT TOP 5 item_purchased,
       ROUND(100.0 * SUM(CASE WHEN discount_applied = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS discount_percentage
FROM dbo.customer_shopping
GROUP BY item_purchased
ORDER BY discount_percentage DESC;
```

**6. Customer segments**
```sql
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
```

**7. Top 3 products in each category**
```sql
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
```

**8. Do repeat buyers subscribe?**
```sql
SELECT subscription_status,
       COUNT(*) AS customer_count,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM dbo.customer_shopping
WHERE previous_purchases > 5
GROUP BY subscription_status;
```

**9. Revenue by age group**
```sql
SELECT age_group,
       SUM(purchase_amount) AS total_revenue,
       ROUND(100.0 * SUM(purchase_amount) / SUM(SUM(purchase_amount)) OVER (), 2) AS revenue_contribution_percent
FROM dbo.customer_shopping
GROUP BY age_group
ORDER BY total_revenue DESC;
```

</details>

---

## 9. Repository Structure

```
├── customer_shopping_behavior.csv   # Raw AI-generated dataset
├── data_cleaning.ipynb              # Python cleaning + feature work + load to SQL Server
├── customer_shopping_cleaned.csv    # Cleaned data (output of the notebook; optional to upload)
├── SQL_Analysis.xlsx                # Query results (one sheet per question)
├── queries.sql                      # All SQL queries
└── README.md
```

## 10. How to Run

1. Put `customer_shopping_behavior.csv` in the same folder as the notebook.
2. Install the packages: `pip install pandas openpyxl sqlalchemy pyodbc`
3. Open `data_cleaning.ipynb` and run all cells. Change `SERVER` and `DATABASE` in the last cell to match your local SQL Server.
4. Run the queries in SQL Server Management Studio against `dbo.customer_shopping`.
