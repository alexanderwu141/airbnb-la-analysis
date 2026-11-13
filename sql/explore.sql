-- How many listings are there of each room type?
SELECT room_type, COUNT(room_type)
FROM listings_raw
GROUP BY room_type
ORDER BY COUNT(room_type) DESC;

-- What percentage of listings have no price?
SELECT 
    COUNT(*) AS total_rows,
    SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) AS missing_count,
    ROUND((SUM(CASE WHEN price IS NULL THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2) AS missing_percentage
FROM listings_raw;

-- Show the 10 longest price strings.
SELECT 
    DISTINCT price,
    length(price) AS price_length
FROM listings_raw
ORDER BY price_length DESC
LIMIT 10;

-- The 10 neighborhoods with the most listings, with their group.
SELECT
    neighbourhood_cleansed,
    COUNT(*) AS counts
FROM listings_raw
GROUP BY neighbourhood_cleansed
ORDER BY counts DESC
LIMIT 10;

-- Which columns are actually filled in?
SELECT 
    COUNT(*) AS total_rows,
    COUNT(host_response_time) AS has_response_time,
    COUNT(host_response_rate) AS has_response_rate,
    COUNT(host_acceptance_rate) AS has_acceptance_rate,
    COUNT(host_is_superhost) AS has_superhost,
    COUNT(price) AS has_price
FROM listings_raw;

-- How many listings are listed as monthly rentals (have minimum_nights of 30 or more)?
SELECT COUNT(minimum_nights)
FROM listings_raw
WHERE minimum_nights::integer >= 30;

-- Check the clean listings table's new columns
SELECT listing_name, price, is_superhost, rating, revenue_l365d
FROM listings
ORDER BY random()
LIMIT 5;

-- Check: host_listings vs listings in active
-- host_listings counts ALL of a host's LA listings, before my filters.
-- Example: host 95543 has host_listings = 11 but only 6 rows in active.
-- Decision: keep host_listings as host size (it measures how big the business is).

-- Host 99543's listings after filtering for active listings
SELECT listing_id, host_id, host_listings
FROM active
WHERE host_id = 95543;

-- Host 99543's listings before filtering
SELECT listing_id, host_id, host_listings
FROM listings
WHERE host_id = 95543;

-- Host 99543's listings excluded after filtering
SELECT
    l.listing_id, 
    l.host_id, 
    l.host_listings
FROM listings AS l
LEFT JOIN active AS a
    ON a.listing_id = l.listing_id
WHERE a.listing_id IS NULL
  AND l.host_id = 95543;