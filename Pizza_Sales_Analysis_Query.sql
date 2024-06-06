USE pizzas;

SELECT * FROM orders;
SELECT * FROM order_details;
SELECT * FROM pizza_types;
SELECT * FROM pizzas;

-- total number of orders placed
SELECT COUNT(DISTINCT order_id) FROM order_details;

SELECT COUNT(order_id) FROM orders;

-- Calculate the total revenue generated from pizza sales
SELECT ROUND(SUM((od.quantity * ps.price)), 2) AS Sales
FROM order_details od
JOIN pizzas ps 
ON ps.pizza_id = od.pizza_id;

-- the highest-priced pizza
SELECT pts.name, pts.category, ps.price
FROM pizza_types pts
JOIN pizzas ps 
ON ps.pizza_type_id = pts.pizza_type_id
ORDER BY ps.price DESC
LIMIT 1;

-- the most common pizza size ordered
SELECT * FROM order_details;
SELECT * FROM pizzas;

SELECT ps.size, COUNT(ps.size) AS Most_Ordered
FROM pizzas ps
JOIN order_details od 
ON od.pizza_id = ps.pizza_id
GROUP BY ps.size
ORDER BY COUNT(ps.size) DESC;

--  the top 5 most ordered pizza types along with their quantities
WITH most_ordered_type(pizza_type_id,Total_Quantity) AS
(
SELECT ps.pizza_type_id,SUM(od.quantity) AS Total_Quantity
FROM pizzas ps
JOIN order_details od 
ON od.pizza_id = ps.pizza_id 
GROUP BY ps.pizza_type_id
)
SELECT pizza_type_id,Total_Quantity,
ROW_NUMBER() OVER(ORDER BY Total_Quantity DESC) AS Ranking
FROM most_ordered_type
LIMIT 5;

-- Join the necessary tables to find the total quantity of each pizza category ordered
SELECT pt.category, SUM(od.quantity)
FROM order_details od
JOIN pizzas ps 
ON ps.pizza_id = od.pizza_id
JOIN pizza_types pt 
ON pt.pizza_type_id = ps.pizza_type_id
GROUP BY pt.category;

-- Determine the distribution of orders by hour of the day
SELECT HOUR(os.`time`) AS hours, SUM(od.quantity)
FROM order_details od
JOIN orders os 
ON os.order_id = od.order_id
GROUP BY HOUR(os.`time`)
ORDER BY HOUR(os.`time`);

-- Join relevant tables to find the category-wise distribution of pizzas
SELECT od.order_details_id, pt.category,od.pizza_id,od.quantity
FROM order_details od
JOIN pizzas ps 
ON od.pizza_id = ps.pizza_id
JOIN pizza_types pt 
ON ps.pizza_type_id = pt.pizza_type_id;

-- Group the orders by date and calculate the average number of pizzas ordered per day
-- Using window function
WITH avg_quantity_ordered_per_day(`date`,quantity) AS
(
SELECT os.`date`,SUM(od.quantity)
FROM orders os
JOIN order_details od 
ON os.order_id = od.order_id
GROUP BY os.`date`
)SELECT AVG(quantity)
FROM avg_quantity_ordered_per_day;

-- Using sub query
SELECT ROUND(AVG(quantity),2)AS Avg_quantity_per_day FROM
(SELECT os.`date`,SUM(od.quantity) AS quantity
FROM orders os
JOIN order_details od 
ON os.order_id = od.order_id
GROUP BY os.`date`) AS Quantity;

-- Determine the top 3 most ordered pizza types based on revenue
/*bbq-ckn
S -6171, M -16013, L -20584
TOTAL- 42768
*/
WITH top3_type_by_revenue(Pizza_type,Revenue) AS
(
SELECT pt.pizza_type_id, SUM(od.quantity * ps.price) AS Revenue
FROM order_details od
JOIN pizzas ps 
ON ps.pizza_id = od.pizza_id
JOIN pizza_types pt 
ON ps.pizza_type_id = pt.pizza_type_id
GROUP BY pt.pizza_type_id
)SELECT *,
DENSE_RANK() OVER(ORDER BY Revenue DESC) AS Ranking
FROM top3_type_by_revenue
LIMIT 3;

-- Calculate the percentage contribution of each pizza type to total revenue
WITH revenue_by_type(Pizza_type,Percent_Contribution) AS
(SELECT pt.pizza_type_id, 
ROUND((SUM(od.quantity * ps.price)/(SELECT SUM(od.quantity * ps.price)
FROM order_details od
JOIN pizzas ps 
ON ps.pizza_id = od.pizza_id) * 100),2)
FROM pizza_types pt
JOIN pizzas ps 
ON ps.pizza_type_id = pt.pizza_type_id
JOIN order_details od 
ON od.pizza_id = ps.pizza_id
GROUP BY pt.pizza_type_id
)SELECT * FROM revenue_by_type;


-- Analyze the cumulative revenue generated over time.
WITH cummulative_revenue AS
(
SELECT MONTH(os.`date`) AS `Month`,
ROUND(SUM(od.quantity * ps.price)) AS Revenue
FROM orders os
JOIN order_details od 
ON od.order_id = os.order_id
JOIN pizzas ps 
ON ps.pizza_id = od.pizza_id
GROUP BY MONTH(os.`date`)
)SELECT `Month`,Revenue,
SUM(Revenue) OVER(ORDER BY `Month`) AS Cummulative_revenue
FROM cummulative_revenue;

-- Determine the top 3 most ordered pizza types based on revenue for each pizza category.
WITH top3_type_by_category_revenue(Category,`Type`,Revenue,Ranking)AS
(
SELECT pt.category,pt.pizza_type_id,ROUND(SUM(od.quantity * ps.price),2),
DENSE_RANK() OVER(PARTITION BY pt.category ORDER BY ROUND(SUM(od.quantity * ps.price),2) DESC)
FROM pizza_types pt
JOIN pizzas ps 
ON ps.pizza_type_id = pt.pizza_type_id
JOIN order_details od 
ON od.pizza_id = ps.pizza_id
GROUP BY pt.category,pt.pizza_type_id
ORDER BY pt.category
)SELECT *
FROM top3_type_by_category_revenue
WHERE Ranking <=3;





