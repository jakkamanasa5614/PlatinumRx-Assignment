-- Q1: For every user, get the last booked room

SELECT b.user_id, b.room_no
FROM bookings b
JOIN (
    SELECT user_id, MAX(booking_date) AS last_booking
    FROM bookings
    GROUP BY user_id
) lb
ON b.user_id = lb.user_id AND b.booking_date = lb.last_booking;


-- Q2: Get booking_id and total billing amount of every booking created in November 2021

SELECT bc.booking_id,
       SUM(bc.item_quantity * i.item_rate) AS total_bill
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id
WHERE EXTRACT(MONTH FROM bc.bill_date) = 11
  AND EXTRACT(YEAR FROM bc.bill_date) = 2021
GROUP BY bc.booking_id;


-- Q3: Get bill_id and bill amount > 1000 in October 2021

SELECT bc.bill_id,
       SUM(bc.item_quantity * i.item_rate) AS bill_amount
FROM booking_commercials bc
JOIN items i ON bc.item_id = i.item_id
WHERE EXTRACT(MONTH FROM bc.bill_date) = 10
  AND EXTRACT(YEAR FROM bc.bill_date) = 2021
GROUP BY bc.bill_id
HAVING SUM(bc.item_quantity * i.item_rate) > 1000;


-- Q4: Most and least ordered item each month of 2021

WITH item_orders AS (
    SELECT 
        EXTRACT(MONTH FROM bc.bill_date) AS month,
        bc.item_id,
        SUM(bc.item_quantity) AS total_qty
    FROM booking_commercials bc
    WHERE EXTRACT(YEAR FROM bc.bill_date) = 2021
    GROUP BY month, bc.item_id
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY month ORDER BY total_qty DESC) AS rnk_max,
           RANK() OVER (PARTITION BY month ORDER BY total_qty ASC) AS rnk_min
    FROM item_orders
)
SELECT month, item_id, total_qty,
       CASE 
           WHEN rnk_max = 1 THEN 'Most Ordered'
           WHEN rnk_min = 1 THEN 'Least Ordered'
       END AS category
FROM ranked
WHERE rnk_max = 1 OR rnk_min = 1;


-- Q5: Customers with second highest bill value each month of 2021

WITH monthly_bills AS (
    SELECT 
        EXTRACT(MONTH FROM bc.bill_date) AS month,
        b.user_id,
        bc.bill_id,
        SUM(bc.item_quantity * i.item_rate) AS bill_amount
    FROM booking_commercials bc
    JOIN bookings b ON bc.booking_id = b.booking_id
    JOIN items i ON bc.item_id = i.item_id
    WHERE EXTRACT(YEAR FROM bc.bill_date) = 2021
    GROUP BY month, b.user_id, bc.bill_id
),
ranked AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY month ORDER BY bill_amount DESC) AS rnk
    FROM monthly_bills
)
SELECT *
FROM ranked
WHERE rnk = 2;