with salaries as(
select
		cu.accountnumber,
		tr.transactionid,
		tr.transactiondate,
		tr.transaction_amount,
		tr.transdescription
		from customers as cu
		inner join transaction as tr
		on cu.accountnumber = tr.accountnumber
		where cu.employment_status='student'
		and lower(tr.transdescription) like '%salary%'
		and CAST(tr.transactiondate AS timestamp) >= (DATE '2023-08-31' - INTERVAL '12 months')
		and tr.transactiontype = 'Credit'
),

--recency
-- frequency
-- monetary

--calculate RFM values
RFM as(
select
		accountnumber,
		max(cast(transactiondate as timestamp)) as lasttransactiondate,
		EXTRACT(YEAR FROM AGE('2023-08-31'::DATE, MAX(CAST(transactiondate AS TIMESTAMP)))) * 12 +
		EXTRACT(MONTH FROM AGE('2023-08-31'::DATE, MAX(CAST(transactiondate AS TIMESTAMP)))) AS recency,
		count(transactionid) as frequency,
		avg(transaction_amount) as monetaryvalue
from salaries
group by accountnumber
having avg(transaction_amount) >= 200000 
),
-- assign rfm scores to each customer
RFM_Scores as(
select
	accountnumber,
	lasttransactiondate,
	recency,
	frequency,
	monetaryvalue,
	-- score customers based on their recency
	CASE
		When recency = 0 then 10
		when recency < 3 then 7
		when recency < 5 then 4
		else 1
	end as R_Score,
	-- score customers based on their frequency
	CASE
		When frequency = 12 then 10
		when frequency >= 9 then 7
		when frequency >= 6 then 4
		else 1
	end as F_Score,
	-- score customers based on their monetary value
	CASE
		When monetaryvalue > 600000 then 10
		when monetaryvalue > 400000 then 7
		when monetaryvalue between 300000 and 400000 then 4
		else 1
	end as M_Score
from RFM
),
-- segment each customer
segment as (
select 
	accountnumber,
	lasttransactiondate,
	recency,
	frequency,
	monetaryvalue,
	R_Score,
	F_Score,
	M_Score,
	R_Score + F_Score + M_Score as RFM_Totals,
	cast((R_Score + F_Score + M_Score) as float) /30 as RFM_Segment,
	CASE
		When monetaryvalue > 600000 then 'Above 600k'
		when monetaryvalue > 400000 then '400-600k'
		when monetaryvalue between 300000 and 400000 then '300-400k'
		else '200-300k'
	end as Salary_Range,
	-- customer segmentation
    CASE
		when cast((R_Score + F_Score + M_Score) as float)/30 > 0.8 then 'Tier 1 Customers'
		when cast((R_Score + F_Score + M_Score) as float)/30 >= 0.6 then 'Tier 2 Customers'
		when cast((R_Score + F_Score + M_Score) as float)/30 >= 0.5 then 'Tier 3 Customers'
		else 'Tier 4 Customers'
	end as Segments

from RFM_Scores) 

select 
	se.accountnumber,
	cu.contact_email
	lasttransactiondate,
	recency as monthlysincelastsalry,
	frequency as salariesreceived,
	monetaryvalue as avergaesalary,
	Salary_Range,
	Segments
from segment as se
left join customers as cu
on cu.accountnumber = se.accountnumber
