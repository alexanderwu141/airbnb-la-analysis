-- 00_load.sql : copy the raw Inside Airbnb files into PostgreSQL, as text.
-- This one file runs in DuckDB, from the repo folder:
-- duckdb < sql/00_load.sql
-- Everything after this runs in PostgreSQL.
INSTALL postgres;
LOAD postgres;
ATTACH 'dbname=airbnb' AS pg (TYPE postgres);

DROP TABLE IF EXISTS pg.listings_raw;
CREATE TABLE pg.listings_raw AS
SELECT *
FROM read_csv_auto('data/raw/listings.csv.gz',
all_varchar = true,
max_line_size = 10000000);
DROP TABLE IF EXISTS pg.neighbourhoods_raw;
CREATE TABLE pg.neighbourhoods_raw AS
SELECT * 
FROM read_csv_auto('data/raw/neighbourhoods.csv', all_varchar = true);

SELECT COUNT(*) AS listings FROM pg.listings_raw;