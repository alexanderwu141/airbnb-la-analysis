-- 02_clean.sql : one clean row per listing, correct types, readable names.
-- CASCADE also drops the 'active' view built on it (03_active.sql rebuilds it).
DROP TABLE IF EXISTS listings CASCADE;
CREATE TABLE listings AS
SELECT
    id::bigint                                      AS listing_id,
    name                                            AS listing_name,
    host_id::bigint                                 AS host_id,
    host_is_superhost = 't'                         AS is_superhost,
    to_num(calculated_host_listings_count)::int     AS host_listings,
    neighbourhood_cleansed                          AS neighborhood,
    neighbourhood_group_cleansed                    AS area,
    to_num(latitude)                                AS latitude,
    to_num(longitude)                               AS longitude,
    room_type,
    to_num(accommodates)::int                       AS accommodates,
    to_num(bedrooms)::int                           AS bedrooms,
    to_num(beds)::int                               AS beds,
    to_num(bathrooms)                               AS bathrooms,
    amenities,
    to_num(REGEXP_REPLACE(price, '[$,]', '', 'g'))  AS price,
    to_num(minimum_nights)::int                     AS minimum_nights,
    to_num(number_of_reviews)::int                  AS number_of_reviews,
    to_num(number_of_reviews_ltm)::int              AS number_of_reviews_ltm,
    to_num(review_scores_rating)                    AS rating,
    to_day(first_review)                            AS first_review,
    to_day(last_review)                             AS last_review,
    to_num(estimated_occupancy_l365d)::int          AS occupancy_nights,
    to_num(estimated_revenue_l365d)                 AS revenue_l365d,
    instant_bookable = 't'                          AS is_instant_bookable
FROM listings_raw;