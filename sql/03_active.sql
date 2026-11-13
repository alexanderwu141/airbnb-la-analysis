-- 03_active.sql : the listings the analysis uses (justification explained in README).
CREATE OR REPLACE VIEW active AS
SELECT *
FROM listings
WHERE price IS NOT NULL
    AND price BETWEEN 20 AND 2000
    AND room_type IN ('Entire home/apt', 'Private room')
    AND number_of_reviews_ltm >= 1;