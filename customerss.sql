-- customer table
-- how many customers do we have
select count(customerid) from customers;

-- check null values
select *
from customers
where accountnumber is null
or account_open_date is null
or account_type is null
or contact_email is null
or contact_phone is null
or customerid is null
or dateofbirth is null
or employment_status is null
or firstname is null
or lastname is null;
-- no null values

-- check for duplicates
select accountnumber,customerid,contact_email, count(*) as count
from customers
group by accountnumber,customerid,contact_email
having count(*) > 1;
-- no duplicates

-- check employment status
select distinct(employment_status), count(*)
from customers
group by employment_status;
