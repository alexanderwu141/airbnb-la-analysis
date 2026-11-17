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

## Known issues

- **Everything is text.** Prices look like `"$1,250.00"`, yes/no columns are `t`/`f`, and blanks are empty strings. `sql/02_clean.sql` converts them to real types.
- **Missing prices.** 7,094 listings (16%) have no price, so they're excluded from the analysis.
- **Empty columns.** `host_response_time`, `host_response_rate` and `host_acceptance_rate` are empty for every listing in this snapshot.
- **Estimated revenue.** `estimated_revenue_l365d` and `estimated_occupancy_l365d` are Inside Airbnb's estimates from reviews and prices, not real booking records.
- **Monthly rentals.** Many listings require 30+ nights, especially in the City of Los Angeles (74.8%), probably because of local short-term rental rules.
- **Host listing counts.** `calculated_host_listings_count` counts all of a host's LA listings, including ones my filters later remove.