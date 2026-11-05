create database Banking_analysis;

use banking_analysis;
show tables;
select *
from indian_banking_transactions
limit 10;

describe indian_banking_transactions;

USE banking_analysis;

-- 1. Total records
SELECT COUNT(*) AS total_records
FROM indian_banking_transactions;

-- 2. Duplicate transaction IDs
SELECT transaction_id, COUNT(*) AS occurrences
FROM indian_banking_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- 3. Missing values
SELECT
    SUM(transaction_id IS NULL OR transaction_id = '') AS missing_transaction_id,
    SUM(customer_id IS NULL OR customer_id = '') AS missing_customer_id,
    SUM(transaction_date IS NULL OR transaction_date = '') AS missing_date,
    SUM(transaction_amount IS NULL) AS missing_amount
FROM indian_banking_transactions;

-- 4. Transaction types
SELECT transaction_type, COUNT(*) AS total
FROM indian_banking_transactions
GROUP BY transaction_type;

-- 5. Account types
SELECT account_type, COUNT(*) AS total
FROM indian_banking_transactions
GROUP BY account_type;

SELECT
    transaction_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount
FROM indian_banking_transactions
GROUP BY transaction_type
ORDER BY total_transactions DESC;

SELECT
    DATE_FORMAT(
        STR_TO_DATE(transaction_date, '%Y-%m-%d'),
        '%Y-%m'
    ) AS transaction_month,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount
FROM indian_banking_transactions
WHERE STR_TO_DATE(transaction_date, '%Y-%m-%d') IS NOT NULL
GROUP BY transaction_month
ORDER BY transaction_month;

SELECT
    customer_id,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_transaction_amount,
    ROUND(AVG(transaction_amount), 2) AS average_transaction_amount
FROM indian_banking_transactions
GROUP BY customer_id
ORDER BY total_transaction_amount DESC
LIMIT 10;

SELECT
    customer_id,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount
FROM indian_banking_transactions
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 10;

SELECT
    customer_id,
    total_amount,
    RANK() OVER (ORDER BY total_amount DESC) AS customer_rank
FROM (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM indian_banking_transactions
    GROUP BY customer_id
) AS customer_summary
ORDER BY customer_rank
LIMIT 10;
USE banking_analysis;

DESCRIBE indian_banking_transactions;

SELECT COUNT(*) AS total_transactions
FROM indian_banking_transactions;

SELECT
    COUNT(DISTINCT customer_id) AS total_customers,
    MIN(STR_TO_DATE(transaction_date, '%Y-%m-%d')) AS first_date,
    MAX(STR_TO_DATE(transaction_date, '%Y-%m-%d')) AS last_date
FROM indian_banking_transactions;

USE banking_analysis;

DESCRIBE indian_banking_transactions;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT transaction_id) AS unique_transactions,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(transaction_id IS NULL) AS missing_transaction_ids,
    SUM(customer_id IS NULL) AS missing_customer_ids,
    SUM(transaction_amount IS NULL) AS missing_amounts
FROM indian_banking_transactions;

USE banking_analysis;

WITH monthly_summary AS (
    SELECT
        DATE_FORMAT(
            STR_TO_DATE(transaction_date, '%Y-%m-%d'),
            '%Y-%m'
        ) AS transaction_month,
        COUNT(*) AS total_transactions,
        SUM(transaction_amount) AS total_amount
    FROM indian_banking_transactions
    GROUP BY DATE_FORMAT(
        STR_TO_DATE(transaction_date, '%Y-%m-%d'),
        '%Y-%m'
    )
)
SELECT
    transaction_month,
    total_transactions,
    ROUND(total_amount, 2) AS total_amount,
    LAG(total_amount) OVER (
        ORDER BY transaction_month
    ) AS previous_month_amount,
    ROUND(
        (
            total_amount - LAG(total_amount) OVER (
                ORDER BY transaction_month
            )
        ) / NULLIF(
            LAG(total_amount) OVER (
                ORDER BY transaction_month
            ), 0
        ) * 100,
        2
    ) AS mom_growth_percent
FROM monthly_summary
ORDER BY transaction_month;

SELECT
    transaction_id,
    customer_id,
    STR_TO_DATE(transaction_date, '%Y-%m-%d') AS transaction_date,
    transaction_amount,
    SUM(transaction_amount) OVER (
        ORDER BY
            STR_TO_DATE(transaction_date, '%Y-%m-%d'),
            transaction_time,
            transaction_id
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total
FROM indian_banking_transactions
ORDER BY
    STR_TO_DATE(transaction_date, '%Y-%m-%d'),
    transaction_time,
    transaction_id
LIMIT 20;

USE banking_analysis;

-- 1. Total records
SELECT COUNT(*) AS total_records
FROM indian_banking_transactions;

-- 2. Duplicate transaction IDs
SELECT transaction_id, COUNT(*) AS occurrences
FROM indian_banking_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- 3. Missing values
SELECT
    SUM(transaction_id IS NULL OR transaction_id = '') AS missing_transaction_id,
    SUM(customer_id IS NULL OR customer_id = '') AS missing_customer_id,
    SUM(transaction_date IS NULL OR transaction_date = '') AS missing_date,
    SUM(transaction_amount IS NULL) AS missing_amount
FROM indian_banking_transactions;

-- 4. Transaction types
SELECT transaction_type, COUNT(*) AS total
FROM indian_banking_transactions
GROUP BY transaction_type;

-- 5. Account types
SELECT account_type, COUNT(*) AS total
FROM indian_banking_transactions
GROUP BY account_type;

USE banking_analysis;

CREATE OR REPLACE VIEW vw_customer_summary AS
SELECT
    customer_id,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount
FROM indian_banking_transactions
GROUP BY customer_id;

SELECT *
FROM vw_customer_summary
ORDER BY total_amount DESC
LIMIT 10;

USE banking_analysis;

DROP PROCEDURE IF EXISTS sp_transaction_report;

DELIMITER $$

CREATE PROCEDURE sp_transaction_report(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT
        transaction_type,
        COUNT(*) AS total_transactions,
        ROUND(SUM(transaction_amount), 2) AS total_amount,
        ROUND(AVG(transaction_amount), 2) AS average_amount
    FROM indian_banking_transactions
    WHERE STR_TO_DATE(transaction_date, '%Y-%m-%d')
          BETWEEN p_start_date AND p_end_date
    GROUP BY transaction_type
    ORDER BY total_amount DESC;
END $$

DELIMITER ;

CALL sp_transaction_report('2019-01-01', '2019-01-31');

USE banking_analysis;

DROP PROCEDURE IF EXISTS sp_transaction_report;

DELIMITER $$

CREATE PROCEDURE sp_transaction_report(
    IN p_start_date DATE,
    IN p_end_date DATE
)
BEGIN
    SELECT
        transaction_type,
        COUNT(*) AS total_transactions,
        ROUND(SUM(transaction_amount), 2) AS total_amount,
        ROUND(AVG(transaction_amount), 2) AS average_amount
    FROM indian_banking_transactions
    WHERE STR_TO_DATE(transaction_date, '%Y-%m-%d')
          BETWEEN p_start_date AND p_end_date
    GROUP BY transaction_type
    ORDER BY total_amount DESC;
END$$

DELIMITER ;

SHOW PROCEDURE STATUS
WHERE Db = 'banking_analysis'
  AND Name = 'sp_transaction_report';
  
  CALL banking_analysis.sp_transaction_report(
    '2019-01-01',
    '2019-01-31'
);
USE banking_analysis;

INSERT IGNORE INTO customers (customer_id)
SELECT DISTINCT customer_id
FROM indian_banking_transactions
WHERE customer_id IS NOT NULL
  AND customer_id <> '';

INSERT IGNORE INTO account_types (account_type)
SELECT DISTINCT account_type
FROM indian_banking_transactions
WHERE account_type IS NOT NULL
  AND account_type <> '';

INSERT IGNORE INTO transaction_types (transaction_type)
SELECT DISTINCT transaction_type
FROM indian_banking_transactions
WHERE transaction_type IS NOT NULL
  AND transaction_type <> '';
  
  USE banking_analysis;

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(30) PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS account_types (
    account_type_id INT AUTO_INCREMENT PRIMARY KEY,
    account_type VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS transaction_types (
    transaction_type_id INT AUTO_INCREMENT PRIMARY KEY,
    transaction_type VARCHAR(50) NOT NULL UNIQUE
);

INSERT IGNORE INTO customers (customer_id)
SELECT DISTINCT customer_id
FROM indian_banking_transactions
WHERE customer_id IS NOT NULL
  AND customer_id <> '';

INSERT IGNORE INTO account_types (account_type)
SELECT DISTINCT account_type
FROM indian_banking_transactions
WHERE account_type IS NOT NULL
  AND account_type <> '';

INSERT IGNORE INTO transaction_types (transaction_type)
SELECT DISTINCT transaction_type
FROM indian_banking_transactions
WHERE transaction_type IS NOT NULL
  AND transaction_type <> '';
  
  USE banking_analysis;

CREATE TABLE IF NOT EXISTS bank_transactions (
    transaction_pk BIGINT AUTO_INCREMENT PRIMARY KEY,
    transaction_id VARCHAR(50) NOT NULL,
    customer_id VARCHAR(30) NOT NULL,
    account_type_id INT NOT NULL,
    transaction_type_id INT NOT NULL,
    transaction_date DATE,
    transaction_time TIME,
    transaction_amount DECIMAL(18,2) NOT NULL,
    transaction_direction VARCHAR(30),

    CONSTRAINT fk_bt_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id),

    CONSTRAINT fk_bt_account
        FOREIGN KEY (account_type_id)
        REFERENCES account_types(account_type_id),

    CONSTRAINT fk_bt_type
        FOREIGN KEY (transaction_type_id)
        REFERENCES transaction_types(transaction_type_id),

    CONSTRAINT chk_transaction_amount
        CHECK (transaction_amount >= 0)
);

INSERT INTO bank_transactions (
    transaction_id,
    customer_id,
    account_type_id,
    transaction_type_id,
    transaction_date,
    transaction_time,
    transaction_amount,
    transaction_direction
)
SELECT
    b.transaction_id,
    b.customer_id,
    a.account_type_id,
    t.transaction_type_id,
    STR_TO_DATE(b.transaction_date, '%Y-%m-%d'),
    STR_TO_DATE(b.transaction_time, '%H:%i'),
    b.transaction_amount,
    b.transaction_direction
FROM indian_banking_transactions b
JOIN account_types a
    ON b.account_type = a.account_type
JOIN transaction_types t
    ON b.transaction_type = t.transaction_type
JOIN customers c
    ON b.customer_id = c.customer_id;
    
    SELECT COUNT(*) AS total_transactions
FROM bank_transactions;

SELECT *
FROM bank_transactions
LIMIT 10;

USE banking_analysis;

SHOW TABLES;

DESCRIBE customers;
DESCRIBE account_types;
DESCRIBE transaction_types;

USE banking_analysis;

SHOW CREATE TABLE customers;

SHOW CREATE TABLE account_types;

SHOW CREATE TABLE transaction_types;

USE banking_analysis;

SHOW TABLES;

SELECT TABLE_NAME, ENGINE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'banking_analysis';

USE banking_analysis;

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(30) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

INSERT IGNORE INTO customers (customer_id)
SELECT DISTINCT customer_id
FROM indian_banking_transactions
WHERE customer_id IS NOT NULL
  AND customer_id <> '';

CREATE TABLE IF NOT EXISTS account_types (
    account_type_id INT AUTO_INCREMENT PRIMARY KEY,
    account_type VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

INSERT IGNORE INTO account_types (account_type)
SELECT DISTINCT account_type
FROM indian_banking_transactions
WHERE account_type IS NOT NULL
  AND account_type <> '';
  
  SHOW TABLES;
  
  USE banking_analysis;

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(30) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS account_types (
    account_type_id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    account_type VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

USE banking_analysis;

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(30) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

INSERT IGNORE INTO customers (customer_id)
SELECT DISTINCT customer_id
FROM indian_banking_transactions
WHERE customer_id IS NOT NULL
AND customer_id <> '';

INSERT IGNORE INTO account_types (account_type)
SELECT DISTINCT account_type
FROM indian_banking_transactions
WHERE account_type IS NOT NULL
AND account_type <> '';

SHOW TABLES;

USE banking_analysis;

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(30) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

INSERT IGNORE INTO customers (customer_id)
SELECT DISTINCT customer_id
FROM indian_banking_transactions
WHERE customer_id IS NOT NULL
AND customer_id <> '';

INSERT IGNORE INTO account_types (account_type)
SELECT DISTINCT account_type
FROM indian_banking_transactions
WHERE account_type IS NOT NULL
AND account_type <> '';
SHOW TABLES;

USE banking_analysis;

CREATE TABLE IF NOT EXISTS customers (
    customer_id VARCHAR(30) NOT NULL PRIMARY KEY
) ENGINE=InnoDB;

INSERT IGNORE INTO customers (customer_id)
SELECT DISTINCT customer_id
FROM indian_banking_transactions
WHERE customer_id IS NOT NULL
  AND customer_id <> '';

SELECT COUNT(*) AS total_customers
FROM customers;
SHOW TABLES;
USE banking_analysis;

CREATE TABLE customers (
    customer_id VARCHAR(30) NOT NULL,
    PRIMARY KEY (customer_id)
) ENGINE = InnoDB;
INSERT IGNORE INTO customers (customer_id)
SELECT DISTINCT customer_id
FROM indian_banking_transactions
WHERE customer_id IS NOT NULL
  AND customer_id <> '';
  SELECT COUNT(*) AS total_customers
FROM customers;

SHOW TABLES;
USE banking_analysis;

DESCRIBE indian_banking_transactions;
DESCRIBE customers;
DESCRIBE account_types;
DESCRIBE transaction_types;

USE banking_analysis;

SHOW CREATE TABLE indian_banking_transactions;

SHOW CREATE TABLE customers;

SHOW CREATE TABLE account_types;

SHOW CREATE TABLE transaction_types;

USE banking_analysis;

SHOW CREATE TABLE indian_banking_transactions;
SHOW CREATE TABLE customers;
SHOW CREATE TABLE account_types;
SHOW CREATE TABLE transaction_types;

SHOW CREATE TABLE indian_banking_transactions;
DESCRIBE indian_banking_transactions;
DESCRIBE account_types;
DESCRIBE customers;

USE banking_analysis;

DESCRIBE indian_banking_transactions;

USE banking_analysis;

DESCRIBE indian_banking_transactions;
DESCRIBE account_types;

DESCRIBE transaction_types;

SELECT
    COUNT(*) AS total_rows,
    SUM(customer_id IS NULL OR customer_id = '') AS missing_customer_id,
    SUM(account_type IS NULL OR account_type = '') AS missing_account_type,
    SUM(transaction_type IS NULL OR transaction_type = '') AS missing_transaction_type
FROM indian_banking_transactions;

SELECT COUNT(*) AS unmatched_customers
FROM indian_banking_transactions t
LEFT JOIN customers c
    ON t.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS unmatched_account_types
FROM indian_banking_transactions t
LEFT JOIN account_types a
    ON t.account_type = a.account_type
WHERE a.account_type IS NULL;

SELECT COUNT(*) AS unmatched_transaction_types
FROM indian_banking_transactions t
LEFT JOIN transaction_types tt
    ON t.transaction_type = tt.transaction_type
WHERE tt.transaction_type IS NULL;

SELECT
    TABLE_NAME,
    ENGINE,
    TABLE_TYPE
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'banking_analysis'
  AND TABLE_NAME IN (
      'indian_banking_transactions',
      'customers',
      'account_types',
      'transaction_types'
  );
  USE banking_analysis;

DESCRIBE customers;
DESCRIBE account_types;
DESCRIBE transaction_types;
DESCRIBE indian_banking_transactions;

USE banking_analysis;

DESCRIBE customers;
DESCRIBE account_types;
DESCRIBE transaction_types;
USE banking_analysis;

DESCRIBE account_types;

DESCRIBE customers;
USE banking_analysis;
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT account_type) AS unique_account_types,
    COUNT(DISTINCT transaction_type) AS unique_transaction_types
FROM indian_banking_transactions;
USE banking_analysis;

SELECT COUNT(*) AS total_customers
FROM customers;

SELECT COUNT(*) AS total_account_types
FROM account_types;

SELECT COUNT(*) AS total_transaction_types
FROM transaction_types;

USE banking_analysis;

SELECT COUNT(*) AS total_customers
FROM customers;

SELECT COUNT(*) AS total_account_types
FROM account_types;

SELECT COUNT(*) AS total_transaction_types
FROM transaction_types;

SELECT COUNT(*) AS total_customers
FROM customers;
SELECT COUNT(*) AS total_transaction_types
FROM transaction_types;
SELECT COUNT(*) AS total_transaction_types
FROM transaction_types;

USE banking_analysis;

SELECT COUNT(*) AS total_customers
FROM customers;
SELECT COUNT(*) AS total_account_types
FROM account_types;

SELECT COUNT(*) AS total_customers
FROM customers;

SELECT
    transaction_id,
    COUNT(*) AS duplicate_count
FROM indian_banking_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

USE banking_analysis;

SELECT
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount,
    ROUND(MAX(transaction_amount), 2) AS highest_amount,
    ROUND(MIN(transaction_amount), 2) AS lowest_amount
FROM indian_banking_transactions;

SELECT
    transaction_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount
FROM indian_banking_transactions
GROUP BY transaction_type
ORDER BY total_amount DESC;

SELECT
    account_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount
FROM indian_banking_transactions
GROUP BY account_type
ORDER BY total_amount DESC;

SELECT
    customer_id,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount
FROM indian_banking_transactions
GROUP BY customer_id
ORDER BY total_amount DESC
LIMIT 10;

SELECT
    DATE_FORMAT(
        STR_TO_DATE(transaction_date, '%Y-%m-%d'),
        '%Y-%m'
    ) AS transaction_month,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount
FROM indian_banking_transactions
WHERE STR_TO_DATE(transaction_date, '%Y-%m-%d') IS NOT NULL
GROUP BY transaction_month
ORDER BY transaction_month;

SELECT
    MIN(transaction_date) AS first_transaction_date,
    MAX(transaction_date) AS last_transaction_date,
    COUNT(DISTINCT transaction_date) AS unique_dates
FROM indian_banking_transactions;

SELECT
    STR_TO_DATE(transaction_date, '%Y-%m-%d') AS transaction_day,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount
FROM indian_banking_transactions
WHERE STR_TO_DATE(transaction_date, '%Y-%m-%d') IS NOT NULL
GROUP BY STR_TO_DATE(transaction_date, '%Y-%m-%d')
ORDER BY transaction_day;

SELECT
    STR_TO_DATE(transaction_date, '%Y-%m-%d') AS transaction_day,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount
FROM indian_banking_transactions
WHERE STR_TO_DATE(transaction_date, '%Y-%m-%d') IS NOT NULL
GROUP BY STR_TO_DATE(transaction_date, '%Y-%m-%d')
ORDER BY total_amount DESC
LIMIT 5;
USE banking_analysis;

SELECT
    t.transaction_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(b.transaction_amount), 2) AS total_amount
FROM indian_banking_transactions b
INNER JOIN transaction_types t
    ON b.transaction_type = t.transaction_type
GROUP BY t.transaction_type
ORDER BY total_amount DESC;

USE banking_analysis;

SELECT
    a.account_type,
    COUNT(*) AS total_transactions,
    ROUND(SUM(b.transaction_amount), 2) AS total_amount
FROM indian_banking_transactions b
INNER JOIN account_types a
    ON b.account_type = a.account_type
GROUP BY a.account_type
ORDER BY total_amount DESC;

USE banking_analysis;

SELECT
    customer_id,
    total_amount,
    RANK() OVER (
        ORDER BY total_amount DESC
    ) AS customer_rank
FROM (
    SELECT
        customer_id,
        SUM(transaction_amount) AS total_amount
    FROM indian_banking_transactions
    GROUP BY customer_id
) AS customer_totals
ORDER BY customer_rank
LIMIT 10;

USE banking_analysis;

WITH customer_summary AS (
    SELECT
        customer_id,
        COUNT(*) AS total_transactions,
        SUM(transaction_amount) AS total_amount
    FROM indian_banking_transactions
    GROUP BY customer_id
)
SELECT
    customer_id,
    total_transactions,
    ROUND(total_amount, 2) AS total_amount
FROM customer_summary
WHERE total_amount > (
    SELECT AVG(total_amount)
    FROM customer_summary
)
ORDER BY total_amount DESC
LIMIT 10;
USE banking_analysis;

SELECT
    customer_id,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    DENSE_RANK() OVER (
        ORDER BY SUM(transaction_amount) DESC
    ) AS customer_rank
FROM indian_banking_transactions
GROUP BY customer_id
ORDER BY customer_rank
LIMIT 10;

USE banking_analysis;

CREATE OR REPLACE VIEW vw_daily_summary AS
SELECT
    STR_TO_DATE(transaction_date, '%Y-%m-%d') AS transaction_day,
    COUNT(*) AS total_transactions,
    ROUND(SUM(transaction_amount), 2) AS total_amount,
    ROUND(AVG(transaction_amount), 2) AS average_amount
FROM indian_banking_transactions
GROUP BY STR_TO_DATE(transaction_date, '%Y-%m-%d');

SELECT * FROM vw_daily_summary
ORDER BY transaction_day;

USE banking_analysis;

CALL sp_transaction_report('2019-01-01', '2019-01-31');

