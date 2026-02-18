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
--    (überschaubar, manuell oder mit Prozeduren generiert)
-- ############################################################

-- Datum: 1 Jahr (z.B. 2024) generieren
DELETE FROM dim_date;


DROP PROCEDURE IF EXISTS fill_dim_date;
DELIMITER //
CREATE PROCEDURE fill_dim_date()
BEGIN  
    DECLARE start_date DATE DEFAULT '2024-01-01';
    DECLARE end_date DATE DEFAULT '2024-12-31';

WHILE start_date <= end_date DO
    INSERT INTO dim_date (
        date_key, full_date, day_of_week, day_of_month,
        month, month_name, quarter, year, is_weekend
    ) VALUES (
        DATE_FORMAT(start_date, '%Y%m%d'),
        start_date,
        DATE_FORMAT(start_date, '%W'),    -- Monday, Tuesday ...
        DAYOFMONTH(start_date),
        MONTH(start_date),
        DATE_FORMAT(start_date, '%M'),    -- January, February ...
        QUARTER(start_date),
        YEAR(start_date),
        CASE WHEN DAYOFWEEK(start_date) IN (1,7) THEN 1 ELSE 0 END
    );
    

    SET start_date = DATE_ADD(start_date, INTERVAL 1 DAY);
END WHILE;
END //
DELIMITER ;

CALL fill_dim_date();
DROP PROCEDURE fill_dim_date;

-- Produkte (10 Beispiele)
DELETE FROM dim_product;

INSERT INTO dim_product
    (product_id, product_name, category, subcategory, brand, supplier)
VALUES
    ('P-001', 'Smartphone Alpha',      'Elektronik', 'Smartphone',  'AlphaTech',  'GlobalTech GmbH'),
    ('P-002', 'Smartphone Beta',       'Elektronik', 'Smartphone',  'BetaCorp',   'GlobalTech GmbH'),
    ('P-003', 'Laptop Lite 13"',       'Elektronik', 'Laptop',      'NotePro',    'ComputerWorld AG'),
    ('P-004', 'Laptop Power 15"',      'Elektronik', 'Laptop',      'NotePro',    'ComputerWorld AG'),
    ('P-005', 'Gaming Mouse X1',       'Zubehör',    'Maus',        'GameMax',    'Peripherie GmbH'),
    ('P-006', 'Mechanical Keyboard',   'Zubehör',    'Tastatur',    'TypeFast',   'Peripherie GmbH'),
    ('P-007', '4K Monitor 27"',        'Elektronik', 'Monitor',     'ViewSharp',  'Display AG'),
    ('P-008', 'USB-C Hub 7-in-1',      'Zubehör',    'Adapter',     'ConnectIT',  'Peripherie GmbH'),
    ('P-009', 'Bluetooth Headset',     'Audio',      'Headset',     'SoundWave',  'AudioPlus KG'),
    ('P-010', 'External SSD 1TB',      'Speicher',   'SSD',         'FastStore',  'Storage AG');

-- Kunden (50 Beispiele, halbwegs zufällig)
DELETE FROM dim_customer;

DelimITER //
CREATE PROCEDURE fill_dim_customer()
BEGIN

DECLARE i INT DEFAULT 1;
WHILE i <= 50 DO
    INSERT INTO dim_customer (
        customer_id, first_name, last_name, email,
        city, country, customer_segment
    ) VALUES (
        CONCAT('C-', LPAD(i, 4, '0')),
        CONCAT('Vorname', i),
        CONCAT('Nachname', i),
        CONCAT('kunde', i, '@[example.com](http://example.com)'),
        CASE
            WHEN i % 5 = 0 THEN 'Wien'
            WHEN i % 5 = 1 THEN 'Graz'
            WHEN i % 5 = 2 THEN 'Linz'
            WHEN i % 5 = 3 THEN 'Salzburg'
            ELSE 'Innsbruck'
        END,
        'Österreich',
        CASE
            WHEN i % 3 = 0 THEN 'Business'
            WHEN i % 3 = 1 THEN 'Privat'
            ELSE 'VIP'
        END
    );
    SET i = i + 1;
END WHILE;
END //
DELIMITER ;

CALL fill_dim_customer();
DROP PROCEDURE fill_dim_customer;

-- Stores (5 Filialen)
DELETE FROM dim_store;

INSERT INTO dim_store
    (store_id, store_name, city, region, country)
VALUES
    ('S-001', 'Store Wien Mitte',    'Wien',      'Ost',   'Österreich'),
    ('S-002', 'Store Graz City',     'Graz',      'Süd',   'Österreich'),
    ('S-003', 'Store Linz Donau',    'Linz',      'Nord',  'Österreich'),
    ('S-004', 'Store Salzburg Alt',  'Salzburg',  'West',  'Österreich'),
    ('S-005', 'Store Innsbruck',     'Innsbruck', 'West',  'Österreich');

-- ############################################################
-- 5. ~1000 Beispiel-Datensätze in die Faktentabelle laden
--    (Pseudo-zufällig generiert)
-- ############################################################

DELETE FROM sales_fact;

DELIMITER //
CREATE PROCEDURE fill_sales_fact()
BEGIN
DECLARE row_count INT DEFAULT 0;
DECLARE rand_date DATE;
DECLARE date_key INT;
DECLARE product_key INT;
DECLARE customer_key INT;
DECLARE store_key INT;
DECLARE quantity INT;
DECLARE base_price DECIMAL(10,2);
DECLARE unit_price DECIMAL(10,2);
DECLARE discount_rate DECIMAL(4,2);
DECLARE gross_amount DECIMAL(10,2);
DECLARE discount_amount DECIMAL(10,2);
DECLARE total_amount DECIMAL(10,2);

WHILE row_count < 1000 DO
    -- Zufälliges Datum aus dem Jahr 2024
    SET rand_date = DATE_ADD('2024-01-01', INTERVAL FLOOR(RAND() * 365) DAY);
    SET date_key  = DATE_FORMAT(rand_date, '%Y%m%d');

    -- Zufälliges Produkt (1..10)
    SET product_key = FLOOR(1 + RAND() * 10);

    -- Zufälliger Kunde (1..50)
    SET customer_key = FLOOR(1 + RAND() * 50);

    -- Zufälliger Store (1..5)
    SET store_key = FLOOR(1 + RAND() * 5);

    -- Menge 1..5
    SET quantity = FLOOR(1 + RAND() * 5);

    -- Basispreis je nach Produkt grob staffeln
    SET base_price =
        CASE
            WHEN product_key IN (1,2) THEN 400 + RAND()*400      -- Smartphones
            WHEN product_key IN (3,4) THEN 800 + RAND()*700      -- Laptops
            WHEN product_key IN (7)   THEN 250 + RAND()*250      -- Monitor
            WHEN product_key IN (9)   THEN 80  + RAND()*120      -- Headset
            WHEN product_key IN (10)  THEN 100 + RAND()*200      -- SSD
            ELSE 20 + RAND()*80                                  -- Zubehör
        END;

    SET unit_price = ROUND(base_price, 2);

    -- Rabatt 0..20%
    SET discount_rate = RAND() * 0.2;
    SET gross_amount  = quantity * unit_price;
    SET discount_amount = ROUND(gross_amount * discount_rate, 2);
    SET total_amount    = ROUND(gross_amount - discount_amount, 2);

    INSERT INTO sales_fact (
        date_key, product_key, customer_key, store_key,
        quantity, unit_price, total_amount, discount_amount
    ) VALUES (
        date_key, product_key, customer_key, store_key,
        quantity, unit_price, total_amount, discount_amount
    );

    SET row_count = row_count + 1;
END WHILE;  
END //
DELIMITER ;
CALL fill_sales_fact();
DROP PROCEDURE fill_sales_fact;

-- ############################################################
-- 6. Beispielabfragen (OLAP-ähnlich, mit JOINs und Aggregationen)
-- ############################################################

-- Umsatz pro Monat und Kategorie

SELECT
  d.year,
  d.month,
  d.month_name,
  p.category,
  SUM(f.total_amount) AS total_sales,
  SUM(f.quantity)     AS total_quantity
FROM sales_fact f
JOIN dim_date    d ON f.date_key    = d.date_key
JOIN dim_product p ON f.product_key = p.product_key
GROUP BY
  d.year, d.month, d.month_name, p.category
ORDER BY
  d.year, d.month, p.category;

-- Top 10 Kunden nach Umsatz
SELECT
  c.customer_id,
  c.first_name,
  c.last_name,
  c.country,
  SUM(f.total_amount) AS total_spent,
  COUNT(f.sale_id)    AS number_of_purchases
FROM sales_fact f
JOIN dim_customer c ON f.customer_key = c.customer_key
GROUP BY
  c.customer_key, c.customer_id, c.first_name, c.last_name, c.country
ORDER BY
  total_spent DESC
LIMIT 10;