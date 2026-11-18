# Data

## Source

[Inside Airbnb](https://insideairbnb.com/get-the-data/), Los Angeles, snapshot of September 14, 2026.

## Files

Download these two files from the Los Angeles section and put them in `data/raw/`
(not committed to this repo):

| File | What it is |
| --- | --- |
| `listings.csv.gz` | one row per listing: 43,781 listings, 79 columns |
| `neighbourhoods.csv` | neighborhood names and the area each belongs to |


## What the raw data looks like

Five rows of `listings.csv` (8 of its 79 columns), exactly as loaded: every
value is text. Note the `$` in `price`, `t`/`f` for Superhost, and revenue
of `0` for listings with no estimated bookings.
<br>
```sql
SELECT id,
       neighbourhood_cleansed,
       room_type,
       bedrooms,
       price,
       minimum_nights,
       host_is_superhost,
       estimated_revenue_l365d
FROM listings_raw
LIMIT 5;
```
```
   id   | neighbourhood_cleansed |    room_type    | bedrooms |  price  | minimum_nights | host_is_superhost | estimated_revenue_l365d 
--------+------------------------+-----------------+----------+---------+----------------+-------------------+-------------------------
 287630 | Woodland Hills         | Private room    | 1        | $63.61  | 30             | f                 | 0
 288428 | Van Nuys               | Private room    | 1        | $141.81 | 2              | t                 | 32333
 290761 | Pasadena               | Entire home/apt | 1        | $108.43 | 30             | t                 | 19517
 296379 | Fairfax                | Entire home/apt | 1        | $113.05 | 30             | f                 | 0
 20965  | Hollywood              | Entire home/apt | 1        | $269.00 | 1              | f                 | 17754
(5 rows)
```
<br>

First five rows of `neighbourhoods.csv`:
```sql
SELECT * FROM neighbourhoods_raw LIMIT 5;
```
```
 neighbourhood_group |     neighbourhood      
---------------------+------------------------
 City of Los Angeles | Adams-Normandie
 City of Los Angeles | Arleta
 City of Los Angeles | Arlington Heights
 City of Los Angeles | Atwater Village
 City of Los Angeles | Baldwin Hills/Crenshaw
(5 rows)
```

## Known issues

- **Everything is text.** Prices look like `"$1,250.00"`, yes/no columns are `t`/`f`, and blanks are empty strings. `sql/02_clean.sql` converts them to real types.
- **Missing prices.** 7,094 listings (16%) have no price, so they're excluded from the analysis.
- **Empty columns.** `host_response_time`, `host_response_rate` and `host_acceptance_rate` are empty for every listing in this snapshot.
- **Estimated revenue.** `estimated_revenue_l365d` and `estimated_occupancy_l365d` are Inside Airbnb's estimates from reviews and prices, not real booking records.
- **Monthly rentals.** Many listings require 30+ nights, especially in the City of Los Angeles (74.8%), probably because of local short-term rental rules.
- **Host listing counts.** `calculated_host_listings_count` counts all of a host's LA listings, including ones my filters later remove.

## How the data was prepared

These issues are addressed and cleaned using `02_clean.sql` to transform `listings_raw` into `listings`, a table with important columns renamed and typed.

Afterwards, `03_active.sql` is run to filter for active listings from the `listings` table. Listings like these are filtered out:
1. Price posted is NULL
2. Price outside of range $20 to $2000
3. Room type is not `Entire home/apt` or `Private room`
4. No reviews in the last 12 months

The $20–$2,000 range removes likely data-entry errors and extreme outliers that would distort the medians. Only private rooms, homes, or apartments are used to remove hotels or shared rooms which are inherently different from traditional Airbnb listings. A minimum of one review in the last 12 months is set to ensure that only listings that are actually being booked are included. The resulting `active` view is used in all later analyses.