-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS Num_of_customers
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT MONTHNAME(start_date) AS months, COUNT(start_date) AS Total_trial_plan
FROM subscriptions
WHERE plan_id = 0
GROUP BY MONTHNAME(start_date)
ORDER BY months DESC;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT plan_name, COUNT(plan_name) AS count
FROM plans
JOIN subscriptions
ON plans.plan_id = subscriptions.plan_id
WHERE YEAR(start_date) > 2020
GROUP BY plan_name;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH cte AS
(SELECT COUNT(customer_id) AS churn_count
FROM subscriptions 
WHERE plan_id = 4)
SELECT churn_count, COUNT(DISTINCT customer_id) AS Num_of_cust, 
CONCAT(ROUND((churn_count/COUNT(DISTINCT customer_id))*100,1), "%") AS percent
FROM cte , subscriptions 
GROUP BY churn_count;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH cte AS (SELECT customer_id, plan_name,
DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY s.plan_id) AS position
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id)
SELECT COUNT(position) AS posttrial_churn_count,
CONCAT(ROUND(100*COUNT(position)/(SELECT COUNT(DISTINCT customer_id)
FROM subscriptions),0),"%") AS percent
FROM cte
WHERE position = 2 AND plan_name = "churn";

-- 6. What is the number and percentage of customer plans after their initial free trial?
WITH cte AS (SELECT customer_id, plan_name,
RANK() OVER(PARTITION BY customer_id ORDER BY s.plan_id) AS position
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id)
SELECT plan_name, COUNT(position) AS posttrial_churn_count,
CONCAT(ROUND(100*COUNT(position)/(SELECT COUNT(DISTINCT customer_id) 
FROM subscriptions),1), "%") AS percent
FROM cte
WHERE position = 2
GROUP BY plan_name;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH cte AS (
SELECT customer_id, p.plan_id, plan_name, start_date,
ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) AS rown
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE start_date <= "2020-12-31")
SELECT plan_name,COUNT(customer_id) AS cust_count,
	CONCAT(ROUND(100*COUNT(customer_id)/
		(SELECT COUNT(DISTINCT customer_id)
		FROM subscriptions),1),'%') AS cust_percent
FROM cte
WHERE rown =1
GROUP BY plan_name;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT plan_name, COUNT(customer_id) AS cust_count_2022
FROM subscriptions
JOIN plans ON subscriptions.plan_id = plans.plan_id
WHERE plan_name = "pro annual" AND YEAR(start_date) = 2020
GROUP BY plan_name;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH trial AS (
SELECT customer_id, start_date
FROM subscriptions
WHERE plan_id = 0),
annual AS (
SELECT customer_id, start_date
FROM subscriptions 
WHERE plan_id = 3)
SELECT ROUND(AVG(DATEDIFF(annual.start_date, trial.start_date)),1) AS avg_num_of_days
FROM trial
JOIN annual ON trial.customer_id = annual.customer_id; 

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
WITH trial AS (
SELECT customer_id, start_date
FROM subscriptions
WHERE plan_id = 0),
annual AS (
SELECT customer_id, start_date
FROM subscriptions 
WHERE plan_id = 3),
bucket as
(
SELECT CASE
WHEN DATEDIFF(trial.start_date,annual.start_date)>=0 AND DATEDIFF(trial.start_date,annual.start_date)<=30
THEN '0-30 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>30 AND DATEDIFF(trial.start_date,annual.start_date)<=60
THEN '30-60 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>60 AND DATEDIFF(trial.start_date,annual.start_date)<=90
THEN'60-90 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>90 AND DATEDIFF(trial.start_date,annual.start_date)<=120
THEN '90-120 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>120 AND DATEDIFF(trial.start_date,annual.start_date)<=150
THEN '120-150 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>150 AND DATEDIFF(trial.start_date,annual.start_date)<=180
THEN '150-180 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>180 AND DATEDIFF(trial.start_date,annual.start_date)<=210
THEN '180-210 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>210 AND DATEDIFF(trial.start_date,annual.start_date)<=240
THEN '210-240 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>240 AND DATEDIFF(trial.start_date,annual.start_date)<=270
THEN '240-270 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>270 AND DATEDIFF(trial.start_date,annual.start_date)<=300
THEN '270-300 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>300 AND DATEDIFF(trial.start_date,annual.start_date)<=330
THEN '300-330 Days'
WHEN DATEDIFF(trial.start_date,annual.start_date)>330 AND DATEDIFF(trial.start_date,annual.start_date)<=360
THEN "330-360 Days"
ELSE 'NA'
END AS Bins
FROM trial 
JOIN annual ON trial.customer_id=annual.customer_id
)
SELECT Bins,COUNT(*) AS customers
FROM bucket
GROUP BY Bins
ORDER BY Bins;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH cte AS (
SELECT customer_id, plan_name, s.plan_id,
LEAD(s.plan_id) OVER (PARTITION BY s.customer_id ORDER BY s.plan_id) AS next_plan_id
FROM subscriptions s
JOIN plans p ON s.plan_id = p.plan_id
WHERE YEAR(start_date) = 2020)
