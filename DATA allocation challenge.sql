---Data Allocation Challenge:

--To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

--Option 1: data is allocated based off the amount of money at the end of the previous month
--Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
--Option 3: data is updated real-time
--For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

--running customer balance column that includes the impact each transaction
--customer balance at the end of each month
--minimum, average and maximum values of the running balance for each customer
--Using all of the data available - how much data would have been required for each option on a monthly basis?
select * from customer_transactions order by customer_id;
with month_cte as
(
select customer_id,month(txn_date) as month , sum(case
when txn_type = 'deposit' then txn_amount else -txn_amount end ) as balance from customer_transactions  group by month(txn_date),customer_id )
select * from month_cte order by customer_id;


WITH AmountCte AS(
   SELECT 
   	customer_id,
    txn_date ,
   	SUM(CASE 
   	WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS amount
   FROM customer_transactions
   GROUP BY customer_id, txn_date

)
select customer_id, txn_date, sum(amount) over (partition by customer_id order by txn_date rows between unbounded preceding and current row) as closing_balance
from AmountCte group by customer_id,txn_date,amount order by customer_id;

---minimum, average and maximum values of the running balance 
WITH RunningTotalCte AS(
SELECT
   customer_id,
   txn_date,
   SUM(CASE 
   		WHEN txn_type = 'deposit' THEN txn_amount 
   		WHEN txn_type = 'purchase' THEN -txn_amount 
   		WHEN txn_type = 'withdrawal' THEN -txn_amount ELSE 0 END)
   		OVER(PARTITION BY customer_id ORDER BY txn_date 
   			 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total
FROM customer_transactions
)
SELECT 
   customer_id, 
   MIN(running_total) AS min_running_total,
   AVG(running_total) AS avg_running_total,
   MAX(running_total) AS max_running_total
FROM RunningTotalCte
GROUP BY customer_id; 


WITH AmountCte AS (
   SELECT 
   	customer_id,
   	MONTH(txn_date) AS month,
   	CASE
   		WHEN txn_type = 'deposit' THEN txn_amount
   		WHEN txn_type = 'purchase' THEN -txn_amount
   		WHEN txn_type = 'withdrawal' THEN -txn_amount END as amount
   FROM customer_transactions
   
),
RunningBalance AS (
   SELECT 
   	*,
   	SUM(amount) OVER (PARTITION BY customer_id, month ORDER BY customer_id, month
   		   ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
   FROM AmountCte
),
MonthlyAllocation AS(
   SELECT 
   	*,
   	LAG(running_balance, 1) OVER(PARTITION BY customer_id 
   								 ORDER BY customer_id, month) AS monthly_allocation
   FROM RunningBalance
)
SELECT
   month,
   SUM(monthly_allocation) AS total_allocation
FROM MonthlyAllocation
GROUP BY month
ORDER BY month;