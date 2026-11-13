-- Which neighborhoods are the most expensive?
SELECT neighborhood, ROUND(AVG(price), 2) AS avg_price
FROM active
GROUP BY neighborhood
ORDER BY avg_price DESC
LIMIT 10;