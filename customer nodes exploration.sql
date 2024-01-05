---How many unique nodes are there on the Data Bank system?
select count(distinct node_id) from customer_nodes;

---What is the number of nodes per region?
select region_id , count(node_id) 
as nodes_per_region from customer_nodes 
group by region_id order by region_id;

---How many customers are allocated to each region?
select region_id , 
count(distinct customer_id) as customer_per_region 
from customer_nodes group by region_id order by region_id;

---How many days on average are customers reallocated to a different node?
SELECT 
AVG(CAST(DATEDIFF(day, start_date, end_date) as int)) AS avg_reallocation_days
FROM customer_nodes
WHERE end_date != '9999-12-31';

---What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
-- Calculate the median, 80th percentile, and 95th percentile for each region
WITH dayscte AS (
    SELECT 
        c.region_id,
        DATEDIFF(day, start_date, end_date) AS reallocation_days
    FROM customer_nodes AS c
    WHERE end_date != '9999-12-31'
)
, percentiles AS (
    SELECT
        region_id,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reallocation_days) OVER (PARTITION BY region_id) AS median,
        PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY reallocation_days) OVER (PARTITION BY region_id) AS percentile_80,
        PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY reallocation_days) OVER (PARTITION BY region_id) AS percentile_95
    FROM dayscte
)
SELECT
    d.region_id,
    p.median,
    p.percentile_80,
    p.percentile_95
FROM dayscte d
INNER JOIN percentiles p ON d.region_id = p.region_id
GROUP BY d.region_id, p.median, p.percentile_80, p.percentile_95;
