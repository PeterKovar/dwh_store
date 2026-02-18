-- ############################################################
-- 1. Grund-Setup (Schema optional)
-- ############################################################

-- Optional: eigenes Schema anlegen
CREATE DATABASE IF NOT EXISTS dwh_shop
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_general_ci;

USE dwh_shop;

-- ############################################################
-- 2. Dimensionstabellen
-- ############################################################

DROP TABLE IF EXISTS sales_fact;
DROP TABLE IF EXISTS dim_store;
DROP TABLE IF EXISTS dim_customer;
DROP TABLE IF EXISTS dim_product;
DROP TABLE IF EXISTS dim_date;

-- Zeitdimension
CREATE TABLE dim_date (
    date_key        INT PRIMARY KEY,      -- YYYYMMDD
    full_date       DATE NOT NULL,
    day_of_week     VARCHAR(10),
    day_of_month    INT,
    month           INT,
    month_name      VARCHAR(10),
    quarter         INT,
    year            INT,
    is_weekend      TINYINT(1)            -- 0/1 statt BOOLEAN
) ENGINE=InnoDB;

-- Produktdimension
CREATE TABLE dim_product (
    product_key     INT AUTO_INCREMENT PRIMARY KEY,
    product_id      VARCHAR(50),
    product_name    VARCHAR(200),
    category        VARCHAR(100),
    subcategory     VARCHAR(100),
    brand           VARCHAR(100),
    supplier        VARCHAR(100)
) ENGINE=InnoDB;

-- Kundendimension
CREATE TABLE dim_customer (
    customer_key        INT AUTO_INCREMENT PRIMARY KEY,
    customer_id         VARCHAR(50),
    first_name          VARCHAR(100),
    last_name           VARCHAR(100),
    email               VARCHAR(200),
    city                VARCHAR(100),
    country             VARCHAR(100),
    customer_segment    VARCHAR(50)
) ENGINE=InnoDB;

-- Filialdimension
CREATE TABLE dim_store (
    store_key   INT AUTO_INCREMENT PRIMARY KEY,
    store_id    VARCHAR(50),
    store_name  VARCHAR(200),
    city        VARCHAR(100),
    region      VARCHAR(100),
    country     VARCHAR(100)
) ENGINE=InnoDB;

-- ############################################################
-- 3. Faktentabelle
-- ############################################################

CREATE TABLE sales_fact (
    sale_id         INT AUTO_INCREMENT PRIMARY KEY,
    date_key        INT,
    product_key     INT,
    customer_key    INT,
    store_key       INT,
    quantity        INT,
    unit_price      DECIMAL(10,2),
    total_amount    DECIMAL(10,2),
    discount_amount DECIMAL(10,2),

    CONSTRAINT fk_sales_date
        FOREIGN KEY (date_key) REFERENCES dim_date (date_key),
    CONSTRAINT fk_sales_product
        FOREIGN KEY (product_key) REFERENCES dim_product (product_key),
    CONSTRAINT fk_sales_customer
        FOREIGN KEY (customer_key) REFERENCES dim_customer (customer_key),
    CONSTRAINT fk_sales_store
        FOREIGN KEY (store_key) REFERENCES dim_store (store_key)
) ENGINE=InnoDB;

-- ############################################################
-- 4. Basis-Testdaten für Dimensionen
--    (überschaubar)
-- ############################################################

-- Datum: 1 Jahr (z.B. 2024) generieren
DELETE FROM dim_date;

SET @start_date = DATE('2024-01-01');
SET @end_date   = DATE('2024-12-31');

WHILE @start_date <= @end_date DO
    SET @date_key    = DATE_FORMAT(@start_date, '%Y%m%d');
    SET @dow         = DATE_FORMAT(@start_date, '%W');   -- Monday, Tuesday ...
    SET @dom         = DAYOFMONTH(@start_date);
    SET @month       = MONTH(@start_date);
    SET @month_name  = DATE_FORMAT(@start_date, '%M');   -- January, ...
    SET @quarter     = QUARTER(@start_date);
    SET @year        = YEAR(@start_date);
    SET @is_weekend  = CASE WHEN DAYOFWEEK(@start_date) IN (1,7) THEN 1 ELSE 0 END;

    INSERT INTO dim_date (
        date_key, full_date, day_of_week, day_of_month,
        month, month_name, quarter, year, is_weekend
    ) VALUES (
        @date_key, @start_date, @dow, @dom,
        @month, @month_name, @quarter, @year, @is_weekend
    );

    SET @start_date = DATE_ADD(@start_date, INTERVAL 1 DAY);
END WHILE;
