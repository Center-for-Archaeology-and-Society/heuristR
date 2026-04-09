# Find Heurist Records

Queries records using a raw Heurist query string.

## Usage

``` r
heurist_find_records(session, q, format = "json", as_sf = FALSE, crs = 4326)
```

## Arguments

- session:

  A `heurist_session`.

- q:

  Heurist query string, such as `"t:10"` or `"sortby:-m"`.

- format:

  Response format. Defaults to `"json"`.

- as_sf:

  If `TRUE`, return an `sf` object when possible.

- crs:

  Coordinate reference system to use when `as_sf = TRUE`.

## Value

A parsed Heurist record payload, or an `sf` object if `as_sf = TRUE`.
