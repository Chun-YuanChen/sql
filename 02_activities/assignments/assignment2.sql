
--Module: SQL
--Name: Chun-Yuan Chen
--Assignment: 2
--Sections: 2 & 3



/* ASSIGNMENT 2 */
/* SECTION 2 */



-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with nulls, and 
'unit' for the second column with nulls.

HINT: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same.) */

SELECT
	/* Notes: 
	1. Initially, I checked for any empty strings in each separate column of interest, 
	   and if found, converted them to NULLs. 
	2. In this case, I see these lines of code as a data cleaning step, although sometimes a blank can 
	   represent specific meaning depending on the context. 
	*/ 
	NULLIF(product_name, '') AS product_name,          
	NULLIF(product_size, '') AS product_size,                
	NULLIF(product_qty_type, '') AS product_qty_type, 
	
COALESCE(product_name, '') || ', ' || COALESCE(product_size, '') || ' (' || COALESCE(product_qty_type, 'unit') || ')' AS product_list
	/* Notes: 
	1. Although the product_name column contains no NULLs, I still applied COALESCE for consistency and to ensure robustness.
	2. In the new product_list column, the two NULLs originally in product_size have now been replaced with blank.
	3. In the new product_list column, the two NULLs originally in product_qty_type have now been replaced with 'unit'.
	*/
FROM product;



--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). */

SELECT DISTINCT customer_id, market_date, /* Notes: I added DISTINCT to ensure that only unique market dates per customer are returned. */
DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date ASC) AS visit_number_asc
	/* Notes: Based on the question, I assumed that multiple transactions on the same date, regardless of time, 
	   count as the same visit. Therefore, I did not bring transaction_time into the code.*/
FROM customer_purchases;



/* 2. Reverse the numbering of the query from a part so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit. */

SELECT customer_id, market_date
FROM (
	SELECT DISTINCT customer_id, market_date,
	DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY market_date DESC) AS visit_number_desc 
	/* Notes: I used DESC to ensure each customer’s most recent visit is labeled 1. */
        FROM customer_purchases
	)
WHERE visit_number_desc = 1; /* Notes: Now, only the most recent visit for each customer is returned. */



/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. */

PRAGMA table_info(customer_purchases); /* Notes: I used this just to get a quick look myself at all the columns. */
SELECT *, COUNT(product_id) OVER (PARTITION BY customer_id, product_id) AS product_purchase_count
FROM customer_purchases;



-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name                          | description |
|---------------------------- |-------------|
| Habanero Peppers - Organic  | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */

SELECT product_name,
	CASE 
		WHEN INSTR(product_name, '-') THEN TRIM(SUBSTR(product_name, INSTR(product_name, '-')+1))
		ELSE NULL
	END AS description
FROM product;



/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */

SELECT * FROM product
WHERE product_size REGEXP '[0-9]';



-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */

DROP TABLE IF EXISTS temp.sales_values_by_date; /* Notes: I found temp. appears to be not necessarily required. */ 
CREATE TEMP TABLE sales_values_by_date AS
SELECT market_date, SUM(quantity * cost_to_customer_per_qty) AS total_sales_values
FROM customer_purchases
GROUP BY market_date;


DROP TABLE IF EXISTS temp.sales_values_ranked; 
CREATE TEMP TABLE sales_values_ranked AS
SELECT market_date, total_sales_values,
       RANK() OVER (ORDER BY total_sales_values DESC) AS total_sales_values_desc,
       RANK() OVER (ORDER BY total_sales_values ASC) AS total_sales_values_asc
FROM sales_values_by_date;


SELECT market_date, total_sales_values, 'best day' AS total_sales_values_marked
FROM sales_values_ranked
WHERE total_sales_values_desc = 1

UNION

SELECT market_date, total_sales_values, 'worst day' AS total_sales_values_marked
FROM sales_values_ranked
WHERE total_sales_values_asc = 1;



/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */


/* Notes:
	1. This question is really no walk in the park, pretty hard!
	2. Original tables needed: customer, vendor, product, vendor_inventory
	3. Derived tables in my case: all_possible_vendor_product_pairs, vendor_original_prices, how_much_vendor_make_per_product.
*/

WITH 
total_number_customers AS (
	SELECT COUNT(DISTINCT c.customer_id) AS num_customers FROM customer c), 
	/* Notes: Get total #customers first, 26, and apply this number later, 
	   because the question highlighted 'every customer on record'.  */

all_possible_vendor_product_pairs AS (
	SELECT v.vendor_id, v.vendor_name, p.product_id, p.product_name FROM vendor v
	CROSS JOIN product p), 
	/* Notes: Get all possible vendor-product pair, 9 vendors x 23 products, 207 pairs. */
	
vendor_original_prices AS (
	SELECT DISTINCT vendor_id, product_id, original_price FROM vendor_inventory), 
	/* Notes: Get each original price for each of the products listed from the three vendors in this table. */

how_much_vendor_make_per_product AS (
	SELECT 
		apvpp.vendor_id, 
		apvpp.vendor_name, 
		apvpp.product_id, 
		apvpp.product_name, 
		vop.original_price, 
		tnc.num_customers,
		5 * vop.original_price * tnc.num_customers AS vendor_revenue
		
	FROM all_possible_vendor_product_pairs apvpp
		LEFT JOIN vendor_original_prices vop ON apvpp.vendor_id = vop.vendor_id AND apvpp.product_id = vop.product_id
		CROSS JOIN total_number_customers tnc)
	/* Notes: Derive the revenue variable. */

SELECT vendor_name, product_name, original_price, num_customers, COALESCE(vendor_revenue, 0) AS vendor_revenue
FROM how_much_vendor_make_per_product
WHERE original_price IS NOT NULL
ORDER BY vendor_name, product_name;
  
 
 
-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */

DROP TABLE IF EXISTS product_units;
CREATE TABLE product_units AS
SELECT *, DATETIME('now', 'localtime') AS snapshot_timestamp
FROM product
WHERE product_qty_type = 'unit';

SELECT * FROM product_units; /* Notes: This line of code just for myself to do a check. */



/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */

INSERT INTO product_units (product_id, product_name, product_size, product_category_id, product_qty_type, snapshot_timestamp)
VALUES (3, 'Poblano Peppers - Organic', 'large', 1, 'unit', DATETIME('now', 'localtime'));
	/* Notes: So, now there are two same records (product_id = 3) except snapshot_timestamp, 
	          one is old and the other new in my case. */

SELECT * FROM product_units; /* Notes: This line of code just for myself to do a check. */



-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
	
DELETE FROM product_units AS pu1
WHERE pu1.snapshot_timestamp < (
	SELECT MAX(snapshot_timestamp)
	FROM product_units AS pu2
	WHERE pu2.product_id = pu1.product_id
	AND pu2.product_name = pu1.product_name
	AND pu2.product_size = pu1.product_size
	AND pu2.product_category_id = pu1.product_category_id
	AND pu2.product_qty_type = pu1.product_qty_type
);

SELECT * FROM product_units; /* Notes: This line of code just for myself to do a check. */


	
-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT;

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */

ALTER TABLE product_units ADD current_quantity INT; 
SELECT * FROM product_units; /* Notes: This line of code just for myself to do a check. */

DROP TABLE IF EXISTS vendor_inventory_copy; 
CREATE TABLE vendor_inventory_copy AS SELECT * FROM vendor_inventory; 
/*Notes: I made a copy to vendor_inventory, didn't want to affect the original one. */

ALTER TABLE vendor_inventory_copy ADD COLUMN current_quantity INT;
SELECT * FROM vendor_inventory_copy; /* Notes: This line of code just for myself to do a check. */

UPDATE vendor_inventory_copy 
/* Notes: It appears to not able to use alias for vendor_inventory_copy in update command here. */
SET current_quantity = (
    SELECT quantity
    FROM vendor_inventory vi
    WHERE vi.product_id = vendor_inventory_copy.product_id
    ORDER BY market_date DESC
    LIMIT 1
);

SELECT * FROM vendor_inventory_copy; /* Notes: This line of code just for myself to do a check. */


DROP TABLE IF EXISTS vendor_inventory_current_quantity;
CREATE TABLE vendor_inventory_current_quantity AS 
SELECT DISTINCT product_id, current_quantity 
FROM vendor_inventory_copy;


UPDATE product_units
SET current_quantity = COALESCE(
	(SELECT vicq.current_quantity FROM vendor_inventory_current_quantity vicq WHERE vicq.product_id = product_units.product_id), 
     0); /* Notes: If not matched, then just use 0 instead. */
     
SELECT * FROM product_units; /* Notes: This line of code just for myself to do a check. */

