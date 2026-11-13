-- 10_q1_market.sql : analysis questions, run on the active view.
-- Run from the repo folder:  psql airbnb -f sql/10_q1_market.sql
-- Neighborhood rankings only include neighborhoods with at least 50 active
-- listings, so a handful of listings can't top a chart by luck.


-- Q1a: Are private rooms or entire homes more expensive? (by area)
SELECT
    area,
    room_type,
    COUNT(*) AS listings,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price))::numeric, 2)
        AS median_price
FROM active
GROUP BY area, room_type
ORDER BY area, median_price DESC;
-- Result: Entire homes are 80% of active listings (17,700 of 22,252) and cost about
-- 3x a private room: in the City of LA $246 vs $73 a night, in other cities $282 vs
-- $109, unincorporated $278 vs $88. The City of LA has the cheapest entire homes.


-- Q1b: What share of active listings belong to hosts with 5+ listings in LA?
-- host_listings counts all of a host's LA listings, before my filters
-- (see explore.sql).
SELECT
    COUNT(*) AS active_listings,
    SUM(CASE WHEN host_listings >= 5 THEN 1 ELSE 0 END) AS multi_host_listings,
    ROUND(100.0 * SUM(CASE WHEN host_listings >= 5 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS pct_multi_host
FROM active;
-- Result: 41.3% of active listings (9,185 of 22,252) belong to hosts with 5+ listings
-- in LA, so a large part of the market is run by professional operators.


-- Q2: Per area, what share of listings require 30+ nights?
-- Uses the full listings table: monthly rentals often have few reviews,
-- so many of them aren't in active.
SELECT
    area,
    COUNT(*) AS listings,
    ROUND(100.0 * SUM(CASE WHEN minimum_nights >= 30 THEN 1 ELSE 0 END)
          / COUNT(*), 1) AS pct_monthly_rentals
FROM listings
GROUP BY area
ORDER BY pct_monthly_rentals DESC;
-- Result: 74.8% of City of LA listings (of 21,687) require 30+ nights, against 22.8%
-- in other cities and 10.3% in unincorporated areas. That fits the City of LA's
-- short-term rental rules pushing hosts into monthly rentals.


-- Q3: Which neighborhoods have the highest median nightly price?
SELECT
    neighborhood,
    COUNT(*) AS listings,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price))::numeric, 2)
        AS median_price
FROM active
GROUP BY neighborhood
HAVING COUNT(*) >= 50
ORDER BY median_price DESC
LIMIT 10;
-- Result: The most expensive neighborhoods are Avalon on Catalina Island ($751 median),
-- Beverly Crest ($728), Hollywood Hills West ($705) and Malibu ($703).


-- Q4: Price by size: median price and listings by bedrooms (0 to 5, then 6+)
SELECT
    CASE WHEN bedrooms >= 6 THEN '6+' ELSE bedrooms::text END AS bedroom_group,
    COUNT(*) AS listings,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price))::numeric, 2)
        AS median_price
FROM active
WHERE bedrooms IS NOT NULL
GROUP BY bedroom_group
ORDER BY MIN(bedrooms);
-- Result: Price rises with size: studios and 1-bedrooms are about the same ($150, $146),
-- a 2-bedroom costs about twice as much ($296), and each extra bedroom adds roughly
-- $100-170 a night up to $867 for 6+. 1-bedrooms are the most common (10,539).


-- Q5: Where do listings earn the most? Highest median yearly revenue
SELECT
    neighborhood,
    COUNT(*) AS listings,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue_l365d))::numeric, 0)
        AS median_revenue_l365d
FROM active
GROUP BY neighborhood
HAVING COUNT(*) >= 50
ORDER BY median_revenue_l365d DESC
LIMIT 10;
-- Result: Malibu earns the most (median $74,688 a year), then Avalon ($66,378),
-- Manhattan Beach ($61,425) and Hollywood Hills West ($59,255). Most of the top 10 are
-- also the most expensive, but Lennox ($35,754), Topanga ($34,902) and West Hollywood
-- ($33,820) make the revenue top 10 without being in the price top 10.


-- Q6: Overpriced or hidden gem?
-- Rank neighborhoods by price and by revenue. gap = revenue rank - price rank.
--   big positive gap: ranks high on price but low on revenue  -> overpriced
--   big negative gap: ranks low on price but high on revenue  -> hidden gem
WITH neighborhood_stats AS (
    SELECT
        neighborhood,
        COUNT(*) AS listings,
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price))::numeric
            AS median_price,
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue_l365d))::numeric
            AS median_revenue_l365d
    FROM active
    GROUP BY neighborhood
    HAVING COUNT(*) >= 50
),
ranked AS (
    SELECT
        neighborhood,
        listings,
        ROUND(median_price, 2) AS median_price,
        ROUND(median_revenue_l365d, 0) AS median_revenue_l365d,
        RANK() OVER (ORDER BY median_price DESC) AS price_rank,
        RANK() OVER (ORDER BY median_revenue_l365d DESC) AS revenue_rank
    FROM neighborhood_stats
)
SELECT *, revenue_rank - price_rank AS gap
FROM ranked
ORDER BY gap DESC            -- overpriced at the top
LIMIT 10;
-- Result: Beverly Hills is the clearest overpriced neighborhood: 14th by nightly
-- price ($313) but 65th by yearly revenue ($19,152), across 375 listings. Marina del
-- Rey is similar (9th by price at $378, 42nd by revenue). Northridge and Altadena have
-- bigger gaps but only about 60 listings each. Hidden gems: see Q6b.


-- Q6b: Hidden gems: neighborhoods that rank much higher on revenue than on price.
-- Same calculation as Q6, sorted the other way.
WITH neighborhood_stats AS (
    SELECT
        neighborhood,
        COUNT(*) AS listings,
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price))::numeric
            AS median_price,
        (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue_l365d))::numeric
            AS median_revenue_l365d
    FROM active
    GROUP BY neighborhood
    HAVING COUNT(*) >= 50
),
ranked AS (
    SELECT
        neighborhood,
        listings,
        ROUND(median_price, 2) AS median_price,
        ROUND(median_revenue_l365d, 0) AS median_revenue_l365d,
        RANK() OVER (ORDER BY median_price DESC) AS price_rank,
        RANK() OVER (ORDER BY median_revenue_l365d DESC) AS revenue_rank
    FROM neighborhood_stats
)
SELECT *, revenue_rank - price_rank AS gap
FROM ranked
ORDER BY gap
LIMIT 10;
-- Result: Norwalk, South San Gabriel, and Winnetka are the leaders in gap. Their price ranks
-- are near the bottom with price_rank 91, 93, and 99 respectively with modest revenues. Silverlake,
-- Hawthorne, and East Los Angeles are also in the top 10 hidden gems with more listings.


-- Q7a: Do Superhosts earn more?
SELECT
    is_superhost,
    COUNT(*) AS listings,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue_l365d))::numeric, 0)
        AS median_revenue_l365d
FROM active
GROUP BY is_superhost;
-- Result: Superhosts earn a median $31,021 a year, 2.3x non-Superhosts ($13,467), and
-- they run 57% of active listings (12,578). This makes sense since Superhost status requires
-- a steady flow of bookings, so busy listings become Superhosts as much as Superhosts
-- become busy.


-- Q7b: Do good reviews earn more, and does Superhost status add to it?
WITH categorized_listings AS (
    SELECT
        CASE
            WHEN rating <= 4.5 THEN '1: up to 4.5'
            WHEN rating <= 4.8 THEN '2: 4.5-4.8'
            ELSE                    '3: over 4.8'
        END AS rating_group,
        CASE WHEN is_superhost THEN 'superhost' ELSE 'not superhost' END
            AS host_type,
        revenue_l365d
    FROM active
    WHERE rating IS NOT NULL
)
SELECT
    rating_group,
    host_type,
    COUNT(*) AS listings,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY revenue_l365d))::numeric, 0)
        AS median_revenue_l365d
FROM categorized_listings
GROUP BY rating_group, host_type
ORDER BY rating_group, host_type;
-- Result: Superhost status matters most for top-rated listings: rated over 4.8,
-- Superhosts earn $33,660 vs $11,899 for non-Superhosts. At 4.5-4.8 the gap is small
-- ($24,618 vs $22,134) and at 4.5 or below both earn about $9,000. Top-rated
-- non-Superhosts earn less than 4.5-4.8 ones, probably because many are newer
-- listings with a few perfect reviews and few bookings so far.


-- Q8: Which amenities go with higher prices?
-- Compared among 2-bedroom listings only, so size doesn't explain the gap.
-- has_pool: own or private pool; shared/community pools don't count.
-- has_free_parking: any single amenity of the form "Free ... parking ...".
WITH flagged AS (
    SELECT
        *,
        (amenities::text ILIKE '%"Pool"%'
         OR amenities::text ILIKE '%"Private pool"%'
         OR amenities::text ILIKE '%"Private outdoor pool%') AS has_pool,
        amenities::text ~* '"Free[^"]*parking[^"]*"' AS has_free_parking
    FROM active
)
SELECT
    has_pool,
    has_free_parking,
    COUNT(*) AS listings,
    ROUND((PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price))::numeric, 2)
        AS median_price
FROM flagged
WHERE bedrooms = 2
GROUP BY has_pool, has_free_parking
ORDER BY has_pool, has_free_parking;
-- Result: Among 2-bedroom listings with free parking, those with a pool charge a median
-- $373 vs $282 without (+32%, 567 vs 3,757 listings). Free parking on its own doesn't
-- raise prices: it's more common in cheaper suburban areas. The no-parking groups
-- are small though (396 and 69 listings).