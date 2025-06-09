CREATE DATABASE IF NOT EXISTS retail_sales;
USE retail_sales;
# Create the customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    signup_date DATE,
    region VARCHAR(50)
);
# Create the products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10, 2),
    stock_qty INT
);
# Create the orders table
CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10, 2),
    payment_method VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);
# Create the order_items table
CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    unit_price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
# Create the returns table
CREATE TABLE returns (
    return_id INT PRIMARY KEY,
    order_id INT,
    product_id INT,
    return_date DATE,
    reason VARCHAR(100),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
# Create the reviews table
CREATE TABLE reviews (
    review_id INT PRIMARY KEY,
    customer_id INT,
    product_id INT,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    review_date DATE,
    comments TEXT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);
# checking all tables:
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM products;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM returns;
SELECT COUNT(*) FROM reviews;

-- QUERIES:
# 1. Revenue Analysis
# Q: Which region contributes the most to overall revenue?
SELECT 
    c.region,
    ROUND(SUM(o.total_amount), 2) AS total_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
GROUP BY c.region
ORDER BY total_revenue DESC;
# Ans: Region East contributes the most.

# Q: Which products drive the most revenue?
SELECT 
    p.name AS product_name,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.name
ORDER BY total_revenue DESC
LIMIT 5;
# Ans: Google Pixel 7 drives the most revenue followed by kitchenaid mixer.

# 2.Customer Analysis
# Q: Who are our most valuable customers?
SELECT 
    c.name AS customer_name,
    SUM(o.total_amount) AS total_spent
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 5;
# Ans: Lindsay Miler and Scott Hahn are most valuable customers.

# Q: How can we segment our customers to tailor marketing efforts and improve accordingy?
SELECT 
    c.customer_id,
    c.name,
    SUM(o.total_amount) AS total_spent,
    CASE 
        WHEN SUM(o.total_amount) >= 1000 THEN 'High Spender'
        WHEN SUM(o.total_amount) >= 500 THEN 'Mid Spender'
        ELSE 'Low Spender'
    END AS segment
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY total_spent DESC;
# Ans: Lindsay Miller and Scott Hahn high spenders etc and Taylor Jhonson, James philip are Mid spender etc, Judith miler is low spender. So segmentation done according to high, mid, low spender.

# 3.Product Performance
# Q: Which Products are most returned?
SELECT 
    p.name AS product_name,
    COUNT(*) AS return_count
FROM returns r
JOIN products p ON r.product_id = p.product_id
GROUP BY p.name
ORDER BY return_count DESC
LIMIT 5;
# Ans: Kitchenaid Mixer highest retuen with 3, followed by Nike air max 270 with 2 etc.

# Q: Which products have five star reviews?
SELECT 
    p.name AS product_name,
    COUNT(*) AS five_star_reviews
FROM reviews r
JOIN products p ON r.product_id = p.product_id
WHERE r.rating = 5
GROUP BY p.name
ORDER BY five_star_reviews DESC
LIMIT 5;
# Ans: Adidas Ultraboost, Lego star wars set, barbie dreamhouse, nike air max 270 annd Apple iphone 14.

# 4. Operational Insights
# Q: What is the average number of items per order?
SELECT 
    ROUND(AVG(items_per_order), 2) AS avg_basket_size
FROM (
    SELECT 
        order_id,
        SUM(quantity) AS items_per_order
    FROM order_items
    GROUP BY order_id
) AS sub;
# Ans: Average basket size is 5.61.

# Q: How is order volume changing over time — month-over-month?
SELECT 
    DATE_FORMAT(order_date, '%Y-%m') AS month,
    COUNT(*) AS order_count
FROM orders
GROUP BY month
ORDER BY month;
# Ans: Order volume has been declining steadily over time, starting from 24 orders in December 2024 to just 10 in May 2025.

# 5. Risk/Issue Detection
# Q: What are the products with high returns and low ratings?
SELECT 
    p.name AS product_name,
    COUNT(DISTINCT r.return_id) AS return_count,
    ROUND(AVG(rv.rating), 2) AS avg_rating
FROM products p
LEFT JOIN returns r ON p.product_id = r.product_id
LEFT JOIN reviews rv ON p.product_id = rv.product_id
GROUP BY p.name
HAVING return_count >= 1 AND avg_rating < 3.5
ORDER BY return_count DESC;
# Ans: Kitchenaid Mixer had 3 returns with 3 as avg rating, followed by Fitbit Charge 5 & IKEA Dining Table very low ratings (2.00), even with just 1 return. These could indicate product quality issues, misleading expectations, or inadequate descriptions.

# Q: What are categories with high return rate?
SELECT 
    p.category,
    COUNT(DISTINCT r.return_id) AS total_returns,
    ROUND(COUNT(DISTINCT r.return_id) * 100.0 / COUNT(DISTINCT oi.item_id), 2) AS return_rate_pct
FROM returns r
JOIN products p ON r.product_id = p.product_id
JOIN order_items oi ON oi.product_id = p.product_id
GROUP BY p.category
ORDER BY return_rate_pct DESC;
# Ans: Home category has 5 returns with return rate of 16.67, followed by clothing category with t return and return rate of 13.89. Then come electronics and toys.

-- END--

