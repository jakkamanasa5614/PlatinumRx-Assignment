-- Q1: Revenue from each sales channel in a given year

SELECT sales_channel,
       SUM(amount) AS revenue
FROM clinic_sales
WHERE EXTRACT(YEAR FROM datetime) = 2021
GROUP BY sales_channel;


-- Q2: Top 10 most valuable customers for a given year

SELECT uid,
       SUM(amount) AS total_spent
FROM clinic_sales
WHERE EXTRACT(YEAR FROM datetime) = 2021
GROUP BY uid
ORDER BY total_spent DESC
LIMIT 10;


-- Q3: Month-wise revenue, expense, profit, status

WITH revenue AS (
    SELECT EXTRACT(MONTH FROM datetime) AS month,
           SUM(amount) AS total_revenue
    FROM clinic_sales
    WHERE EXTRACT(YEAR FROM datetime) = 2021
    GROUP BY month
),
expenses_cte AS (
    SELECT EXTRACT(MONTH FROM datetime) AS month,
           SUM(amount) AS total_expense
    FROM expenses
    WHERE EXTRACT(YEAR FROM datetime) = 2021
    GROUP BY month
)
SELECT r.month,
       r.total_revenue,
       e.total_expense,
       (r.total_revenue - e.total_expense) AS profit,
       CASE 
           WHEN (r.total_revenue - e.total_expense) > 0 THEN 'Profitable'
           ELSE 'Not Profitable'
       END AS status
FROM revenue r
JOIN expenses_cte e ON r.month = e.month;


-- Q4: Most profitable clinic per city (example month = May)

WITH clinic_profit AS (
    SELECT c.city, cs.cid,
           SUM(cs.amount) - COALESCE(SUM(e.amount),0) AS profit
    FROM clinic_sales cs
    JOIN clinics c ON cs.cid = c.cid
    LEFT JOIN expenses e ON cs.cid = e.cid
        AND EXTRACT(MONTH FROM cs.datetime) = EXTRACT(MONTH FROM e.datetime)
    WHERE EXTRACT(MONTH FROM cs.datetime) = 5
    GROUP BY c.city, cs.cid
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY city ORDER BY profit DESC) AS rnk
    FROM clinic_profit
)
SELECT *
FROM ranked
WHERE rnk = 1;


-- Q5: Second least profitable clinic per state (example month = May)

WITH clinic_profit AS (
    SELECT c.state, cs.cid,
           SUM(cs.amount) - COALESCE(SUM(e.amount),0) AS profit
    FROM clinic_sales cs
    JOIN clinics c ON cs.cid = c.cid
    LEFT JOIN expenses e ON cs.cid = e.cid
        AND EXTRACT(MONTH FROM cs.datetime) = EXTRACT(MONTH FROM e.datetime)
    WHERE EXTRACT(MONTH FROM cs.datetime) = 5
    GROUP BY c.state, cs.cid
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY state ORDER BY profit ASC) AS rnk
    FROM clinic_profit
)
SELECT *
FROM ranked
WHERE rnk = 2;