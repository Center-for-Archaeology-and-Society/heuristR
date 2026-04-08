# Find Heurist Records

Queries records using a raw Heurist query string.

## Usage

``` r
heurist_find_records(session, q, format = "json")
```

## Arguments

- session:

  A `heurist_session`.

- q:

  Heurist query string, such as `"t:10"` or `"sortby:-m"`.

- format:

  Response format. Defaults to `"json"`.

## Value

A parsed Heurist record payload.
