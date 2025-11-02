
-- ============================================
-- SQL PORTFOLIO - ALL PROJECTS (BY: AISHA HAMMAD)
-- ============================================
-- Database: PostgreSQL
-- This master file includes:
-- 1) E-commerce Sales Analysis
-- 2) Payroll Management System
-- 3) Library Management System
-- 4) Financial Fraud Detection
-- 5) Recommendation System Prototype
-- ============================================


-- ======================================================================
-- 1️⃣ E-COMMERCE SALES PERFORMANCE ANALYSIS
-- ======================================================================

-- Drop existing tables (safe reset)
DROP TABLE IF EXISTS order_items, orders, customers, products CASCADE;

-- Schema
CREATE TABLE customers (
  customer_id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT,
  created_at DATE
);

CREATE TABLE products (
  product_id SERIAL PRIMARY KEY,
  name TEXT,
  category TEXT,
  price NUMERIC(10,2)
);

CREATE TABLE orders (
  order_id SERIAL PRIMARY KEY,
  customer_id INT REFERENCES customers(customer_id),
  order_date DATE,
  total_amount NUMERIC(12,2)
);

CREATE TABLE order_items (
  order_item_id SERIAL PRIMARY KEY,
  order_id INT REFERENCES orders(order_id),
  product_id INT REFERENCES products(product_id),
  quantity INT,
  unit_price NUMERIC(10,2)
);

-- Sample Data
INSERT INTO customers (name,email,created_at) VALUES
('Aisha','aisha@example.com','2025-06-01'),
('Bilal','bilal@example.com','2025-07-10');

INSERT INTO products (name,category,price) VALUES
('Widget A','Gadgets',100.00),
('Widget B','Gadgets',50.00),
('Book X','Books',20.00);

INSERT INTO orders (customer_id,order_date,total_amount) VALUES
(1,'2025-08-05',200.00),
(2,'2025-09-12',150.00);

INSERT INTO order_items (order_id,product_id,quantity,unit_price) VALUES
(1,1,1,100.00),
(1,3,5,20.00),
(2,2,3,50.00);

-- Analytics Queries
-- Top Selling Products in Last Quarter
SELECT p.name, SUM(oi.quantity) AS total_sold
FROM order_items oi
JOIN orders o ON oi.order_id=o.order_id
JOIN products p ON oi.product_id=p.product_id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '3 months'
GROUP BY p.name
ORDER BY total_sold DESC;


-- ======================================================================
-- 2️⃣ PAYROLL MANAGEMENT SYSTEM
-- ======================================================================

DROP TABLE IF EXISTS payroll, employees, departments CASCADE;

-- Schema
CREATE TABLE departments (
  dept_id SERIAL PRIMARY KEY,
  name TEXT
);

CREATE TABLE employees (
  emp_id SERIAL PRIMARY KEY,
  name TEXT,
  dept_id INT REFERENCES departments(dept_id),
  base_salary NUMERIC(12,2),
  hire_date DATE
);

CREATE TABLE payroll (
  payroll_id SERIAL PRIMARY KEY,
  emp_id INT REFERENCES employees(emp_id),
  pay_period DATE,
  gross_pay NUMERIC(12,2),
  tax_deduction NUMERIC(12,2),
  net_pay NUMERIC(12,2),
  created_at TIMESTAMP DEFAULT now()
);

-- Stored Procedure
CREATE OR REPLACE FUNCTION calculate_payroll(p_emp_id INT, p_period DATE)
RETURNS VOID AS $$
DECLARE
  base NUMERIC(12,2);
  tax NUMERIC(12,2);
  gross NUMERIC(12,2);
  net NUMERIC(12,2);
BEGIN
  SELECT base_salary INTO base FROM employees WHERE emp_id = p_emp_id;
  IF base IS NULL THEN RETURN; END IF;
  gross := base;

  IF gross <= 50000 THEN
    tax := ROUND(gross * 0.10,2);
  ELSE
    tax := ROUND(gross * 0.20,2);
  END IF;

  net := gross - tax;
  INSERT INTO payroll (emp_id,pay_period,gross_pay,tax_deduction,net_pay)
  VALUES (p_emp_id,p_period,gross,tax,net);
END;
$$ LANGUAGE plpgsql;


-- ======================================================================
-- 3️⃣ LIBRARY MANAGEMENT SYSTEM
-- ======================================================================

DROP TABLE IF EXISTS borrowings, members, books CASCADE;

CREATE TABLE members (
  member_id SERIAL PRIMARY KEY,
  name TEXT,
  email TEXT
);

CREATE TABLE books (
  book_id SERIAL PRIMARY KEY,
  title TEXT,
  author TEXT,
  copies_total INT,
  copies_available INT
);

CREATE TABLE borrowings (
  borrow_id SERIAL PRIMARY KEY,
  member_id INT REFERENCES members(member_id),
  book_id INT REFERENCES books(book_id),
  borrowed_at DATE,
  due_date DATE,
  returned_at DATE,
  late_fee NUMERIC(8,2) DEFAULT 0
);

-- Function: Book Issue
CREATE OR REPLACE FUNCTION issue_book(p_member INT, p_book INT, p_days INT)
RETURNS TEXT AS $$
BEGIN
  UPDATE books SET copies_available = copies_available - 1 WHERE book_id=p_book;
  INSERT INTO borrowings(member_id,book_id,borrowed_at,due_date)
  VALUES(p_member,p_book,CURRENT_DATE,CURRENT_DATE + (p_days||' days')::interval);
  RETURN 'Issued';
END;
$$ LANGUAGE plpgsql;


-- ======================================================================
-- 4️⃣ FINANCIAL FRAUD DETECTION RULES
-- ======================================================================

DROP TABLE IF EXISTS transactions CASCADE;

CREATE TABLE transactions (
  txn_id SERIAL PRIMARY KEY,
  account_id INT,
  txn_date TIMESTAMP,
  amount NUMERIC(12,2),
  merchant TEXT
);

-- Detection Query (Z-score based)
WITH stats AS (
  SELECT account_id, AVG(amount) avg_amt, STDDEV_POP(amount) sd_amt
  FROM transactions GROUP BY account_id
)
SELECT *
FROM transactions t
JOIN stats s USING (account_id)
WHERE (t.amount - s.avg_amt) / NULLIF(s.sd_amt,0) > 3;


-- ======================================================================
-- 5️⃣ RECOMMENDATION SYSTEM PROTOTYPE
-- ======================================================================

DROP TABLE IF EXISTS ratings CASCADE;

CREATE TABLE ratings (
  user_id INT,
  item_id INT,
  rating INT,
  rated_at DATE
);

-- Recommendation Query
WITH pairs AS (
  SELECT r1.user_id u1, r2.user_id u2, r1.item_id, r1.rating r1r, r2.rating r2r
  FROM ratings r1
  JOIN ratings r2 ON r1.item_id=r2.item_id AND r1.user_id<r2.user_id
),
sim AS (
  SELECT u1,u2,
  SUM(r1r*r2r) dot,
  SQRT(SUM(r1r*r1r)) n1,
  SQRT(SUM(r2r*r2r)) n2
  FROM pairs GROUP BY u1,u2
)
SELECT item_id, AVG(rating) AS score
FROM ratings WHERE user_id=1
GROUP BY item_id
ORDER BY score DESC;
