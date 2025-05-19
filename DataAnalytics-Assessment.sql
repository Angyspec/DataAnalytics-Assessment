--  Question 1: High-Value Customers with Multiple Products (Savings and Investments)
SELECT 
    u.id AS owner_id,
    CONCAT(u.first_name, ' ', u.last_name) AS name,
    COUNT(DISTINCT CASE WHEN p.is_regular_savings = 1 THEN p.id END) AS savings_count,
    COUNT(DISTINCT CASE WHEN p.is_a_fund = 1 THEN p.id END) AS investment_count,
    SUM(s.confirmed_amount) / 100 AS total_deposits
FROM 
    users_customuser u
JOIN 
    plans_plan p ON u.id = p.owner_id
JOIN 
    savings_savingsaccount s ON p.id = s.plan_id
GROUP BY 
    u.id, name
HAVING 
    savings_count > 0 AND investment_count > 0
ORDER BY 
    total_deposits DESC;





-- Question 2: Transaction Frequency Analysis
WITH monthly_transactions AS (
    SELECT 
        s.owner_id,
        DATE_FORMAT(s.transaction_date, '%Y-%m') AS month,
        COUNT(*) AS transaction_count
    FROM 
        savings_savingsaccount s
    GROUP BY 
        s.owner_id, month
),
customer_averages AS (
    SELECT 
        owner_id,
        AVG(transaction_count) AS avg_transactions_per_month,
        CASE 
            WHEN AVG(transaction_count) >= 10 THEN 'High Frequency'
            WHEN AVG(transaction_count) >= 3 THEN 'Medium Frequency'
            ELSE 'Low Frequency'
        END AS frequency_category
    FROM 
        monthly_transactions
    GROUP BY 
        owner_id
)
SELECT 
    frequency_category,
    COUNT(*) AS customer_count,
    ROUND(AVG(avg_transactions_per_month), 1) AS avg_transactions_per_month
FROM 
    customer_averages
GROUP BY 
    frequency_category
ORDER BY 
    CASE 
        WHEN frequency_category = 'High Frequency' THEN 1
        WHEN frequency_category = 'Medium Frequency' THEN 2
        ELSE 3
    END;






-- Question 3: Account Inactivity Alert
SELECT 
    p.id AS plan_id,
    p.owner_id,
    CASE 
        WHEN p.is_regular_savings = 1 THEN 'Savings'
        WHEN p.is_a_fund = 1 THEN 'Investment'
        ELSE 'Other'
    END AS type,
    MAX(s.transaction_date) AS last_transaction_date,
    DATEDIFF(CURDATE(), MAX(s.transaction_date)) AS inactivity_days
FROM 
    plans_plan p
LEFT JOIN 
    savings_savingsaccount s ON p.id = s.plan_id
WHERE 
    p.status_id != 3  -- Assuming status_id 3 means inactive/closed
GROUP BY 
    p.id, p.owner_id, type
HAVING 
    inactivity_days > 365 OR last_transaction_date IS NULL
ORDER BY 
    inactivity_days DESC;


-- Question 4: Customer Lifetime Value Estimation
WITH customer_data AS (
    SELECT 
        u.id AS customer_id,
        CONCAT(u.first_name, ' ', u.last_name) AS name,
        TIMESTAMPDIFF(MONTH, u.date_joined, CURDATE()) AS tenure_months,
        COUNT(s.id) AS total_transactions,
        SUM(s.confirmed_amount) / 100 * 0.001 AS total_profit  -- 0.1% of transaction value
    FROM 
        users_customuser u
    LEFT JOIN 
        savings_savingsaccount s ON u.id = s.owner_id
    GROUP BY 
        u.id, name, tenure_months
    HAVING 
        tenure_months > 0  -- Avoid division by zero
)
SELECT 
    customer_id,
    name,
    tenure_months,
    total_transactions,
    ROUND((total_profit / tenure_months) * 12, 2) AS estimated_clv
FROM 
    customer_data
ORDER BY 
    estimated_clv DESC;
