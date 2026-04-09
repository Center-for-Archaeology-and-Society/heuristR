# Get a Single Heurist Record

Fetches one record by record ID.

## Usage

``` r
heurist_get_record(session, record_id, as_sf = FALSE, crs = 4326)
```

## Arguments

- session:

  A `heurist_session`.

- record_id:

  Numeric or character record ID.

- as_sf:

  If `TRUE`, return an `sf` object when possible.

- crs:

  Coordinate reference system to use when `as_sf = TRUE`.

## Value

A parsed Heurist record payload, or an `sf` object if `as_sf = TRUE`.
