-- 01_helpers.sql : safe conversions. Bad or empty text becomes NULL.

-- Text to number: only converts if it looks like 12, -3 or 45.67
CREATE OR REPLACE FUNCTION to_num(t text) RETURNS numeric AS $$
  SELECT CASE WHEN t ~ '^-?[0-9]+(\.[0-9]+)?$' THEN t::numeric END
$$ LANGUAGE sql IMMUTABLE;

-- Text to date: only converts if it looks like 2026-09-14
CREATE OR REPLACE FUNCTION to_day(t text) RETURNS date AS $$
  SELECT CASE WHEN t ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' THEN t::date END
$$ LANGUAGE sql IMMUTABLE;