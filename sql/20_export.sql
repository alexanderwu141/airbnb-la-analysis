-- 20_export.sql : the two tables Tableau reads.
-- Run from the repo folder:
--   psql airbnb -v ON_ERROR_STOP=1 -f sql/20_export.sql
-- then write the CSVs with the two \copy lines in the README.
-- Re-run this file after 02_clean.sql and 03_active.sql (CASCADE drops these views).


-- One row per active listing: only the columns the dashboard needs.
CREATE OR REPLACE VIEW export_listings AS
SELECT
    listing_id,
    neighborhood,
    area,
    room_type,
    bedrooms,
    latitude,
    longitude,
    price,
    occupancy_nights,
    revenue_l365d,
    rating,
    is_superhost,
    -- same pool rule as Q8 in 10_q1_market.sql
    (amenities::text ILIKE '%"Pool"%'
     OR amenities::text ILIKE '%"Private pool"%'
     OR amenities::text ILIKE '%"Private outdoor pool%') AS has_pool
FROM active;


-- One row per neighborhood (50+ active listings, as in Q3, Q5 and Q6),
-- with counts, medians and a four-way label.
CREATE OR REPLACE VIEW export_neighborhoods AS
WITH by_hood AS (
    SELECT
        neighborhood,
        area,
        COUNT(*) AS listings,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)            AS median_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue_l365d)    AS median_revenue,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY occupancy_nights) AS median_nights
    FROM active
    GROUP BY neighborhood, area
    HAVING COUNT(*) >= 50
),
middle AS (
    -- the typical neighborhood: the median of the neighborhood medians
    SELECT
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY median_price)   AS mid_price,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY median_revenue) AS mid_revenue
    FROM by_hood
)
SELECT
    b.neighborhood,
    b.area,
    b.listings,
    ROUND(b.median_price::numeric, 0)   AS median_price,
    ROUND(b.median_revenue::numeric, 0) AS median_revenue,
    ROUND(b.median_nights::numeric, 0)  AS median_nights,
    CASE
        WHEN b.median_price >= m.mid_price AND b.median_revenue >= m.mid_revenue
            THEN 'Premium'        -- high price, high revenue
        WHEN b.median_price >= m.mid_price
            THEN 'Over-priced'    -- high price, low revenue
        WHEN b.median_revenue >= m.mid_revenue
            THEN 'Hidden gem'     -- low price, high revenue
        ELSE 'Budget'             -- low price, low revenue
    END AS label
FROM by_hood AS b
CROSS JOIN middle AS m;