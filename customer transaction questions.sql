--Customer Transactions

---What is the unique count and total amount for each transaction type?
select distinct txn_type,count(txn_type) as count_of_txn_type, 
sum(txn_amount) as total_amount_txn_type 
from customer_transactions group by txn_type;


---What is the average total historical deposit counts and amounts for all customers?
select avg(txn_amount) from customer_transactions where txn_type = 'deposit' ;

---For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?

with countcte as(
select month(txn_date) as txn_month,customer_id ,

count(case when txn_type = 'deposit' then 1 else 0 end ) as deposit_count,

count(case when txn_type = 'purchase' then 1 else 0 end ) as purchase_count,
count(case when txn_type = 'withdrawal' then 1 else 0 end ) as withdrawal_count
from customer_transactions group by customer_id ,MONTH(txn_date))
select txn_month,count(distinct customer_id) as count_customer from countcte where 
deposit_count>1 and (purchase_count>0 or withdrawal_count>0) group by txn_month order by count_customer desc;



---What is the closing balance for each customer at the end of the month?



WITH AmountCte AS(
   SELECT 
   	customer_id,
   	month(txn_date) AS month,
   	SUM(CASE 
   	WHEN txn_type = 'deposit' THEN txn_amount ELSE -txn_amount END) AS amount
   FROM customer_transactions
   GROUP BY customer_id, month(txn_date)

)
select customer_id, month, sum(amount) over (partition by customer_id order by month rows between unbounded preceding and current row) as closing_balance
from AmountCte group by customer_id,month,amount order by customer_id;

